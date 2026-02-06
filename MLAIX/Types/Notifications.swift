//
//  Notifications.swift
//  MLAI
//
//  Created by Bean John on 10/10/24.
//

import Foundation

public enum Notifications: String, NotificationName, Sendable {

    case systemPromptChanged
    case changedInferenceConfig
    case didCommandSelectExpert
    case newConversation
    case switchToConversation
    case sendMessage
    case toggleCanvas
    case toggleFunctions
    case toggleWebSearch
    case showKeyboardShortcuts
    case showScriptTesting

}
