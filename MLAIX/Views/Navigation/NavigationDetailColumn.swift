//
//  NavigationDetailColumn.swift
//  MLAIX
//
//  Third column: detail (conversation chat + canvas, or tool/section detail).
//

import SwiftUI

struct NavigationDetailColumn: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(ConversationState.self) private var conversationState
    @Environment(ConversationManager.self) private var conversationManager

    var section: PrimarySection?
    var selectedToolId: String?
    var conversationView: () -> AnyView
    var noConversationView: () -> AnyView

    var body: some View {
        Group {
            switch section {
            case .conversations:
                conversationDetail
            case .tools:
                toolDetail
            case .models, .memory, .settings, .none:
                sectionPlaceholder
            }
        }
        .frame(minWidth: 400)
    }

    private var conversationDetail: some View {
        Group {
            if conversationState.selectedConversationId == nil || conversationManager.getConversation(id: conversationState.selectedConversationId!) == nil {
                noConversationView()
            } else {
                conversationView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var toolDetail: some View {
        Group {
            if let id = selectedToolId, let tool = toolItem(id: id) {
                toolDetailCard(tool: tool)
            } else {
                ContentUnavailableView(
                    "Select a tool",
                    systemImage: "wrench.and.screwdriver",
                    description: Text("Choose a tool from the list to open it.")
                )
                .symbolVariant(.fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func toolItem(id: String) -> (name: String, description: String, systemImage: String)? {
        switch id {
        case "dashboard": return (String(localized: "Dashboard"), String(localized: "View usage statistics and trends"), "chart.line.uptrend.xyaxis")
        case "detector": return (String(localized: "Detector"), String(localized: "Stay one step ahead of Turnitin"), "checkmark.seal.text.page")
        case "diagrammer": return (String(localized: "Diagrammer"), String(localized: "Generate diagrams with AI"), "square.on.square")
        case "slideStudio": return (String(localized: "Slide Studio"), String(localized: "Create 10 minute presentations in 5 minutes"), "rectangle.on.rectangle.angled")
        case "inlineAssistant": return (String(localized: "Inline Writing Assistant"), String(localized: "Edit text with AI without leaving your editor. Use the Toolbox (⌘T) to configure."), "pencil.and.list.clipboard")
        case "nodeEditor": return (String(localized: "Node Editor"), String(localized: "Visual node-based scripting with JavaScript"), "point.3.connected.trianglepath.dotted")
        default: return nil
        }
    }

    private func toolDetailCard(tool: (name: String, description: String, systemImage: String)) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: tool.systemImage)
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
                    .frame(width: 52, height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.quaternary.opacity(0.8))
                    )
                VStack(alignment: .leading, spacing: 4) {
                    Text(tool.name)
                        .font(.title2.weight(.semibold))
                    Text(tool.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            if let id = selectedToolId, id != "inlineAssistant" {
                Button {
                    openWindow(id: id)
                } label: {
                    Label("Open in New Window", systemImage: "arrow.up.forward.square")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else if selectedToolId == "inlineAssistant" {
                Text("Use the Toolbox (⌘T) from the conversation view to configure and use the Inline Writing Assistant.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 0.5)
        )
    }

    private var sectionPlaceholder: some View {
        VStack(alignment: .leading, spacing: 24) {
            ContentUnavailableView(
                "Detail",
                systemImage: "sidebar.right",
                description: Text("Use the middle column to open Models, Memory, or Settings.")
            )
            .symbolVariant(.fill)
            if section == .models {
                quickLinkButton(icon: "cpu", title: "Open Models", action: { openWindow(id: "models") })
            } else if section == .memory {
                quickLinkButton(icon: "brain", title: "Open Memory", action: { openWindow(id: "memory") })
            } else if section == .settings {
                quickLinkButton(icon: "gearshape", title: "Open Settings", action: { NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil) })
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.quaternary.opacity(0.5), lineWidth: 0.5)
        )
    }

    private func quickLinkButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, alignment: .center)
                Text(title)
                    .font(.subheadline.weight(.medium))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(.quaternary.opacity(0.5)))
        }
        .buttonStyle(.plain)
    }
}
