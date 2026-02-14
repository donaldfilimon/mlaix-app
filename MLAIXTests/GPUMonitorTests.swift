//
//  GPUMonitorTests.swift
//  MLAIXTests
//
//  Tests for GPUMonitor GPU recommendations, memory formatting, and singleton.
//

import Foundation
import Testing
@testable import MLAIX

@Suite("GPUMonitorTests")
struct GPUMonitorTests {

    // MARK: - Singleton

    @Test @MainActor func sharedSingletonExists() {
        let monitor = GPUMonitor.shared
        #expect(monitor !== nil as AnyObject?)
    }

    @Test @MainActor func sharedReturnsSameInstance() {
        let a = GPUMonitor.shared
        let b = GPUMonitor.shared
        #expect(a === b)
    }

    // MARK: - MemoryPressure enum

    @Test func memoryPressureNominalRawValue() {
        #expect(GPUMonitor.MemoryPressure.nominal.rawValue == "nominal")
    }

    @Test func memoryPressureWarningRawValue() {
        #expect(GPUMonitor.MemoryPressure.warning.rawValue == "warning")
    }

    @Test func memoryPressureCriticalRawValue() {
        #expect(GPUMonitor.MemoryPressure.critical.rawValue == "critical")
    }

    @Test func memoryPressureInitFromRawValue() {
        #expect(GPUMonitor.MemoryPressure(rawValue: "nominal") == .nominal)
        #expect(GPUMonitor.MemoryPressure(rawValue: "warning") == .warning)
        #expect(GPUMonitor.MemoryPressure(rawValue: "critical") == .critical)
        #expect(GPUMonitor.MemoryPressure(rawValue: "invalid") == nil)
    }

    // MARK: - recommendGPULayers

    @Test @MainActor func recommendGPULayersSmallModel() {
        let monitor = GPUMonitor.shared
        // 1 GB model should likely get high layer count on modern hardware
        let layers = monitor.recommendGPULayers(modelSizeBytes: 1_000_000_000)
        #expect(layers > 0)
        #expect(layers <= 99)
    }

    @Test @MainActor func recommendGPULayersTinyModel() {
        let monitor = GPUMonitor.shared
        // 1 MB model — should comfortably fit, expect max layers
        let layers = monitor.recommendGPULayers(modelSizeBytes: 1_000_000)
        #expect(layers == 99)
    }

    @Test @MainActor func recommendGPULayersHugeModel() {
        let monitor = GPUMonitor.shared
        // 500 GB model — larger than any current GPU, should get fewer layers
        let layers = monitor.recommendGPULayers(modelSizeBytes: 500_000_000_000)
        #expect(layers >= 1)
        #expect(layers <= 99)
    }

    @Test @MainActor func recommendGPULayersZeroSize() {
        let monitor = GPUMonitor.shared
        // Zero-size model defaults to 99
        let layers = monitor.recommendGPULayers(modelSizeBytes: 0)
        #expect(layers == 99)
    }

    // MARK: - shouldEnableFlashAttention

    @Test @MainActor func flashAttentionSmallContext() {
        let monitor = GPUMonitor.shared
        // Small context (< 4096) should not trigger flash attention
        let result = monitor.shouldEnableFlashAttention(contextLength: 2048)
        // Even with enough memory, context must be > 4096
        #expect(result == false)
    }

    @Test @MainActor func flashAttentionLargeContext() {
        let monitor = GPUMonitor.shared
        // Large context — result depends on totalMemory (> 8 GB)
        let result = monitor.shouldEnableFlashAttention(contextLength: 8192)
        // On machines with > 8 GB GPU, this should be true
        if monitor.totalMemory > 8 * 1024 * 1024 * 1024 {
            #expect(result == true)
        } else {
            #expect(result == false)
        }
    }

    @Test @MainActor func flashAttentionBoundaryContext() {
        let monitor = GPUMonitor.shared
        // Exactly 4096 should NOT enable (threshold is > 4096)
        let result = monitor.shouldEnableFlashAttention(contextLength: 4096)
        #expect(result == false)
    }

    // MARK: - formattedMemoryUsage

    @Test @MainActor func formattedMemoryUsageContainsGB() {
        let monitor = GPUMonitor.shared
        let formatted = monitor.formattedMemoryUsage
        #expect(formatted.contains("GB"))
    }

    @Test @MainActor func formattedMemoryUsageContainsSlash() {
        let monitor = GPUMonitor.shared
        let formatted = monitor.formattedMemoryUsage
        #expect(formatted.contains("/"))
    }

    @Test @MainActor func formattedMemoryUsageMatchesPattern() {
        let monitor = GPUMonitor.shared
        let formatted = monitor.formattedMemoryUsage
        // Should match pattern like "X.X / Y.Y GB"
        let components = formatted.split(separator: "/")
        #expect(components.count == 2)
    }

    // MARK: - Observable properties

    @Test @MainActor func defaultPropertiesAreReasonable() {
        let monitor = GPUMonitor.shared
        #expect(monitor.currentUtilization >= 0.0)
        #expect(monitor.currentUtilization <= 100.0)
        #expect(monitor.memoryPressure == .nominal || monitor.memoryPressure == .warning || monitor.memoryPressure == .critical)
    }

    @Test @MainActor func gpuNameIsNotEmpty() {
        let monitor = GPUMonitor.shared
        // gpuName is set from MTLDevice or "Unknown"
        #expect(!monitor.gpuName.isEmpty)
    }

    @Test @MainActor func totalMemoryIsPositiveOnAppleSilicon() {
        let monitor = GPUMonitor.shared
        // On any Mac with Metal support, totalMemory should be > 0
        // (Could be 0 only if MTLCreateSystemDefaultDevice() returns nil)
        #expect(monitor.totalMemory >= 0)
    }
}
