//
//  TextOutputFormat.swift
//  MLAI
//
//  Created by Bean John on 10/8/24.
//

import Splash
import SwiftUI

struct TextOutputFormat: OutputFormat {
	
	private let theme: Theme
	
	init(theme: Theme) {
		self.theme = theme
	}
	
	func makeBuilder() -> Builder {
		Builder(theme: self.theme)
	}
	
}

extension TextOutputFormat {
	
	struct Builder: OutputBuilder {
		
		private let theme: Theme
		private var accumulatedText: [AttributedString]
		
		fileprivate init(theme: Theme) {
			self.theme = theme
			self.accumulatedText = []
		}
		
		mutating func addToken(_ token: String, ofType type: TokenType) {
			let color = self.theme.tokenColors[type] ?? self.theme.plainTextColor
			var attributed = AttributedString(token)
			attributed.foregroundColor = Color(color)
			self.accumulatedText.append(attributed)
		}
		
		mutating func addPlainText(_ text: String) {
			var attributed = AttributedString(text)
			attributed.foregroundColor = Color(self.theme.plainTextColor)
			self.accumulatedText.append(attributed)
		}
		
		mutating func addWhitespace(_ whitespace: String) {
			self.accumulatedText.append(AttributedString(whitespace))
		}
		
		func build() -> Text {
			let combined = self.accumulatedText.reduce(AttributedString()) { partialResult, next in
				partialResult + next
			}
			return Text(combined)
		}
		
	}
	
}
