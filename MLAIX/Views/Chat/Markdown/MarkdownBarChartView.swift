//
//  MarkdownBarChartView.swift
//  MLAI
//
//  Created by Bean John on 11/6/24.
//

import Charts
import SwiftUI

struct MarkdownBarChartView: View {
	
	@EnvironmentObject private var controller: MarkdownDataViewController
	
	private var bars: [Bar] {
		return controller.rows.enumerated().compactMap { index, row -> Bar? in
			guard let label = row.first, let lastCell = row.last else { return nil }
			let value = lastCell.parseChartNumericValue() ?? 0
			return Bar(index: index, value: value, label: label)
		}
	}
	
    var body: some View {
		let xHeader = controller.headers.first ?? ""
		let yHeader = controller.headers.last ?? ""
		Chart(bars) { bar in
			BarMark(
				x: .value(xHeader, bar.label),
				y: .value(yHeader, bar.value)
			)
			.foregroundStyle(
				by: .value(bar.label, bar.label)
			)
			.annotation(
				position: .top,
				alignment: .center
			) {
				Text(bar.valueDescription)
					.foregroundStyle(.secondary)
			}
		}
		.aspectRatio(1.0, contentMode: .fit)
		.chartLegend(.hidden)
		.chartYAxis {
			AxisMarks(position: .leading)
		}
		.chartXAxisLabel(
			xHeader,
			position: .bottom,
			alignment: .center
		)
		.chartYAxisLabel(
			yHeader,
			position: .leading,
			alignment: .center
		)
		.frame(maxWidth: 350)
		.padding(.bottom, 5)
    }
	
	private struct Bar: Identifiable {
		
		let id: UUID = UUID()
		
		let index: Int
		let value: Double
		var valueDescription: String {
			if value.rounded() == value {
				return String(Int(value))
			}
			return String(format: "%.2f", value)
		}
		
		let label: String
	}
	
}
