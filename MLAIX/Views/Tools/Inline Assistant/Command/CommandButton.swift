//
//  CommandButton.swift
//  MLAI
//
//  Created by Bean John on 11/18/24.
//

import SwiftUI

struct CommandButton: View {
	
	@Environment(Model.self) private var model
	@Environment(CommandManager.self) private var commandManager
	@Environment(InlineAssistantController.self) private var inlineAssistantController
	
	@State private var isEditingCommand: Bool = false
	
	@Binding var command: Command
	var action: () -> Void
	
    var body: some View {
		Button {
			self.action()
		} label: {
			label
		}
		.buttonStyle(.plain)
		.contextMenu {
			contextMenu
		}
		.sheet(isPresented: $isEditingCommand) {
			CommandEditorView(
				command: $command,
				isEditingCommand: $isEditingCommand
			)
			.frame(minWidth: 350, minHeight: 300)
		}
    }
	
	var label: some View {
		Text(self.command.name)
			.bold()
			.padding(5)
			.background {
				RoundedRectangle(
					cornerRadius: 5
				)
				.fill(Color.textBackground)
			}
			.font(.body)
	}
	
	var contextMenu: some View {
		Group {
			Button {
				self.isEditingCommand.toggle()
			} label: {
				Text("Edit")
			}
			Button {
				self.commandManager.delete(self.command)
			} label: {
				Text("Delete")
			}
		}
	}
	
}
