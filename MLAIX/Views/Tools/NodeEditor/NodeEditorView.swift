//
//  NodeEditorView.swift
//  MLAIX
//
//  Visual node-based scripting editor: canvas, nodes, connections, Run → JavaScript.
//

import SwiftUI

private let nodeWidth: CGFloat = 180
private let slotRadius: CGFloat = 6
private let canvasSize: CGFloat = 3000

private struct ConnectionDragState {
    var fromNodeId: UUID
    var fromSlot: String
    var fromPoint: CGPoint
    var currentLocation: CGPoint
}

struct NodeEditorView: View {
    @State private var graph: NodeGraph = NodeEditorView.defaultGraph()
    @State private var output: String = ""
    @State private var consoleOutput: [ConsoleEntry] = []
    @State private var isRunning: Bool = false
    @State private var errorMessage: String?
    @State private var selectedNodeId: UUID?
    @State private var connectionDrag: ConnectionDragState?
    @State private var outputPanelHeight: CGFloat = 180
    @State private var saveTask: Task<Void, Never>?

    var body: some View {
        VSplitView {
            canvasColumn
            outputPanel
                .frame(minHeight: 120, maxHeight: 400)
        }
        .onAppear { loadGraph() }
        .onChange(of: graph) { _, _ in scheduleSave() }
        .onKeyPress(.delete, phases: .down) { _ in
            deleteSelectedNode()
            return .handled
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    graph = NodeEditorView.defaultGraph()
                    selectedNodeId = nil
                    scheduleSave()
                } label: {
                    Label("New", systemImage: "square.and.pencil")
                }
                .help("New graph")
                Menu {
                    ForEach(NodeKind.allCases.filter { $0 != .start }) { kind in
                        Button(kind.title) { addNode(kind: kind) }
                    }
                } label: {
                    Label("Add Node", systemImage: "plus.circle")
                }
                .help("Add a node to the graph")
                Button {
                    runGraph()
                } label: {
                    Label("Run", systemImage: "play.fill")
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(isRunning)
                .help("Run script (⌘↵)")
                if isRunning {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
        }
    }

    private func loadGraph() {
        if let loaded = NodeEditorPersistence.load() {
            graph = loaded
        }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            NodeEditorPersistence.save(graph)
        }
    }

    private func deleteSelectedNode() {
        guard let id = selectedNodeId else { return }
        graph.removeNode(id: id)
        selectedNodeId = nil
    }

    private var canvasColumn: some View {
        ScrollView([.horizontal, .vertical]) {
            ZStack(alignment: .topLeading) {
                // Connection being dragged
                if let drag = connectionDrag {
                    ConnectionPath(
                        from: drag.fromPoint,
                        to: drag.currentLocation
                    )
                }
                // Drawn connections
                ForEach(graph.connections) { conn in
                    if let from = graph.nodes.first(where: { $0.id == conn.fromNodeId }),
                       let to = graph.nodes.first(where: { $0.id == conn.toNodeId }) {
                        ConnectionPath(
                            from: slotPosition(node: from, slot: conn.fromSlot, isOutput: true),
                            to: slotPosition(node: to, slot: conn.toSlot, isOutput: false)
                        )
                    }
                }
                // Nodes
                ForEach(graph.nodes) { node in
                    NodeView(
                        node: node,
                        isSelected: selectedNodeId == node.id,
                        onMove: { delta in moveNode(id: node.id, delta: delta) },
                        onSelect: { selectedNodeId = node.id },
                        onStartConnection: { slot in startConnection(from: node.id, slot: slot) },
                        onEndConnection: { slot in endConnection(to: node.id, slot: slot) },
                        onEndConnectionDrag: { endConnectionDrag() },
                        onUpdateDragLocation: { updateConnectionDragLocation($0) },
                        onUpdateNumber: { graph.updateNumber(id: node.id, value: $0) },
                        onUpdateString: { graph.updateString(id: node.id, value: $0) },
                        onUpdateRunJS: { graph.updateRunJS(id: node.id, value: $0) }
                    )
                    .offset(x: node.position.x, y: node.position.y)
                }
            }
            .frame(width: canvasSize, height: canvasSize)
            .contentShape(Rectangle())
            .onTapGesture { selectedNodeId = nil }
        }
        .focusable()
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var outputPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Output")
                    .font(.headline)
                Spacer()
            }
            if let err = errorMessage {
                Text("Error: \(err)")
                    .foregroundStyle(.red)
                    .font(.system(.body, design: .monospaced))
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    if !output.isEmpty {
                        Text(output)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    }
                    ForEach(Array(consoleOutput.enumerated()), id: \.offset) { _, entry in
                        HStack(alignment: .top, spacing: 6) {
                            Text(entry.level.rawValue)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(levelColor(entry.level))
                                .frame(width: 36, alignment: .leading)
                            Text(entry.message)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    }
                    if output.isEmpty && consoleOutput.isEmpty && errorMessage == nil {
                        Text("Run the graph to see result and console output.")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(nsColor: .textBackgroundColor))
        }
        .padding(12)
    }

    private func levelColor(_ level: ConsoleEntry.Level) -> Color {
        switch level {
        case .log: return .secondary
        case .warn: return .orange
        case .error: return .red
        }
    }

    private func slotPosition(node: ScriptNode, slot: String, isOutput: Bool) -> CGPoint {
        let base = node.position
        switch node.kind {
        case .start:
            return CGPoint(x: base.x + nodeWidth, y: base.y + 30)
        case .number, .string:
            return CGPoint(x: base.x + (isOutput ? nodeWidth : 0), y: base.y + 40)
        case .add:
            if slot == "a" { return CGPoint(x: base.x, y: base.y + 30) }
            if slot == "b" { return CGPoint(x: base.x, y: base.y + 50) }
            return CGPoint(x: base.x + nodeWidth, y: base.y + 40)
        case .log, .output:
            return CGPoint(x: base.x + (isOutput && slot == "out" ? nodeWidth : 0), y: base.y + 40)
        case .runJS:
            return CGPoint(x: base.x + nodeWidth, y: base.y + 50)
        }
    }

    private func addNode(kind: NodeKind) {
        let center = CGPoint(x: canvasSize / 2 - nodeWidth / 2, y: canvasSize / 2 - 40)
        let node = ScriptNode(kind: kind, position: center)
        graph.addNode(node)
    }

    private func moveNode(id: UUID, delta: CGSize) {
        guard let idx = graph.nodes.firstIndex(where: { $0.id == id }) else { return }
        graph.nodes[idx].position.x += delta.width
        graph.nodes[idx].position.y += delta.height
    }

    private func startConnection(from nodeId: UUID, slot: String) {
        guard let node = graph.nodes.first(where: { $0.id == nodeId }) else { return }
        let fromPoint = slotPosition(node: node, slot: slot, isOutput: true)
        connectionDrag = ConnectionDragState(fromNodeId: nodeId, fromSlot: slot, fromPoint: fromPoint, currentLocation: fromPoint)
    }

    private func updateConnectionDragLocation(_ location: CGPoint) {
        guard var drag = connectionDrag else { return }
        drag.currentLocation = location
        connectionDrag = drag
    }

    private func endConnection(to nodeId: UUID, slot: String) {
        guard let drag = connectionDrag else { return }
        if drag.fromNodeId != nodeId {
            graph.addConnection(ScriptConnection(fromNodeId: drag.fromNodeId, fromSlot: drag.fromSlot, toNodeId: nodeId, toSlot: slot))
        }
        connectionDrag = nil
    }

    private func endConnectionDrag() {
        defer { connectionDrag = nil }
        guard let drag = connectionDrag else { return }
        let hitRadius: CGFloat = 20
        for node in graph.nodes {
            for slot in node.kind.inputSlots {
                let pos = slotPosition(node: node, slot: slot, isOutput: false)
                let dx = pos.x - drag.currentLocation.x
                let dy = pos.y - drag.currentLocation.y
                if dx * dx + dy * dy <= hitRadius * hitRadius {
                    endConnection(to: node.id, slot: slot)
                    return
                }
            }
        }
    }

    @MainActor
    private func runGraph() {
        output = ""
        consoleOutput = []
        errorMessage = nil
        isRunning = true
        Task { @MainActor in
            do {
                let code = try NodeGraphCompiler.compile(graph)
                let result = try JavaScriptRunner.executeWithConsoleOutput(code)
                output = result.result
                consoleOutput = result.consoleOutput
            } catch {
                errorMessage = error.localizedDescription
            }
            isRunning = false
        }
    }

    static func defaultGraph() -> NodeGraph {
        var g = NodeGraph()
        let start = ScriptNode(kind: .start, position: CGPoint(x: 80, y: 200))
        let num = ScriptNode(kind: .number, position: CGPoint(x: 320, y: 180), numberValue: 42)
        let out = ScriptNode(kind: .output, position: CGPoint(x: 560, y: 200))
        g.addNode(start)
        g.addNode(num)
        g.addNode(out)
        g.addConnection(ScriptConnection(fromNodeId: start.id, fromSlot: "out", toNodeId: num.id, toSlot: "a"))
        g.addConnection(ScriptConnection(fromNodeId: num.id, fromSlot: "out", toNodeId: out.id, toSlot: "value"))
        return g
    }
}

private struct ConnectionPath: View {
    var from: CGPoint
    var to: CGPoint

    var body: some View {
        Path { p in
            p.move(to: from)
            let mid = CGPoint(x: (from.x + to.x) / 2, y: from.y)
            p.addLine(to: mid)
            p.addLine(to: CGPoint(x: mid.x, y: to.y))
            p.addLine(to: to)
        }
        .stroke(.secondary, lineWidth: 2)
    }
}

/// Sendable wrapper so Binding setters can be passed into SwiftUI without concurrency warnings.
private struct SendableSetter<T>: @unchecked Sendable {
    let set: (T) -> Void
}

private struct NodeView: View {
    @State private var lastDragTranslation: CGSize = .zero
    let node: ScriptNode
    let isSelected: Bool
    let onMove: (CGSize) -> Void
    let onSelect: () -> Void
    let onStartConnection: (String) -> Void
    let onEndConnection: (String) -> Void
    let onEndConnectionDrag: () -> Void
    let onUpdateDragLocation: (CGPoint) -> Void
    let onUpdateNumber: (Double) -> Void
    let onUpdateString: (String) -> Void
    let onUpdateRunJS: (String) -> Void

    var body: some View {
        let numberSetter = SendableSetter(set: onUpdateNumber)
        let stringSetter = SendableSetter(set: onUpdateString)
        let runJSSetter = SendableSetter(set: onUpdateRunJS)
        return HStack(alignment: .top, spacing: 0) {
            // Input slots
            VStack(alignment: .leading, spacing: 8) {
                ForEach(node.kind.inputSlots, id: \.self) { slot in
                    slotCircle(isOutput: false, slot: slot)
                }
            }
            .frame(width: slotRadius * 2)
            // Body
            VStack(alignment: .leading, spacing: 6) {
                Text(node.kind.title)
                    .font(.caption.weight(.semibold))
                switch node.kind {
                case .number:
                    TextField("", value: Binding(get: { node.numberValue }, set: { numberSetter.set($0) }), format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                case .string:
                    TextField("", text: Binding(get: { node.stringValue }, set: { stringSetter.set($0) }))
                        .textFieldStyle(.roundedBorder)
                case .runJS:
                    TextEditor(text: Binding(get: { node.runJSCode }, set: { runJSSetter.set($0) }))
                        .font(.system(.caption, design: .monospaced))
                        .frame(height: 60)
                default:
                    EmptyView()
                }
            }
            .padding(8)
            .frame(width: nodeWidth - slotRadius * 4, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color(nsColor: .controlBackgroundColor)))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(isSelected ? Color.accentColor : Color.secondary.opacity(0.5), lineWidth: isSelected ? 2 : 0.5)
            )
            // Output slot
            if !node.kind.outputSlots.isEmpty {
                OutputSlotView(
                    node: node,
                    onStartConnection: { onStartConnection("out") },
                    onUpdateDragLocation: onUpdateDragLocation,
                    onEndConnectionDrag: onEndConnectionDrag
                )
            }
        }
        .padding(4)
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .gesture(
            DragGesture()
                .onChanged { value in
                    let inc = CGSize(
                        width: value.translation.width - lastDragTranslation.width,
                        height: value.translation.height - lastDragTranslation.height
                    )
                    lastDragTranslation = value.translation
                    onMove(inc)
                }
                .onEnded { _ in
                    lastDragTranslation = .zero
                }
        )
    }

    private func slotCircle(isOutput: Bool, slot: String) -> some View {
        Circle()
            .fill(isOutput ? Color.blue : Color.orange)
            .frame(width: slotRadius * 2, height: slotRadius * 2)
    }
}

private struct OutputSlotView: View {
    let node: ScriptNode
    let onStartConnection: () -> Void
    let onUpdateDragLocation: (CGPoint) -> Void
    let onEndConnectionDrag: () -> Void

    @State private var dragStarted = false

    var body: some View {
        Circle()
            .fill(Color.blue)
            .frame(width: slotRadius * 2, height: slotRadius * 2)
            .gesture(
                DragGesture(minimumDistance: 4)
                    .onChanged { value in
                        if !dragStarted {
                            dragStarted = true
                            onStartConnection()
                        }
                        let canvasPoint = CGPoint(
                            x: node.position.x + value.location.x,
                            y: node.position.y + value.location.y
                        )
                        onUpdateDragLocation(canvasPoint)
                    }
                    .onEnded { _ in
                        dragStarted = false
                        onEndConnectionDrag()
                    }
            )
    }
}

// MARK: - NodeGraph helpers for binding updates
private extension NodeGraph {
    mutating func updateNumber(id: UUID, value: Double) {
        guard let idx = nodes.firstIndex(where: { $0.id == id }) else { return }
        nodes[idx].numberValue = value
    }
    mutating func updateString(id: UUID, value: String) {
        guard let idx = nodes.firstIndex(where: { $0.id == id }) else { return }
        nodes[idx].stringValue = value
    }
    mutating func updateRunJS(id: UUID, value: String) {
        guard let idx = nodes.firstIndex(where: { $0.id == id }) else { return }
        nodes[idx].runJSCode = value
    }
}

#Preview {
    NodeEditorView()
        .frame(width: 800, height: 500)
}
