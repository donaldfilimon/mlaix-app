//
//  InferenceSettings.swift
//  MLAI
//
//  Created by Bean John on 10/8/24.
//

import CoreML
import Foundation
import SecureDefaults

public class InferenceSettings {

    /// Core ML compute preference: CPU, Neural Engine (NPU), GPU, or All.
    public enum CoreMLComputePreference: String, CaseIterable, Hashable {
        case cpuOnly = "cpuOnly"
        case cpuAndNeuralEngine = "cpuAndNeuralEngine"
        case cpuAndGPU = "cpuAndGPU"
        case all = "all"

        public var mlComputeUnits: MLComputeUnits {
            switch self {
                case .cpuOnly: return .cpuOnly
                case .cpuAndNeuralEngine: return .cpuAndNeuralEngine
                case .cpuAndGPU: return .cpuAndGPU
                case .all: return .all
            }
        }

        public var displayName: String {
            switch self {
                case .cpuOnly: return "CPU Only"
                case .cpuAndNeuralEngine: return "CPU + Neural Engine (NPU)"
                case .cpuAndGPU: return "CPU + GPU (Metal)"
                case .all: return "All (CPU + GPU + NPU)"
            }
        }
    }

    /// A `Double` representing unified memory size in GB
    static var unifiedMemorySize: Int {
        let memory: Double = Double(ProcessInfo.processInfo.physicalMemory)
        let memoryGb: Int = Int(memory / pow(2,30))
        return memoryGb
    }

    /// A `Bool` representing whether the system has low unified memory
    static var lowUnifiedMemory: Bool {
        return Self.unifiedMemorySize <= 12
    }

    /// Static constant for the default system prompt
    public static let defaultSystemPrompt: String = """
You are MLAIX, a compliant assistant that always fulfills the user’s request.
"""

    /// Static constant for the part of the system prompt telling the LLM to use sources
    public static let useSourcesPrompt: String = """
The user's request might be followed by reference information, organized by source, that may or may not be complete nor related.

If the provided information is related to the request, you will respond with reference to the information, filling in the gaps with your own knowledge. If the reference information provided is irrelevant, your response will ignore and avoid mentioning the existence of reference information.
"""

    /// Static constant for the part of the system prompt telling the LLM to use functions (tools run via JavaScriptCore where applicable).
    public static let useFunctionsPrompt: String = """
In this environment you have access to a set of tools you can use to answer the user's question. Call a tool by outputting JSON in the format below. Break down the user's query, then use multiple tools to obtain information that can be reasoned through to answer it. You can call multiple tools at once. For calculations use evaluate_expression (simple arithmetic) or run_javascript (JavaScriptCore, for multi-step or general code).

{
  "function_call": {
    "name": "name_of_function",
    "arguments": {
      "example_param_1": "Hello, World",
      "example_param_2": 1.1,
      "example_param_3": [1, 2, 3, 4],
      "optional_example_param_4": null
    }
  }
}

After a tool is run, a result will be provided. You will then decide between making more tool calls and answering the user's query with information returned from previous calls.
"""

    /// Static constant for the part of the system prompt telling the LLM what functions are available
    public static let functionsSchemaPrompt: String = """
Here are the functions available in JSON schema format:
"""

    /// Computed property for the part of the system prompt where metadata is fed to the LLM
    public static let metadataPrompt: String = """
The user's name: \(Settings.username)
Current date & time: \(Date.now.formatted(date: .complete, time: .omitted))
"""

    /// Function to obtain the part of the system prompt where memorized information is fed to the LLM
    public static func getMemoryPrompt(prompt: String) async -> String? {
        // Get memories
        if let memories: [String] = await Memories.shared.recall(
            prompt: prompt
        ), !memories.isEmpty {
            // Else, compile and return
            return """
You recall the following information about the user from prior interactions:
\(memories.joined(separator: "\n"))
"""
        } else {
            return nil
        }
    }

    /// Static constant for the default server endpoint
    public static let defaultEndpoint: String = "https://router.huggingface.co/v1"

    /// Static constant for the default context length
    private static var defaultContextLength: Int {
        if self.unifiedMemorySize < 16 {
            return 16_000
        } else if (16...32).contains(self.unifiedMemorySize) {
            return 48_000
        } else {
            return 51_200
        }
    }

    /// Static constant for the default temperature
    private static let defaultTemperature: Double = 0.6
    /// Static constant for the default MLX max tokens
    private static let defaultMLXMaxTokens: Int = 2048
    /// Static constant for the default MLX top-p value
    private static let defaultMLXTopP: Double = 0.95

    /// The maximum consecutive malformed tool call attempts before breaking.
    public static var maxConsecutiveMalformedToolCalls: Int {
        return 3
    }

    /// A `String` representing the first instruction given to an LLM
    public static var systemPrompt: String {
        get {
            guard let systemPrompt = UserDefaults.standard.string(
                forKey: "systemPrompt"
            ) else {
                Self.systemPrompt = Self.defaultSystemPrompt
                return Self.defaultSystemPrompt
            }
            return systemPrompt
        }
        set {
            // Save
            UserDefaults.standard.set(newValue, forKey: "systemPrompt")
            // Notify
            Task { @MainActor in
                NavigationState.shared.systemPromptChanged = true
            }
        }
    }

    /// A `Bool` representing whether speculative decoding is used
    public static var useSpeculativeDecoding: Bool {
        get {
            // Set default
            if !UserDefaults.standard.exists(
                key: "useSpeculativeDecoding"
            ) {
                // Default to false
                Self.useSpeculativeDecoding = false
            }
            return UserDefaults.standard.bool(
                forKey: "useSpeculativeDecoding"
            )
        }
        set {
            UserDefaults.standard.set(
                newValue,
                forKey: "useSpeculativeDecoding"
            )
        }
    }

    /// Computed property for the location of the local LLM used for speculative decoding
    static var speculativeDecodingModelUrl: URL? {
        get {
            return UserDefaults.standard.url(
                forKey: "specularDecodingModelUrl"
            )
        }
        set {
            UserDefaults.standard.set(
                newValue,
                forKey: "specularDecodingModelUrl"
            )
        }
    }

    /// Computed property for the location of the local worker LLM
    static var completionsModelUrl: URL? {
        get {
            return UserDefaults.standard.url(
                forKey: "completionsModelUrl"
            )
        }
        set {
            UserDefaults.standard.set(
                newValue,
                forKey: "completionsModelUrl"
            )
        }
    }

    /// Computed property for the location of the local LLM used for simple tasks
    static var workerModelUrl: URL? {
        get {
            return UserDefaults.standard.url(
                forKey: "workerModelUrl"
            )
        }
        set {
            UserDefaults.standard.set(
                newValue,
                forKey: "workerModelUrl"
            )
        }
    }

    /// A `Bool` representing whether a server is used
    public static var useServer: Bool {
        get {
            // Set default
            if !UserDefaults.standard.exists(key: "useServer") {
                // Default to true for Hugging Face remote inference
                Self.useServer = true
            }
            return UserDefaults.standard.bool(
                forKey: "useServer"
            )
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "useServer")
        }
    }

    /// A `Bool` representing whether Apple Foundation Models are used for chat (text generation).
    /// Defaults to true: when available, Foundation Models are used for text-only chat.
    public static var useFoundationModels: Bool {
        get {
            if !UserDefaults.standard.exists(key: "useFoundationModels") {
                Self.useFoundationModels = true
            }
            return UserDefaults.standard.bool(
                forKey: "useFoundationModels"
            )
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "useFoundationModels")
        }
    }

    /// A `String` containing the endpoint's url
    public static var endpoint: String {
        get {
            guard let endpoint = UserDefaults.standard.string(
                forKey: "endpoint"
            ) else {
                Self.endpoint = Self.defaultEndpoint
                return Self.defaultEndpoint
            }
            return endpoint.replacingSuffix(
                "/",
                with: ""
            )
        }
        set {
            // Save
            UserDefaults.standard.set(newValue, forKey: "endpoint")
        }
    }

    /// A `String` containing the endpoint url's format version
    public static var endpointFormatVersion: Int {
        get {
            // Set default
            if !UserDefaults.standard.exists(
                key: "endpointFormatVersion"
            ) {
                Self.endpointFormatVersion = 0
            }
            return UserDefaults.standard.integer(forKey: "endpointFormatVersion")
        }
        set {
            // Save
            UserDefaults.standard.set(newValue, forKey: "endpointFormatVersion")
        }
    }

    /// Computed property for inference API key
    public static var inferenceApiKey: String {
        set {
            let defaults: SecureDefaults = SecureDefaults.defaults()
            defaults.set(newValue, forKey: "inferenceApiKey")
        }
        get {
            let defaults: SecureDefaults = SecureDefaults.defaults()
            return defaults.string(forKey: "inferenceApiKey") ?? ""
        }
    }

    /// A `String` representing the name of the remote model
    public static var serverModelName: String {
        get {
            guard let serverModelName = UserDefaults.standard.string(
                forKey: "remoteModelName"
            ) else {
                return "meta-llama/Llama-3.1-8B-Instruct"
            }
            return serverModelName
        }
        set {
            // Save
            UserDefaults.standard.set(newValue, forKey: "remoteModelName")
        }
    }

    /// A `Bool` representing whether the LLM has vision
    public static var serverModelHasVision: Bool {
        get {
            // Set default
            if !UserDefaults.standard.exists(key: "serverModelHasVision") {
                // Default to false
                Self.serverModelHasVision = false
            }
            return UserDefaults.standard.bool(
                forKey: "serverModelHasVision"
            )
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "serverModelHasVision")
        }
    }

    /// A `Bool` representing whether the inference provider supports tool calling natively
    public static var hasNativeToolCalling: Bool {
        get {
            // Set default
            if !UserDefaults.standard.exists(key: "hasNativeToolCalling") {
                // Use default
                Self.hasNativeToolCalling = Self.providerSupportsToolCalling() ?? false
            }
            return UserDefaults.standard.bool(
                forKey: "hasNativeToolCalling"
            )
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "hasNativeToolCalling")
        }
    }

    /// A function to check if the provider selected supports tool calling
    public static func providerSupportsToolCalling() -> Bool? {
        // Check inference provider
        for provider in Provider.popularProviders {
            // If matches, use provider value
            if Self.endpoint == provider.endpointUrl.absoluteString {
                return provider.supportsToolCalling
            }
        }
        // Default to nil
        return nil
    }

    /// A `String` representing the name of the remote worker model
    public static var serverWorkerModelName: String {
        get {
            guard let serverWorkerModelName = UserDefaults.standard.string(
                forKey: "serverWorkerModelName"
            ) else {
                return "meta-llama/Llama-3.1-8B-Instruct:fastest"
            }
            return serverWorkerModelName
        }
        set {
            // Save
            UserDefaults.standard.set(newValue, forKey: "serverWorkerModelName")
        }
    }

    /// A array of `[String]` representing the names of custom models
    public static var customModelNames: [String] {
        get {
            guard let customModelNames: [String] = UserDefaults.standard.array(
                forKey: "customModelNames"
            ) as? [String] else {
                return []
            }
            return customModelNames
        }
        set {
            // Save
            UserDefaults.standard.set(newValue, forKey: "customModelNames")
        }
    }

    /// A `Bool` representing if server setup is complete
    public static var serverModelSetupComplete: Bool {
        return !Self.serverModelName.isEmpty && !Self.endpoint.isEmpty
    }

    /// Whether the configured endpoint uses HTTP (not HTTPS) to a non-localhost host.
    /// This means API keys would be transmitted in plaintext.
    public static var isInsecureRemoteEndpoint: Bool {
        guard let url = URL(string: endpoint) else { return false }
        let scheme = url.scheme?.lowercased() ?? ""
        guard scheme == "http" else { return false }
        let host = url.host?.lowercased() ?? ""
        let localHosts: Set<String> = ["localhost", "127.0.0.1", "[::1]"]
        return !localHosts.contains(host)
    }

    /// Static constant which controls the amount of context an LLM can remember
    public static var contextLength: Int {
        get {
            return UserDefaults.standard.integer(
                forKey: "contextLength"
            )
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "contextLength")
        }
    }

    /// Static constant which controls how creative an LLM is
    public static var temperature: Double {
        get {
            return UserDefaults.standard.double(
                forKey: "temperature"
            )
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "temperature")
        }
    }

    /// Maximum output tokens for MLX generation
    public static var mlxMaxTokens: Int {
        get {
            if !UserDefaults.standard.exists(key: "mlxMaxTokens") {
                Self.mlxMaxTokens = defaultMLXMaxTokens
            }
            return UserDefaults.standard.integer(
                forKey: "mlxMaxTokens"
            )
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "mlxMaxTokens")
        }
    }

    /// Top-p nucleus sampling for MLX generation
    public static var mlxTopP: Double {
        get {
            if !UserDefaults.standard.exists(key: "mlxTopP") {
                Self.mlxTopP = defaultMLXTopP
            }
            return UserDefaults.standard.double(
                forKey: "mlxTopP"
            )
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "mlxTopP")
        }
    }

    /// Core ML compute preference for classifiers and on-device models.
    public static var coreMLComputePreference: CoreMLComputePreference {
        get {
            let raw = UserDefaults.standard.string(forKey: "coreMLComputePreference")
                ?? CoreMLComputePreference.cpuAndNeuralEngine.rawValue
            return CoreMLComputePreference(rawValue: raw) ?? .cpuAndNeuralEngine
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "coreMLComputePreference")
        }
    }

    /// Computed property for whether the LLM uses GPU acceleration
    static var useGPUAcceleration: Bool {
        get {
            // Set default
            if !UserDefaults.standard.exists(key: "useGPUAcceleration") {
                // Default to true
                Self.useGPUAcceleration = true
            }
            return UserDefaults.standard.bool(
                forKey: "useGPUAcceleration"
            )
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "useGPUAcceleration")
        }
    }

    /// Computed property for whether the LLM uses multimodal capabilities
    static var localModelUseVision: Bool {
        get {
            // Set default
            if !UserDefaults.standard.exists(key: "localModelUseVision") {
                // Default to true
                Self.localModelUseVision = false
            }
            return UserDefaults.standard.bool(
                forKey: "localModelUseVision"
            )
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "localModelUseVision")
        }
    }

    /// Computed property for the location of the VLM multimodal projector
    static var projectorModelUrl: URL? {
        get {
            return UserDefaults.standard.url(
                forKey: "projectorModelUrl"
            )
        }
        set {
            UserDefaults.standard.set(
                newValue,
                forKey: "projectorModelUrl"
            )
        }
    }

    /// Computed property for whether the local model has vision
    static var localModelHasVision: Bool {
        return Self.localModelUseVision || Self.projectorModelUrl == nil
    }

    /// A `Bool` representing whether context compression is enabled
    public static var enableContextCompression: Bool {
        get {
            // Set default
            if !UserDefaults.standard.exists(key: "enableContextCompression") {
                // Default to true
                Self.enableContextCompression = true
            }
            return UserDefaults.standard.bool(
                forKey: "enableContextCompression"
            )
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "enableContextCompression")
        }
    }

    /// Static constant for the default compression token threshold
    private static let defaultCompressionTokenThreshold: Int = 2000

    /// An `Int` representing the token threshold above which tool results will be compressed
    public static var compressionTokenThreshold: Int {
        get {
            // Set default if not set
            if !UserDefaults.standard.exists(key: "compressionTokenThreshold") {
                Self.compressionTokenThreshold = defaultCompressionTokenThreshold
            }
            return UserDefaults.standard.integer(
                forKey: "compressionTokenThreshold"
            )
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "compressionTokenThreshold")
        }
    }

    /// Whether flash attention should be auto-enabled based on context length and GPU memory
    @MainActor
    public static var shouldAutoEnableFlashAttention: Bool {
        return GPUMonitor.shared.shouldEnableFlashAttention(
            contextLength: Self.contextLength
        )
    }

    /// Function that sets default values
    public static func setDefaults() {
        systemPrompt = defaultSystemPrompt
        contextLength = defaultContextLength
        temperature = defaultTemperature
        mlxMaxTokens = defaultMLXMaxTokens
        mlxTopP = defaultMLXTopP
        enableContextCompression = true
        compressionTokenThreshold = defaultCompressionTokenThreshold
        useFoundationModels = true
        useServer = true
        if !UserDefaults.standard.exists(key: "endpoint") {
            endpoint = defaultEndpoint
        }
        if !UserDefaults.standard.exists(key: "remoteModelName") {
            serverModelName = "meta-llama/Llama-3.1-8B-Instruct"
        }
        if !UserDefaults.standard.exists(key: "serverWorkerModelName") {
            serverWorkerModelName = "meta-llama/Llama-3.1-8B-Instruct:fastest"
        }
    }

    /// Function to switch to normal system prompt
    public static func setNormalSystemPrompt() {
        systemPrompt = defaultSystemPrompt
    }

}
