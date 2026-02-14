//
//  DownloadManager.swift
//  MLAI
//
//  Created by Bean John on 9/22/24.
//

@preconcurrency import DefaultModels
import Foundation
import OSLog
import Synchronization
import SwiftUI

// MARK: - DownloadSessionDelegate

/// Separated URLSession delegate so that DownloadManager itself does not need NSObject.
/// Callbacks are protected by Mutex for thread safety (delegate methods are called on arbitrary threads).
final class DownloadSessionDelegate: NSObject, URLSessionDelegate, URLSessionDownloadDelegate, @unchecked Sendable {

	private static let logger: Logger = .init(
		subsystem: Bundle.main.logSubsystem,
		category: String(describing: DownloadSessionDelegate.self)
	)

	private let _onProgress = Mutex<(@Sendable (_ taskId: Int) -> Void)?>(nil)
	private let _onComplete = Mutex<(@Sendable (_ taskId: Int, _ error: Error?) -> Void)?>(nil)
	private let _onFinishDownloading = Mutex<(@Sendable (_ fileName: String, _ location: URL) -> Void)?>(nil)

	var onProgress: (@Sendable (_ taskId: Int) -> Void)? {
		get { _onProgress.withLock { $0 } }
		set { _onProgress.withLock { $0 = newValue } }
	}

	var onComplete: (@Sendable (_ taskId: Int, _ error: Error?) -> Void)? {
		get { _onComplete.withLock { $0 } }
		set { _onComplete.withLock { $0 = newValue } }
	}

	var onFinishDownloading: (@Sendable (_ fileName: String, _ location: URL) -> Void)? {
		get { _onFinishDownloading.withLock { $0 } }
		set { _onFinishDownloading.withLock { $0 = newValue } }
	}

	func urlSession(
		_: URLSession,
		downloadTask: URLSessionDownloadTask,
		didWriteData _: Int64,
		totalBytesWritten _: Int64,
		totalBytesExpectedToWrite _: Int64
	) {
		onProgress?(downloadTask.taskIdentifier)
	}

	func urlSession(
		_: URLSession,
		task: URLSessionTask,
		didCompleteWithError error: Error?
	) {
		if let error = error {
			Self.logger.error("Download failed: \(error.localizedDescription)")
		} else {
			Self.logger.info("Task finished: \(task.taskIdentifier)")
		}
		onComplete?(task.taskIdentifier, error)
	}

	func urlSession(
		_: URLSession,
		downloadTask: URLSessionDownloadTask,
		didFinishDownloadingTo location: URL
	) {
		let fileName = downloadTask.originalRequest?.url?.lastPathComponent ?? "defaultModel.gguf"
		let destinationURL = Settings.dirUrl.appending(path: fileName)
		let fileManager = FileManager.default
		try? fileManager.removeItem(at: destinationURL)
		do {
			let folderExists: Bool = (try? Settings.dirUrl.checkResourceIsReachable()) ?? false
			if !folderExists {
				try fileManager.createDirectory(
					at: Settings.dirUrl,
					withIntermediateDirectories: false
				)
			}
			try fileManager.moveItem(at: location, to: destinationURL)
			onFinishDownloading?(fileName, destinationURL)
		} catch {
			Self.logger.error("Failed to move downloaded file from \(location.absoluteString) to \(destinationURL.absoluteString): \(error.localizedDescription)")
		}
	}
}

// MARK: - DownloadManager

@MainActor @Observable
/// Controls the download of LLMs
public final class DownloadManager {

    private static let logger: Logger = .init(
        subsystem: Bundle.main.logSubsystem,
        category: String(describing: DownloadManager.self)
    )

	/// Global instance of `DownloadManager`
	static let shared: DownloadManager = DownloadManager()

	/// Property for currently downloading URL session
	private var urlSession: URLSession!
	/// Separated delegate for URLSession callbacks
	private let sessionDelegate = DownloadSessionDelegate()
	/// A `Bool` representing whether the model should be added to the model manager
	private var shouldAddModel: Bool = true
	/// Download progress
	var tasks: [URLSessionTask] = []
	/// Last progress update timestamp
	var lastUpdatedAt = Date()
	/// Whether the model was downloaded
	var didFinishDownloadingModel: Bool = false

	private init() {
		let config = URLSessionConfiguration.background(
			withIdentifier: "com.donaldfilimon.mlai.DownloadManager"
		)
		config.isDiscretionary = false

		// Warning: Make sure that the URLSession is created only once (if an URLSession still
		// exists from a previous download, it doesn't create a new URLSession object but returns
		// the existing one with the old delegate object attached)
		self.urlSession = URLSession(
			configuration: config,
			delegate: sessionDelegate,
			delegateQueue: OperationQueue()
		)

		// Wire delegate closures to update self on MainActor
		sessionDelegate.onProgress = { @Sendable [weak self] _ in
			Task { @MainActor in
				guard let self else { return }
				let now = Date()
				if self.lastUpdatedAt.timeIntervalSince(now) > 10 {
					self.lastUpdatedAt = now
				}
			}
		}

		sessionDelegate.onComplete = { @Sendable [weak self] taskId, _ in
			Task { @MainActor in
				guard let self else { return }
				self.tasks.removeAll { $0.taskIdentifier == taskId }
			}
		}

		sessionDelegate.onFinishDownloading = { @Sendable [weak self] fileName, destinationURL in
			Task { @MainActor in
				guard let self else { return }
				if self.shouldAddModel {
					if Settings.modelUrl == nil {
						Settings.modelUrl = destinationURL
					}
					ModelManager.shared.add(destinationURL)
				}
				self.didFinishDownloadingModel = true
				LengthyTasksController.shared.tasks = LengthyTasksController.shared.tasks.filter {
					$0.name != "Downloading model \(fileName)"
				}
			}
		}

		// Update lists of tasks for UI
		self.updateTasks()
	}

	/// Function to download an LLM
	public func downloadModel(
		model: HuggingFaceModel
	) async {
		await downloadModel(url: model.url)
	}

	/// Function to download an LLM
	public func downloadModel(
		url: URL
	) async {
		// Check if accessible
		let isValid = await URL.verifyURL(url: url)
		if isValid {
			self.startDownload(url: url)
		} else {
			// If not accessible, try mirror
			let mirrorUrlString: String = url.absoluteString.replacingOccurrences(
				of: "huggingface.co",
				with: "hf-mirror.com"
			)
			guard let mirrorUrl = URL(string: mirrorUrlString) else { return }
			self.startDownload(url: mirrorUrl)
		}
		// Add lengthy task
		LengthyTasksController.shared.addTask(
			id: UUID(),
			task: String(
				localized: "Downloading model \(url.lastPathComponent)"
			)
		)
	}

	/// Function to download the default large language model
	public func downloadDefaultModel() async {
		self.shouldAddModel = true
		let model: HuggingFaceModel = await DefaultModels.recommendedModel
        Self.logger.info("Trying to download \(model.name, privacy: .public)")
		await self.downloadModel(model: model)
	}

	/// Function to download the default completions model
    public func downloadDefaultCompletionsModel() async {
        self.shouldAddModel = false
        guard let modelUrl = URL(string: "https://huggingface.co/mradermacher/Qwen3-1.7B-Base-GGUF/resolve/main/Qwen3-1.7B-Base.Q4_K_M.gguf") else { return }
        Self.logger.info("Trying to download \(modelUrl.deletingLastPathComponent().lastPathComponent, privacy: .public)")
        await self.downloadModel(url: modelUrl)
        let fileName: String = modelUrl.lastPathComponent
        let destinationUrl: URL = Settings.dirUrl.appendingPathComponent(fileName)
        InferenceSettings.completionsModelUrl = destinationUrl
    }

	private func startDownload(url: URL) {
        Self.logger.info("Starting download for resource \"\(url, privacy: .public)\"")
		if self.tasks.contains(where: { $0.originalRequest?.url == url }) {
			return
		}
		let task: URLSessionTask = urlSession.downloadTask(with: url)
		self.tasks.append(task)
		task.resume()
	}

	private func updateTasks() {
		self.urlSession.getAllTasks { [weak self] tasks in
			Task { @MainActor in
				guard let self else { return }
				self.tasks = tasks
				self.lastUpdatedAt = Date()
			}
		}
	}

	/// A `View` that shows download progress
	public var progressView: some View {
		Group {
			ForEach(
				self.tasks,
				id: \.self
			) { task in
				ProgressView(task.progress)
					.progressViewStyle(.linear)
			}
		}
		.padding(.top)
	}
}
