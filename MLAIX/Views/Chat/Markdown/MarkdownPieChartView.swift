//
//  MarkdownPieChartView.swift
//  MLAI
//
//  Created by Bean John on 11/6/24.
//

import Charts
import SwiftUI

struct MarkdownPieChartView: View {
	
	@EnvironmentObject private var controller: MarkdownDataViewController
	
	private var sectors: [Sector] {
		let validRows = controller.rows.compactMap { row -> (label: String, value: Double)? in
			guard let label = row.first, let lastCell = row.last,
			      let value = lastCell.parseChartNumericValue() else { return nil }
			return (label: label, value: value)
		}
		let total = validRows.map(\.value).reduce(0, +)
		guard total > 0 else { return [] }
		return validRows.map { Sector(value: $0.value, total: total, label: $0.label) }
	}
	
    var body: some View {
		Chart(sectors) { sector in
			SectorMark(
				angle: .value(
					sector.text,
					sector.value
				),
				angularInset: 1.5
			)
			.cornerRadius(3)
			.annotation(position: .overlay) {
				Text(sector.percentage)
					.foregroundStyle(.white)
			}
			.foregroundStyle(
				by: .value(
					sector.text,
					sector.label
				)
			)
		}
		.frame(idealWidth: 300, idealHeight: 300)
		.fixedSize(horizontal: true, vertical: false)
		.padding(.bottom, 5)
    }
	
	private struct Sector: Identifiable {
		let id: UUID = UUID()
		let value: Double
		let total: Double
		var percentage: String {
			return String(format: "%.1f", (value / total) * 100) + "%"
		}
		let label: String
		var text: Text {
			Text(label)
		}
	}
	
}
