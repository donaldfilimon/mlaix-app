//
//  ChatCommands.swift
//  MLAI
//
//  Commands for chat input: send message, toggle canvas, functions, web search.
//

import Foundation
import SwiftUI

@MainActor
public enum ChatCommands {

    static var commands: some Commands {
        CommandGroup(after: .pasteboard) {
            Button {
                NotificationCenter.default.post(name: Notifications.sendMessage.name, object: nil)
            } label: {
                Text("Send Message")
            }
            .keyboardShortcut(.return, modifiers: .command)

            Divider()

            Button {
                NotificationCenter.default.post(name: Notifications.toggleCanvas.name, object: nil)
            } label: {
                Text("Toggle Canvas")
            }
            .keyboardShortcut(.return, modifiers: [.command, .option])

            Divider()

            Button {
                NotificationCenter.default.post(name: Notifications.toggleFunctions.name, object: nil)
            } label: {
                Text("Toggle Functions")
            }
            .keyboardShortcut("f", modifiers: [.command, .shift])

            if RetrievalSettings.canUseWebSearch {
                Button {
                    NotificationCenter.default.post(name: Notifications.toggleWebSearch.name, object: nil)
                } label: {
                    Text("Toggle Web Search")
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }
        }
    }

}
