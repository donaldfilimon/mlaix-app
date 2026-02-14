//
//  NavigationContentColumn.swift
//  MLAIX
//
//  Second column: section-specific list (conversations, tools, etc.).
//

import SwiftUI

struct NavigationContentColumn: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(LengthyTasksController.self) private var lengthyTasksController
    @Environment(ConversationManager.self) private var conversationManager
    @Environment(ConversationState.self) private var conversationState
    @Environment(ExpertManager.self) private var expertManager

    var section: PrimarySection?
    @Binding var selectedToolId: String?

    var body: some View {
        Group {
            switch section {
            case .conversations:
                conversationsContent
            case .tools:
                toolsContent
            case .models:
                modelsContent
            case .memory:
                memoryContent
            case .settings:
                settingsContent
            case .none:
                emptyContent
            }
        }
        .accessibilityIdentifier("contentColumn")
        .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 320)
    }

    private var conversationsContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(title: String(localized: "Conversations"), icon: "bubble.left.and.text.bubble.right")
            ConversationNavigationListView()
            Spacer(minLength: 0)
            ConversationSidebarButtons()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(.regularMaterial.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 0.5)
        )
        .padding(10)
    }

    private struct ToolItem: Identifiable {
        let id: String
        let name: String
        let description: String
        let systemImage: String
    }

    private static let toolsList: [ToolItem] = [
        ToolItem(id: "dashboard", name: String(localized: "Dashboard"), description: String(localized: "View usage statistics and trends"), systemImage: "chart.line.uptrend.xyaxis"),
        ToolItem(id: "detector", name: String(localized: "Detector"), description: String(localized: "Stay one step ahead of Turnitin"), systemImage: "checkmark.seal.text.page"),
        ToolItem(id: "diagrammer", name: String(localized: "Diagrammer"), description: String(localized: "Generate diagrams with AI"), systemImage: "square.on.square"),
        ToolItem(id: "slideStudio", name: String(localized: "Slide Studio"), description: String(localized: "Create 10 minute presentations in 5 minutes"), systemImage: "rectangle.on.rectangle.angled"),
        ToolItem(id: "inlineAssistant", name: String(localized: "Inline Writing Assistant"), description: String(localized: "Edit text with AI without leaving your editor"), systemImage: "pencil.and.list.clipboard"),
        ToolItem(id: "nodeEditor", name: String(localized: "Node Editor"), description: String(localized: "Visual node-based scripting with JavaScript"), systemImage: "point.3.connected.trianglepath.dotted")
    ]

    private var toolsContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(title: String(localized: "Tools"), icon: "wrench.and.screwdriver")
            List(selection: $selectedToolId) {
                ForEach(Self.toolsList) { tool in
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: tool.systemImage)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 28, height: 28)
                            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(.quaternary.opacity(0.8)))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tool.name)
                                .font(.subheadline.weight(.medium))
                            Text(tool.description)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .lineLimit(2)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 8)
                    .listRowInsets(EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10))
                    .tag(tool.id)
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
        }
        .padding(12)
        .background(.regularMaterial.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(10)
    }

    private var modelsContent: some View {
        sectionCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Browse and download GGUF/MLX models, configure server and local inference, and switch between model families.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    openWindow(id: "models")
                } label: {
                    Label("Open Models", systemImage: "arrow.up.forward.square")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        section: { sectionHeader(title: String(localized: "Models"), icon: "cpu") }
    }

    private var memoryContent: some View {
        sectionCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Inspect, edit, and export memories that the assistant uses for context across conversations.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    openWindow(id: "memory")
                } label: {
                    Label("Open Memory", systemImage: "arrow.up.forward.square")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        section: { sectionHeader(title: String(localized: "Memory"), icon: "brain") }
    }

    private var settingsContent: some View {
        sectionCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("General, Apple Intelligence, Retrieval, Inference, Appearance, and Deep Research preferences.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Use **Settings…** from the app menu (⌘,) to open preferences.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        section: { sectionHeader(title: String(localized: "Settings"), icon: "gearshape") }
    }

    private var emptyContent: some View {
        VStack(spacing: 20) {
            ContentUnavailableView(
                "Select a section",
                systemImage: "sidebar.left",
                description: Text("Choose Conversations, Tools, or another section from the sidebar.")
            )
            .symbolVariant(.fill)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func sectionCard<Content: View, Section: View>(@ViewBuilder content: () -> Content, @ViewBuilder section: () -> Section) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            section()
            content()
                .padding(.horizontal, 4)
                .padding(.top, 10)
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 0.5)
        )
        .padding(10)
    }

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: 20, alignment: .center)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 10)
    }
}

