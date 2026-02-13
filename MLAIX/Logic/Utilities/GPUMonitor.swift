//
//  GPUMonitor.swift
//  MLAI
//
//  Created for MLAIX GPU performance monitoring.
//

import Foundation
import Metal
import IOKit

@MainActor
@Observable
final class GPUMonitor {

    static let shared = GPUMonitor()

    var currentUtilization: Double = 0.0  // 0-100%
    var currentMemoryUsed: UInt64 = 0
    var totalMemory: UInt64 = 0
    var memoryPressure: MemoryPressure = .nominal
    var gpuName: String = "Unknown"
    var isMonitoring: Bool = false

    enum MemoryPressure: String, Sendable {
        case nominal, warning, critical
    }

    private var monitoringTask: Task<Void, Never>?
    private let device: MTLDevice?

    private init() {
        self.device = MTLCreateSystemDefaultDevice()
        if let device = self.device {
            self.gpuName = device.name
            self.totalMemory = UInt64(device.recommendedMaxWorkingSetSize)
        }
    }

    // MARK: - Monitoring

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        monitoringTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                self.sampleGPU()
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }

    func stopMonitoring() {
        isMonitoring = false
        monitoringTask?.cancel()
        monitoringTask = nil
    }

    // MARK: - GPU Sampling

    private func sampleGPU() {
        guard let device else { return }

        // Memory tracking via Metal device
        let allocatedSize = UInt64(device.currentAllocatedSize)
        self.currentMemoryUsed = allocatedSize

        // Update memory pressure based on usage ratio
        let usageRatio = totalMemory > 0 ? Double(allocatedSize) / Double(totalMemory) : 0
        if usageRatio > 0.9 {
            self.memoryPressure = .critical
        } else if usageRatio > 0.7 {
            self.memoryPressure = .warning
        } else {
            self.memoryPressure = .nominal
        }

        // Sample GPU utilization via IOKit IOAccelerator
        self.currentUtilization = sampleGPUUtilization()
    }

    private nonisolated func sampleGPUUtilization() -> Double {
        var iterator: io_iterator_t = 0
        let matchDict = IOServiceMatching("IOAccelerator")
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, matchDict, &iterator)
        guard result == KERN_SUCCESS else { return 0.0 }
        defer { IOObjectRelease(iterator) }

        var service = IOIteratorNext(iterator)
        while service != 0 {
            defer {
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }

            var properties: Unmanaged<CFMutableDictionary>?
            let kr = IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0)
            guard kr == KERN_SUCCESS, let props = properties?.takeRetainedValue() as? [String: Any] else {
                continue
            }

            // Look for performance statistics dictionary
            if let perfStats = props["PerformanceStatistics"] as? [String: Any] {
                // Try common keys for GPU utilization
                if let utilization = perfStats["Device Utilization %"] as? NSNumber {
                    return utilization.doubleValue
                }
                if let utilization = perfStats["GPU Activity(%)"] as? NSNumber {
                    return utilization.doubleValue
                }
                // Fallback: try reading in-use system memory as a proxy
                if let inUse = perfStats["In use system memory"] as? NSNumber,
                   let alloc = perfStats["Allocated system memory"] as? NSNumber,
                   alloc.uint64Value > 0 {
                    return min(100.0, Double(inUse.uint64Value) / Double(alloc.uint64Value) * 100.0)
                }
            }
        }

        return 0.0
    }

    // MARK: - Recommendations

    /// Recommend optimal GPU layers based on model size and available VRAM.
    /// If the model fits in ~75% of available memory, offload all layers (99).
    /// Otherwise, calculate proportionally.
    func recommendGPULayers(modelSizeBytes: UInt64) -> Int {
        guard totalMemory > 0, modelSizeBytes > 0 else { return 99 }

        let availableMemory = totalMemory - currentMemoryUsed
        let threshold = Double(availableMemory) * 0.75

        if Double(modelSizeBytes) <= threshold {
            // Model fits comfortably — offload everything
            return 99
        } else {
            // Calculate proportional layer count
            let ratio = threshold / Double(modelSizeBytes)
            let layers = Int(ratio * 99.0)
            return max(1, min(99, layers))
        }
    }

    /// Recommend whether flash attention should be enabled based on context
    /// length and GPU memory capacity.
    func shouldEnableFlashAttention(contextLength: Int) -> Bool {
        let hasEnoughMemory = totalMemory > 8 * 1024 * 1024 * 1024  // > 8 GB
        let hasLargeContext = contextLength > 4096
        return hasEnoughMemory && hasLargeContext
    }

    // MARK: - Formatted Helpers

    /// Formatted string for memory usage (e.g. "4.2 / 16.0 GB")
    var formattedMemoryUsage: String {
        let usedGB = Double(currentMemoryUsed) / pow(2.0, 30.0)
        let totalGB = Double(totalMemory) / pow(2.0, 30.0)
        return String(format: "%.1f / %.1f GB", usedGB, totalGB)
    }
}
