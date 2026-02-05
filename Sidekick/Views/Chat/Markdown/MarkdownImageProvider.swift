//
//  MarkdownImageProvider.swift
//  Sidekick
//
//  Created by John Bean on 3/15/25.
//

import Foundation
import LaTeXSwiftUI
import MarkdownUI
import NetworkImage
import SwiftUI
import WebKit
import WebViewKit

struct MarkdownImageProvider: ImageProvider {

	let scaleFactor: CGFloat

    public func makeImage(
		url: URL?
	) -> some View {
        MarkdownImageView(url: url, scaleFactor: scaleFactor)
	}

}

/// Internal view that handles the actual image rendering on MainActor
private struct MarkdownImageView: View {
    let url: URL?
    let scaleFactor: CGFloat

    var body: some View {
        Group {
            if let url = url {
                if url.isWebURL {
                    networkImage(url: url)
                } else if url.isFileURL {
                    fileImage(url: url)
                } else if url.absoluteString.hasPrefix("latex://"),
                          let latexStr = url.withoutSchema.removingPercentEncoding {
                    LaTeX(latexStr)
                        .blockMode(.blockViews)
                        .errorMode(.original)
                        .renderingStyle(.original)
                } else {
                    let fileUrl = URL(fileURLWithPath: url.posixPath)
                    fileImage(url: fileUrl)
                }
            } else {
                imageLoadError
            }
        }
    }

    private func networkImage(url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty, .failure:
                imageLoadError
            case .success(let image):
                image
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .draggable(image)
                    .padding(.leading, 1)
            @unknown default:
                imageLoadError
            }
        }
    }

    private func fileImage(url: URL) -> some View {
        var url = url
        if !url.fileExists && url.pathComponents.count <= 2 {
            url = Settings
                .containerUrl
                .appendingPathComponent("Generated Images")
                .appendingPathComponent(url.lastPathComponent)
        }
        return Group {
            if let nsImage = NSImage(contentsOf: url) {
                if url.pathExtension == "svg" {
                    svgImage(url: url, nsImage: nsImage)
                } else {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .draggable(nsImage)
                        .padding(.leading, 1)
                }
            } else {
                imageLoadError
            }
        }
    }

    private func svgImage(url: URL, nsImage: NSImage) -> some View {
        ScrollView(.horizontal) {
            WebView(url: url) { view in
                view.setValue(false, forKeyPath: "drawsBackground")
            }
            .frame(
                width: nsImage.size.width * 0.5,
                height: nsImage.size.height * 0.5
            )
            .allowsHitTesting(false)
        }
        .padding(.horizontal, 5)
        .draggable(
            FilePromise(
                name: url.lastPathComponent,
                type: .fileURL
            ) { destUrl in
                FileManager.copyItem(from: url, to: destUrl)
            },
            preview: NSImage(contentsOf: url) ?? NSImage(named: "questionmark.app.fill")!
        )
    }

    private var imageLoadError: some View {
        Label("Error loading image", systemImage: "exclamationmark.square.fill")
            .foregroundColor(.red)
    }

}

struct MarkdownInlineImageProvider: InlineImageProvider {
	
	let scaleFactor: CGFloat
	
    @MainActor
	public func image(
		with url: URL,
		label: String
	) async throws -> Image {
		if url.isWebURL {
			let image = try await Image(
				DefaultNetworkImageLoader.shared.image(from: url),
				scale: 2 / scaleFactor,
				label: Text(label)
			)
			return image.renderingMode(.template).resizable()
        } else if url.isFileURL {
            // If file image
            return self.fileImage(url: url)
        } else if url.absoluteString.hasPrefix("latex://"),
			let latexStr = url.withoutSchema.removingPercentEncoding,
				let latexImage: Image = LaTeX(latexStr)
					.blockMode(.alwaysInline)
					.errorMode(.original)
					.padding(.horizontal, 3)
					.offset(y: 2.75)
					.generateImage(
						scale: scaleFactor
					) {
			return latexImage
				.renderingMode(.template)
				.resizable()
        } else {
            // Try converting to absolute path
            let fileUrl: URL = URL(
                fileURLWithPath: url.posixPath
            )
            // If file image
            return self.fileImage(url: fileUrl)
        }
	}

    private func fileImage(
        url: URL
    ) -> Image {
        var url: URL = url
        // Try to correct url
        if !url.fileExists && url.pathComponents.count <= 2 {
            url = Settings
                .containerUrl
                .appendingPathComponent("Generated Images")
                .appendingPathComponent(url.lastPathComponent)
        }
        if let nsImage: NSImage = NSImage(
            contentsOf: url
        ) {
            if url.pathExtension == "svg" {
                let configuration = NSImage.SymbolConfiguration(textStyle: .body, scale: .large)
                if let nsImage = NSImage(contentsOf: url)?.withSymbolConfiguration(
                    configuration
                ) {
                    return Image(nsImage: nsImage)
                }
            } else {
                return Image(nsImage: nsImage)
                    .resizable()
            }
        }
        return self.imageLoadError
    }
    
    var imageLoadError: Image {
        Image(systemName: "questionmark.square.fill")
    }
    
}
