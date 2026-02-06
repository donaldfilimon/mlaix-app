//
//  MLAIXWidget.swift
//  MLAIX Widget Extension
//
//  Add this file to an Xcode Widget Extension target. SwiftPM does not support
//  app extensions; create an Xcode project and add a Widget Extension to use.
//

import SwiftUI
import WidgetKit

// MARK: - Widget

struct MLAIXWidget: Widget {
    let kind: String = "MLAIXWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MLAIXWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("MLAIX")
        .description("Quick access to open MLAIX and start a new chat.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> MLAIXEntry {
        MLAIXEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (MLAIXEntry) -> Void) {
        completion(MLAIXEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MLAIXEntry>) -> Void) {
        let entry = MLAIXEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

// MARK: - Entry

struct MLAIXEntry: TimelineEntry {
    let date: Date
}

// MARK: - Entry View

struct MLAIXWidgetEntryView: View {
    var entry: MLAIXEntry
    @Environment(\.widgetFamily) var family

    private var iconSize: CGFloat {
        switch family {
        case .systemSmall: return 32
        case .systemMedium: return 40
        case .systemLarge: return 48
        default: return 40
        }
    }

    var body: some View {
        if let url = URL(string: "mlaix://new-chat") {
            Link(destination: url) {
                widgetContent
            }
        } else {
            widgetContent
        }
    }

    private var widgetContent: some View {
        VStack(spacing: family == .systemLarge ? 12 : 8) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: iconSize))
                .foregroundStyle(.tint)
            Text("MLAIX")
                .font(.headline)
            Text("New Chat")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("MLAIX. Tap to open and start a new chat.")
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    MLAIXWidget()
} timeline: {
    MLAIXEntry(date: Date())
}
