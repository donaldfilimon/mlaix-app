//
//  DeepResearchSettings.swift
//  MLAI
//
//  Created by Codex on 2/5/26.
//

import Foundation
import SwiftUI

public enum DeepResearchDepth: String, CaseIterable, Identifiable {
    case fast
    case balanced
    case thorough
    
    public var id: String { self.rawValue }
    
    var defaults: (minSources: Int, maxSources: Int, minToolCalls: Int, maxSections: Int) {
        switch self {
            case .fast:
                return (minSources: 4, maxSources: 6, minToolCalls: 4, maxSections: 4)
            case .balanced:
                return (minSources: 7, maxSources: 10, minToolCalls: 7, maxSections: 6)
            case .thorough:
                return (minSources: 10, maxSources: 14, minToolCalls: 10, maxSections: 8)
        }
    }
}

public enum DeepResearchSettings {
    
    public static var depth: DeepResearchDepth {
        get {
            guard let rawValue = UserDefaults.standard.string(forKey: "deepResearchDepth"),
                  let depth = DeepResearchDepth(rawValue: rawValue) else {
                return .balanced
            }
            return depth
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "deepResearchDepth")
            applyDepthDefaults(newValue)
        }
    }
    
    public static var minSources: Int {
        get {
            if !UserDefaults.standard.exists(key: "deepResearchMinSources") {
                UserDefaults.standard.set(
                    depth.defaults.minSources,
                    forKey: "deepResearchMinSources"
                )
            }
            return UserDefaults.standard.integer(forKey: "deepResearchMinSources")
        }
        set {
            UserDefaults.standard.set(max(1, newValue), forKey: "deepResearchMinSources")
        }
    }
    
    public static var maxSources: Int {
        get {
            if !UserDefaults.standard.exists(key: "deepResearchMaxSources") {
                UserDefaults.standard.set(
                    depth.defaults.maxSources,
                    forKey: "deepResearchMaxSources"
                )
            }
            return UserDefaults.standard.integer(forKey: "deepResearchMaxSources")
        }
        set {
            let value = max(newValue, minSources)
            UserDefaults.standard.set(value, forKey: "deepResearchMaxSources")
        }
    }
    
    public static var minToolCalls: Int {
        get {
            if !UserDefaults.standard.exists(key: "deepResearchMinToolCalls") {
                UserDefaults.standard.set(
                    depth.defaults.minToolCalls,
                    forKey: "deepResearchMinToolCalls"
                )
            }
            return UserDefaults.standard.integer(forKey: "deepResearchMinToolCalls")
        }
        set {
            UserDefaults.standard.set(max(1, newValue), forKey: "deepResearchMinToolCalls")
        }
    }
    
    public static var maxSections: Int {
        get {
            if !UserDefaults.standard.exists(key: "deepResearchMaxSections") {
                UserDefaults.standard.set(
                    depth.defaults.maxSections,
                    forKey: "deepResearchMaxSections"
                )
            }
            return UserDefaults.standard.integer(forKey: "deepResearchMaxSections")
        }
        set {
            UserDefaults.standard.set(max(1, newValue), forKey: "deepResearchMaxSections")
        }
    }
    
    public static func applyDepthDefaults(_ depth: DeepResearchDepth) {
        let defaults = depth.defaults
        minSources = defaults.minSources
        maxSources = defaults.maxSources
        minToolCalls = defaults.minToolCalls
        maxSections = defaults.maxSections
    }
}
