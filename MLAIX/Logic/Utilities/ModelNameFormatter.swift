//
//  ModelNameFormatter.swift
//  MLAI
//
//  Created by MLAI on 2/5/26.
//

import Foundation

enum ModelNameFormatter {

    static let variantSuffixTokens: Set<String> = ["free", "exacto"]

    static func formatModelName(
        _ name: String,
        knownModels: [KnownModel] = KnownModel.availableModels
    ) -> String {
        let components = parseModelIdentifier(name)

        if let knownModel = KnownModel.findModel(byIdentifier: name, in: knownModels) {
            let matchedComponents = parseModelIdentifier(knownModel.primaryName)
            var displayName: String
            if let explicitName = knownModel.displayName?.trimmingCharacters(in: .whitespacesAndNewlines),
               !explicitName.isEmpty {
                displayName = explicitName
            } else {
                let providerSource: String
                if knownModel.organization == .other, let orgId = knownModel.organizationIdentifier {
                    providerSource = orgId
                } else {
                    providerSource = components.provider ?? knownModel.organization.rawValue
                }
                let baseName = String(knownModel.primaryName.split(separator: ":").first ?? Substring(knownModel.primaryName))
                displayName = buildDisplayName(
                    provider: providerSource,
                    model: baseName,
                    variant: matchedComponents.variant
                )
            }

            let providerForPrefix: String
            if knownModel.organization == .other, let orgId = knownModel.organizationIdentifier {
                providerForPrefix = orgId
            } else {
                providerForPrefix = components.provider ?? knownModel.organization.rawValue
            }

            displayName = applyProviderPrefixIfNeeded(displayName, provider: providerForPrefix)
            displayName = harmonizeVariantDisplay(displayName, expectedVariant: matchedComponents.variant)
            return displayName
        }

        return buildDisplayName(provider: components.provider, model: components.model, variant: components.variant)
    }

    static func parseModelIdentifier(
        _ name: String
    ) -> (provider: String?, model: String, variant: String?) {
        var remainder = name
        var provider: String? = nil
        if let slashIndex = remainder.firstIndex(of: "/") {
            provider = String(remainder[..<slashIndex])
            remainder = String(remainder[remainder.index(after: slashIndex)...])
        }
        var variant: String? = nil
        if let colonIndex = remainder.firstIndex(of: ":") {
            variant = String(remainder[remainder.index(after: colonIndex)...])
            remainder = String(remainder[..<colonIndex])
        }
        return (provider, remainder, variant)
    }

    static func buildDisplayName(provider: String?, model: String, variant: String?) -> String {
        let formattedModel = formatModelComponent(model)
        var result = ""
        if let provider {
            result = "\(formatProviderName(provider)): "
        }
        result += formattedModel
        if let variant = variant?.trimmingCharacters(in: .whitespacesAndNewlines), !variant.isEmpty {
            let lowerVariant = variant.lowercased()
            if variantSuffixTokens.contains(lowerVariant) {
                result += " (\(lowerVariant))"
            } else {
                result += " \(variant)"
            }
        }
        return result
    }

    static func formatProviderName(_ provider: String) -> String {
        return (provider.prefix(1).uppercased() + provider.dropFirst().lowercased())
            .replacingOccurrences(of: "Bytedance", with: "ByteDance")
            .replacingOccurrences(of: "Openrouter", with: "OpenRouter")
            .replacingOccurrences(of: "Deepseek", with: "DeepSeek")
            .replacingOccurrences(of: "Deepcogito", with: "DeepCogito")
            .replacingOccurrences(of: "X-ai", with: "xAI")
            .replacingOccurrences(of: "Meta-llama", with: "Meta-Llama")
            .replacingOccurrences(of: "Minimax", with: "MiniMax")
            .replacingOccurrences(of: "Z-ai", with: "Zhipu AI")
            .replacingOccurrences(of: "Nousresearch", with: "NousResearch")
            .replacingSuffix("ai", with: "AI")
            .replacingSuffix("org", with: "Org")
            .replacingSuffix("labs", with: "Labs")
    }

    static func formatModelComponent(_ model: String) -> String {
        var spacedResult = ""
        for (index, char) in model.enumerated() {
            if char.isUppercase && index > 0 {
                let previousIndex = model.index(model.startIndex, offsetBy: index - 1)
                if model[previousIndex].isLowercase {
                    spacedResult += " "
                }
            }
            spacedResult.append(char)
        }
        let condensed = spacedResult.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return condensed.lowercased()
    }

    static func applyProviderPrefixIfNeeded(_ displayName: String, provider: String?) -> String {
        guard let provider else { return displayName.trimmingCharacters(in: .whitespacesAndNewlines) }
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.contains(":") {
            return trimmed
        }
        return "\(formatProviderName(provider)): \(trimmed)"
    }

    static func harmonizeVariantDisplay(
        _ displayName: String,
        expectedVariant rawVariant: String?
    ) -> String {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let rawVariant = rawVariant?.trimmingCharacters(in: .whitespacesAndNewlines), !rawVariant.isEmpty else {
            return removeRecognizedVariantSuffix(from: trimmed)
        }
        let lowerVariant = rawVariant.lowercased()
        if variantSuffixTokens.contains(lowerVariant) {
            if trimmed.range(of: "(\(lowerVariant))", options: .caseInsensitive) != nil {
                return trimmed
            }
            let base = removeRecognizedVariantSuffix(from: trimmed)
            return base + " (\(lowerVariant))"
        } else {
            if trimmed.range(of: rawVariant, options: .caseInsensitive) != nil {
                return trimmed
            }
            return trimmed + " \(rawVariant)"
        }
    }

    static func removeRecognizedVariantSuffix(from displayName: String) -> String {
        var result = displayName
        for token in variantSuffixTokens {
            let suffix = " (\(token))"
            if result.lowercased().hasSuffix(suffix) {
                result = String(result.dropLast(suffix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return result
    }
}

enum ModelSearchMatcher {
    static func fuzzyMatch(_ text: String, query: String) -> Bool {
        if query.isEmpty {
            return true
        }

        // Normalize both strings: lowercase and remove special characters
        let normalizedText = text.lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "/", with: " ")
            .replacingOccurrences(of: ":", with: " ")

        let normalizedQuery = query.lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")

        // Split into tokens
        let textTokens = normalizedText.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        let queryTokens = normalizedQuery.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }

        // Check if all query tokens are found in text tokens with stricter matching
        for queryToken in queryTokens {
            let found = textTokens.contains { textToken in
                // Match if:
                // 1. Text token starts with query token (prefix match)
                // 2. Query token is at least 3 chars and text token contains it
                // 3. Exact match
                if textToken.hasPrefix(queryToken) {
                    return true
                }
                if queryToken.count >= 3 && textToken.contains(queryToken) {
                    return true
                }
                // Also check if query token starts with text token (for partial typing)
                if queryToken.count >= 3 && queryToken.hasPrefix(textToken) {
                    return true
                }
                return false
            }
            if !found {
                return false
            }
        }

        return true
    }
}
