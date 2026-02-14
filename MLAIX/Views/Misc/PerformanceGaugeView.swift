//
//  PerformanceGaugeView.swift
//  MLAI
//
//  Created by Bean John on 11/9/24.
//

import SwiftUI
import DefaultModels

struct PerformanceGaugeView: View {
	
	let gpu: GPUInfoDevice? = try? .init()
	@State private var gpuMonitor = GPUMonitor.shared
	
	var name: String {
		return self.gpu?.name ?? "Unknown GPU"
	}
	
	var performance: CGFloat {
		return (self.gpu?.flops ?? 0) / pow(10, 12)
	}
	
	var minTflops: CGFloat {
		let historicalMin: CGFloat = GPU.all.map(\.tflops).sorted().first ?? 0
		return min(historicalMin, performance)
	}
	
	var maxTflops: CGFloat {
		let historicalMax: CGFloat = GPU.all.map(\.tflops).sorted().last ?? 0
		return max(historicalMax, performance)
	}
	
	let colors: [Color] = [.red, .yellow, .green]
	
	var body: some View {
		VStack {
			HStack {
				Text("GPU poor")
				Spacer()
				Text("GPU rich")
			}
			guage
			gpuUtilizationSection
		}
		.onAppear {
			gpuMonitor.startMonitoring()
		}
		.onDisappear {
			gpuMonitor.stopMonitoring()
		}
	}
	
	// MARK: - GPU Utilization Indicator
	
	private var gpuUtilizationSection: some View {
		HStack(spacing: 12) {
			// Circular utilization indicator
			ZStack {
				Circle()
					.stroke(Color.secondary.opacity(0.3), lineWidth: 3)
				Circle()
					.trim(from: 0, to: gpuMonitor.currentUtilization / 100.0)
					.stroke(
						utilizationColor,
						style: StrokeStyle(lineWidth: 3, lineCap: .round)
					)
					.rotationEffect(.degrees(-90))
				Text("\(Int(gpuMonitor.currentUtilization))%")
					.font(.system(size: 8, weight: .medium, design: .monospaced))
			}
			.frame(width: 32, height: 32)
			
			VStack(alignment: .leading, spacing: 2) {
				Text(gpuMonitor.gpuName)
					.font(.caption)
					.foregroundStyle(.secondary)
				Text(gpuMonitor.formattedMemoryUsage)
					.font(.caption2)
					.foregroundStyle(.tertiary)
			}
			
			Spacer()
			
			// Memory pressure badge
			if gpuMonitor.memoryPressure != .nominal {
				Text(gpuMonitor.memoryPressure.rawValue.uppercased())
					.font(.system(size: 9, weight: .semibold, design: .monospaced))
					.padding(.horizontal, 6)
					.padding(.vertical, 2)
					.background(
						gpuMonitor.memoryPressure == .critical ? Color.red.opacity(0.2) : Color.yellow.opacity(0.2)
					)
					.clipShape(Capsule())
			}
		}
		.padding(.top, 4)
	}
	
	private var utilizationColor: Color {
		switch gpuMonitor.currentUtilization {
		case 0..<50: return .green
		case 50..<80: return .yellow
		default: return .red
		}
	}
	
	var guage: some View {
		GeometryReader { proxy in
			scaleLine
				.frame(maxHeight: .infinity, alignment: .center)
				.clipShape(
					Capsule()
				)
				.overlay(alignment: .leading) {
					Group {
						ForEach(GPU.all) { gpu in
							PerformancePointView(
								name: gpu.name,
								width: proxy.size.width,
								min: minTflops,
								max: maxTflops,
								value: gpu.tflops
							)
						}
						PerformancePointView(
							name: String(localized: "Your ") + self.name,
							isCurrentDevice: true,
							width: proxy.size.width,
							min: minTflops,
							max: maxTflops,
							value: self.performance
						)
						.shadow(radius: 10)
					}
				}
		}
		.frame(maxHeight: 15)
	}
	
	var scaleLine: some View {
		LinearGradient(
			gradient: Gradient(
				colors: self.colors
			),
			startPoint: .leading,
			endPoint: .trailing
		)
		.frame(maxHeight: 10)
	}
	
	private struct PerformancePointView: View {
		
		var name: String
		var isCurrentDevice: Bool = false
		var width: CGFloat
		
		var pointScale: CGFloat {
			return isCurrentDevice ? 1.5 : 1.00
		}
		
		var min: CGFloat
		var max: CGFloat
		var value: CGFloat
		
		var valueDescription: String {
			let num: CGFloat = round(self.value * 100) / 100
			return "\(name): \(num) TFLOPS"
		}
		
		var percent: CGFloat {
			return (self.value - self.min) / (self.max - self.min)
		}
		
		var fillColor: Color {
			return .white
		}
		
		let diameter: CGFloat = 10
		
		var xOffset: CGFloat {
			return ((width - diameter) * percent) / pointScale
		}
		
		@State private var isHovering: Bool = false
		
		var body: some View {
			circle
				.popover(isPresented: $isHovering) {
					Text(valueDescription)
						.padding(7)
				}
				.onHover { hovering in
					withAnimation(.linear) {
						self.isHovering = hovering
					}
				}
				.offset(
					x: xOffset
				)
				.scaleEffect(pointScale)
		}
		
		var circle: some View {
			Circle()
				.fill(
					isCurrentDevice ? fillColor : .secondary.opacity(0.6)
				)
				.frame(width: diameter)
		}
		
	}
	
}

#Preview {
	PerformanceGaugeView()
}
