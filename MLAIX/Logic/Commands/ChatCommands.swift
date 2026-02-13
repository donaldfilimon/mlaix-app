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
                NavigationState.shared.sendMessageRequested = true
            } label: {
                Text("Send Message")
            }
            .keyboardShortcut(.return, modifiers: .command)

            Divider()

            Button {
                NavigationState.shared.toggleCanvasRequested = true
            } label: {
                Text("Toggle Canvas")
            }
            .keyboardShortcut(.return, modifiers: [.command, .option])

            Divider()

            Button {
                NavigationState.shared.toggleFunctionsRequested = true
            } label: {
                Text("Toggle Functions")
            }
            .keyboardShortcut("f", modifiers: [.command, .shift])

            if RetrievalSettings.canUseWebSearch {
                Button {
                    NavigationState.shared.toggleWebSearchRequested = true
                } label: {
                    Text("Toggle Web Search")
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }
        }
    }

}
