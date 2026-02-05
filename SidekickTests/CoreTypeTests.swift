//
//  CoreTypeTests.swift
//  MLAITests
//
//  Comprehensive unit tests for core MLAI types.
//

import Foundation
import Testing
@testable import MLAI

// MARK: - Sender Tests

struct SenderTests {

    @Test func testSenderRawValues() {
        #expect(Sender.user.rawValue == "user")
        #expect(Sender.assistant.rawValue == "assistant")
        #expect(Sender.system.rawValue == "system")
    }

    @Test func testSenderEncodeDecode() throws {
        let senders: [Sender] = [.user, .assistant, .system]
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for sender in senders {
            let data = try encoder.encode(sender)
            let decoded = try decoder.decode(Sender.self, from: data)
            #expect(decoded == sender)
        }
    }

    @Test func testSenderDecodeFromRawString() throws {
        let decoder = JSONDecoder()

        let userData = "\"user\"".data(using: .utf8)!
        let user = try decoder.decode(Sender.self, from: userData)
        #expect(user == .user)

        let assistantData = "\"assistant\"".data(using: .utf8)!
        let assistant = try decoder.decode(Sender.self, from: assistantData)
        #expect(assistant == .assistant)

        let systemData = "\"system\"".data(using: .utf8)!
        let system = try decoder.decode(Sender.self, from: systemData)
        #expect(system == .system)
    }

    @Test func testSenderEquatable() {
        #expect(Sender.user == Sender.user)
        #expect(Sender.assistant == Sender.assistant)
        #expect(Sender.system == Sender.system)
        #expect(Sender.user != Sender.assistant)
        #expect(Sender.user != Sender.system)
        #expect(Sender.assistant != Sender.system)
    }
}

// MARK: - Message Tests

struct MessageTests {

    @Test func testMessageInitWithText() {
        let message = Message(
            text: "Hello, world!",
            sender: .user
        )

        #expect(message.text == "Hello, world!")
        #expect(message.getSender() == .user)
        #expect(message.model == "Unknown")
        #expect(message.referencedURLs.isEmpty)
        #expect(message.outputEnded == false)
        #expect(message.expertId == nil)
        #expect(message.functionCallRecords == nil)
    }

    @Test func testMessageInitWithModel() {
        let message = Message(
            text: "Test message",
            sender: .assistant,
            model: "llama-3.2"
        )

        #expect(message.text == "Test message")
        #expect(message.getSender() == .assistant)
        #expect(message.model == "llama-3.2")
    }

    @Test func testMessageInitWithReferencedURLs() {
        let urls = [
            URL(string: "https://example.com")!,
            URL(string: "https://test.org")!
        ]
        let message = Message(
            text: "Check these links",
            sender: .user,
            referencedURLs: urls
        )

        #expect(message.referencedURLs.count == 2)
        #expect(message.referencedURLs[0].url == urls[0])
        #expect(message.referencedURLs[1].url == urls[1])
    }

    @Test func testMessageInitWithExpertId() {
        let expertId = UUID()
        let message = Message(
            text: "Expert message",
            sender: .assistant,
            expertId: expertId
        )

        #expect(message.expertId == expertId)
    }

    @Test func testMessageInitWithFunctionCallRecords() {
        let record = FunctionCallRecord(name: "testFunction")
        let message = Message(
            text: "Function result",
            sender: .assistant,
            functionCallRecords: [record]
        )

        #expect(message.functionCallRecords?.count == 1)
        #expect(message.functionCallRecords?.first?.name == "testFunction")
        #expect(message.hasFunctionCallRecords == true)
    }

    @Test func testMessageHasFunctionCallRecordsEmpty() {
        let message = Message(
            text: "No functions",
            sender: .assistant,
            functionCallRecords: []
        )

        #expect(message.hasFunctionCallRecords == false)
    }

    @Test func testMessageHasFunctionCallRecordsNil() {
        let message = Message(
            text: "No functions",
            sender: .assistant
        )

        #expect(message.hasFunctionCallRecords == false)
    }

    @Test func testMessageImageInit() {
        let imageUrl = URL(string: "file:///path/to/image.png")!
        let message = Message(
            imageUrl: imageUrl,
            prompt: "A beautiful sunset"
        )

        #expect(message.imageUrl == imageUrl)
        #expect(message.text.contains("A beautiful sunset"))
        #expect(message.getSender() == .system)
        #expect(message.model == "Image Playground Model")
        #expect(message.outputEnded == true)
    }

    @Test func testMessageContentTypeText() {
        let message = Message(
            text: "Text message",
            sender: .user
        )

        #expect(message.contentType == .text)
    }

    @Test func testMessageContentTypeImage() {
        let imageUrl = URL(string: "file:///path/to/image.png")!
        let message = Message(
            imageUrl: imageUrl,
            prompt: "Test prompt"
        )

        #expect(message.contentType == .image)
    }

    @Test func testMessageResponseTextWithoutReasoning() {
        let message = Message(
            text: "Simple response text",
            sender: .assistant
        )

        #expect(message.responseText == "Simple response text")
    }

    @Test func testMessageHasReasoningForUserMessage() {
        let message = Message(
            text: "<think>Some reasoning</think>Response",
            sender: .user
        )

        // User messages should never have reasoning
        #expect(message.hasReasoning == false)
    }

    @Test func testMessageEndFunction() {
        var message = Message(
            text: "Test",
            sender: .assistant
        )

        #expect(message.outputEnded == false)

        message.end()

        #expect(message.outputEnded == true)
    }

    @Test func testMessageIdentifiable() {
        let message1 = Message(text: "Test 1", sender: .user)
        let message2 = Message(text: "Test 2", sender: .user)

        #expect(message1.id != message2.id)
    }

    @Test func testMessageHashable() {
        let message1 = Message(text: "Test", sender: .user)
        let message2 = message1

        var set = Set<Message>()
        set.insert(message1)
        set.insert(message2)

        #expect(set.count == 1)
    }

    @Test func testMessageEncodeDecode() throws {
        let message = Message(
            text: "Encode test",
            sender: .assistant,
            model: "test-model"
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(message)
        let decoded = try decoder.decode(Message.self, from: data)

        #expect(decoded.id == message.id)
        #expect(decoded.text == message.text)
        #expect(decoded.getSender() == message.getSender())
        #expect(decoded.model == message.model)
    }

    @Test func testMessageEncodeDecodeWithReferencedURLs() throws {
        let urls = [URL(string: "https://example.com")!]
        let message = Message(
            text: "With URLs",
            sender: .user,
            referencedURLs: urls
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(message)
        let decoded = try decoder.decode(Message.self, from: data)

        #expect(decoded.referencedURLs.count == 1)
        #expect(decoded.referencedURLs[0].url == urls[0])
    }

    @Test func testMessageEncodeDecodeWithFunctionRecords() throws {
        var record = FunctionCallRecord(name: "testFunc")
        record.markAsFinished(status: .succeeded, result: "Success")

        let message = Message(
            text: "Function message",
            sender: .assistant,
            functionCallRecords: [record]
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(message)
        let decoded = try decoder.decode(Message.self, from: data)

        #expect(decoded.functionCallRecords?.count == 1)
        #expect(decoded.functionCallRecords?.first?.name == "testFunc")
        #expect(decoded.functionCallRecords?.first?.status == .succeeded)
    }

    @Test func testMessageTimestamps() {
        let beforeCreation = Date.now
        let message = Message(text: "Timestamp test", sender: .user)
        let afterCreation = Date.now

        #expect(message.startTime >= beforeCreation)
        #expect(message.startTime <= afterCreation)
        #expect(message.lastUpdated >= beforeCreation)
        #expect(message.lastUpdated <= afterCreation)
    }
}

// MARK: - Message.ContentType Tests

struct MessageContentTypeTests {

    @Test func testContentTypeRawValues() {
        #expect(Message.ContentType.text.rawValue == "text")
        #expect(Message.ContentType.image.rawValue == "image")
    }

    @Test func testContentTypeCaseIterable() {
        let allCases = Message.ContentType.allCases
        #expect(allCases.count == 2)
        #expect(allCases.contains(.text))
        #expect(allCases.contains(.image))
    }
}

// MARK: - Conversation Tests

struct ConversationTests {

    @Test func testConversationInit() {
        let conversation = Conversation(title: "Test Conversation")

        #expect(conversation.title == "Test Conversation")
        #expect(conversation.messages.isEmpty)
        #expect(conversation.expertId == nil)
        #expect(conversation.tokenCount == nil)
    }

    @Test func testConversationAddMessageSuccess() {
        var conversation = Conversation(title: "Test")
        let userMessage = Message(text: "Hello", sender: .user)

        let result = conversation.addMessage(userMessage)

        #expect(result == true)
        #expect(conversation.messages.count == 1)
        #expect(conversation.messages.first?.text == "Hello")
    }

    @Test func testConversationAddMessageSameSenderFails() {
        var conversation = Conversation(title: "Test")
        let userMessage1 = Message(text: "First", sender: .user)
        let userMessage2 = Message(text: "Second", sender: .user)

        let result1 = conversation.addMessage(userMessage1)
        let result2 = conversation.addMessage(userMessage2)

        #expect(result1 == true)
        #expect(result2 == false)
        #expect(conversation.messages.count == 1)
    }

    @Test func testConversationAddMessageAlternatingSenders() {
        var conversation = Conversation(title: "Test")
        let userMessage = Message(text: "Question", sender: .user)
        let assistantMessage = Message(text: "Answer", sender: .assistant)

        let result1 = conversation.addMessage(userMessage)
        let result2 = conversation.addMessage(assistantMessage)

        #expect(result1 == true)
        #expect(result2 == true)
        #expect(conversation.messages.count == 2)
    }

    @Test func testConversationAddEmptyUserMessageFails() {
        var conversation = Conversation(title: "Test")
        let emptyMessage = Message(text: "", sender: .user)

        let result = conversation.addMessage(emptyMessage)

        #expect(result == false)
        #expect(conversation.messages.isEmpty)
    }

    @Test func testConversationAddEmptyAssistantMessageSucceeds() {
        var conversation = Conversation(title: "Test")
        let userMessage = Message(text: "Hello", sender: .user)
        let emptyAssistantMessage = Message(text: "", sender: .assistant)

        _ = conversation.addMessage(userMessage)
        let result = conversation.addMessage(emptyAssistantMessage)

        // Empty assistant messages are allowed (streaming start)
        #expect(result == true)
    }

    @Test func testConversationUpdateMessage() {
        var conversation = Conversation(title: "Test")
        var userMessage = Message(text: "Original", sender: .user)
        _ = conversation.addMessage(userMessage)

        userMessage.text = "Updated"
        conversation.updateMessage(userMessage)

        #expect(conversation.messages.first?.text == "Updated")
    }

    @Test func testConversationGetMessage() {
        var conversation = Conversation(title: "Test")
        let message = Message(text: "Find me", sender: .user)
        _ = conversation.addMessage(message)

        let found = conversation.getMessage(message.id)

        #expect(found != nil)
        #expect(found?.text == "Find me")
    }

    @Test func testConversationGetMessageNotFound() {
        let conversation = Conversation(title: "Test")
        let randomId = UUID()

        let found = conversation.getMessage(randomId)

        #expect(found == nil)
    }

    @Test func testConversationDropLastMessage() {
        var conversation = Conversation(title: "Test")
        let message1 = Message(text: "First", sender: .user)
        let message2 = Message(text: "Second", sender: .assistant)
        _ = conversation.addMessage(message1)
        _ = conversation.addMessage(message2)

        conversation.dropLastMessage()

        #expect(conversation.messages.count == 1)
        #expect(conversation.messages.first?.text == "First")
    }

    @Test func testConversationLastUpdated() {
        var conversation = Conversation(title: "Test")
        let createdAt = conversation.createdAt

        // No messages, should return createdAt
        #expect(conversation.lastUpdated == createdAt)

        let message = Message(text: "Test", sender: .user)
        _ = conversation.addMessage(message)

        // With messages, should return message's lastUpdated
        #expect(conversation.lastUpdated >= createdAt)
    }

    @Test func testConversationMessagesWithSnapshots() {
        var conversation = Conversation(title: "Test")
        var messageWithSnapshot = Message(text: "With snapshot", sender: .user)
        messageWithSnapshot.snapshot = Snapshot(text: "Code here")

        let messageWithoutSnapshot = Message(text: "No snapshot", sender: .assistant)

        _ = conversation.addMessage(messageWithSnapshot)
        _ = conversation.addMessage(messageWithoutSnapshot)

        #expect(conversation.messagesWithSnapshots.count == 1)
        #expect(conversation.hasSnapshots == true)
    }

    @Test func testConversationHasSnapshotsFalse() {
        var conversation = Conversation(title: "Test")
        let message = Message(text: "No snapshot", sender: .user)
        _ = conversation.addMessage(message)

        #expect(conversation.hasSnapshots == false)
        #expect(conversation.messagesWithSnapshots.isEmpty)
    }

    @Test func testConversationEquatable() {
        let conversation1 = Conversation(title: "Test 1")
        var conversation2 = conversation1
        let conversation3 = Conversation(title: "Test 3")

        #expect(conversation1 == conversation2)
        #expect(conversation1 != conversation3)

        // Modifying title shouldn't affect equality (based on id)
        conversation2.title = "Modified"
        #expect(conversation1 == conversation2)
    }

    @Test func testConversationIdentifiable() {
        let conversation1 = Conversation(title: "Test 1")
        let conversation2 = Conversation(title: "Test 2")

        #expect(conversation1.id != conversation2.id)
    }

    @Test func testConversationHashable() {
        let conversation1 = Conversation(title: "Test")
        let conversation2 = conversation1

        var set = Set<Conversation>()
        set.insert(conversation1)
        set.insert(conversation2)

        #expect(set.count == 1)
    }

    @Test func testConversationEncodeDecode() throws {
        var conversation = Conversation(title: "Encode Test")
        let message = Message(text: "Test message", sender: .user)
        _ = conversation.addMessage(message)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(conversation)
        let decoded = try decoder.decode(Conversation.self, from: data)

        #expect(decoded.id == conversation.id)
        #expect(decoded.title == conversation.title)
        #expect(decoded.messages.count == 1)
        #expect(decoded.messages.first?.text == "Test message")
    }

    @Test func testConversationEncodeDecodeWithExpertId() throws {
        var conversation = Conversation(title: "Expert Test")
        conversation.expertId = UUID()

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(conversation)
        let decoded = try decoder.decode(Conversation.self, from: data)

        #expect(decoded.expertId == conversation.expertId)
    }

    @Test func testConversationEncodeDecodeEmpty() throws {
        let conversation = Conversation(title: "Empty")

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(conversation)
        let decoded = try decoder.decode(Conversation.self, from: data)

        #expect(decoded.id == conversation.id)
        #expect(decoded.messages.isEmpty)
    }
}

// MARK: - Command Tests

struct CommandTests {

    @Test func testCommandInit() {
        let command = Command(name: "Test Command", prompt: "Do something")

        #expect(command.name == "Test Command")
        #expect(command.prompt == "Do something")
    }

    @Test func testCommandIdentifiable() {
        let command1 = Command(name: "Cmd 1", prompt: "Prompt 1")
        let command2 = Command(name: "Cmd 2", prompt: "Prompt 2")

        #expect(command1.id != command2.id)
    }

    @Test func testCommandEncodeDecode() throws {
        let command = Command(name: "Encode Test", prompt: "Test prompt")

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(command)
        let decoded = try decoder.decode(Command.self, from: data)

        #expect(decoded.id == command.id)
        #expect(decoded.name == command.name)
        #expect(decoded.prompt == command.prompt)
    }

    @Test func testCommandDefaultsExist() {
        let defaults = Command.defaults

        #expect(!defaults.isEmpty)
    }

    @Test func testCommandDefaultsContainExpectedCommands() {
        let defaults = Command.defaults
        let names = defaults.map(\.name)

        // Check for some expected default commands
        #expect(names.contains(where: { $0.contains("Grammar") || $0.contains("Correct") }))
        #expect(names.contains(where: { $0.contains("Rewrite") }))
        #expect(names.contains(where: { $0.contains("Simplify") }))
    }

    @Test func testCommandDefaultsAreSorted() {
        let defaults = Command.defaults
        let names = defaults.map(\.name)
        let sortedNames = names.sorted()

        #expect(names == sortedNames)
    }

    @Test func testCommandDefaultsHaveNonEmptyPrompts() {
        for command in Command.defaults {
            #expect(!command.prompt.isEmpty, "Command '\(command.name)' has empty prompt")
        }
    }

    @Test func testCommandDefaultsHaveNonEmptyNames() {
        for command in Command.defaults {
            #expect(!command.name.isEmpty, "Command has empty name")
        }
    }

    @Test func testCommandEncodeDecodeArray() throws {
        let commands = [
            Command(name: "Cmd 1", prompt: "Prompt 1"),
            Command(name: "Cmd 2", prompt: "Prompt 2"),
            Command(name: "Cmd 3", prompt: "Prompt 3")
        ]

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(commands)
        let decoded = try decoder.decode([Command].self, from: data)

        #expect(decoded.count == 3)
        for (original, decodedCmd) in zip(commands, decoded) {
            #expect(original.id == decodedCmd.id)
            #expect(original.name == decodedCmd.name)
            #expect(original.prompt == decodedCmd.prompt)
        }
    }
}

// MARK: - ReferencedURL Tests

struct ReferencedURLTests {

    @Test func testReferencedURLInit() {
        let url = URL(string: "https://example.com")!
        let referencedURL = ReferencedURL(url: url)

        #expect(referencedURL.url == url)
    }

    @Test func testReferencedURLDisplayNameWeb() {
        let url = URL(string: "https://example.com/path/to/page")!
        let referencedURL = ReferencedURL(url: url)

        #expect(referencedURL.displayName == "example.com")
    }

    @Test func testReferencedURLDisplayNameFile() {
        let url = URL(string: "file:///path/to/document.pdf")!
        let referencedURL = ReferencedURL(url: url)

        #expect(referencedURL.displayName == "document.pdf")
    }

    @Test func testReferencedURLEquatable() {
        let url1 = URL(string: "https://example.com")!
        let url2 = URL(string: "https://example.com")!
        let url3 = URL(string: "https://other.com")!

        let ref1 = ReferencedURL(url: url1)
        let ref2 = ReferencedURL(url: url2)
        let ref3 = ReferencedURL(url: url3)

        #expect(ref1 == ref2)
        #expect(ref1 != ref3)
    }

    @Test func testReferencedURLHashable() {
        let url = URL(string: "https://example.com")!
        let ref1 = ReferencedURL(url: url)
        let ref2 = ReferencedURL(url: url)

        var set = Set<ReferencedURL>()
        set.insert(ref1)
        set.insert(ref2)

        #expect(set.count == 1)
    }

    @Test func testReferencedURLEncodeDecode() throws {
        let url = URL(string: "https://example.com/test")!
        let referencedURL = ReferencedURL(url: url)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(referencedURL)
        let decoded = try decoder.decode(ReferencedURL.self, from: data)

        #expect(decoded.url == referencedURL.url)
    }

    @Test func testReferencedURLFromDataJSON() throws {
        let jsonString = """
        [{"url": "https://example.com"}, {"url": "https://test.org"}]
        """
        let data = jsonString.data(using: .utf8)!

        let result = ReferencedURL.fromData(data: data)

        #expect(result != nil)
        #expect(result?.count == 2)
    }

    @Test func testReferencedURLFromDataStringArray() throws {
        let jsonString = """
        ["https://example.com", "https://test.org"]
        """
        let data = jsonString.data(using: .utf8)!

        let result = ReferencedURL.fromData(data: data)

        #expect(result != nil)
        #expect(result?.count == 2)
    }

    @Test func testReferencedURLFromDataInvalidJSON() {
        let invalidData = "not valid json".data(using: .utf8)!

        let result = ReferencedURL.fromData(data: invalidData)

        #expect(result == nil)
    }

    @Test func testReferencedURLFromDataDeduplicates() throws {
        // Test with JSON object format which supports deduplication
        let jsonString = """
        [{"url": "https://example.com"}, {"url": "https://example.com"}, {"url": "https://test.org"}]
        """
        let data = jsonString.data(using: .utf8)!

        let result = ReferencedURL.fromData(data: data)

        #expect(result != nil)
        // Deduplication works on the URL objects
        #expect(result?.count == 2)
    }

    @Test func testReferencedURLFromDataSorted() throws {
        let jsonString = """
        ["https://zebra.com", "https://apple.com"]
        """
        let data = jsonString.data(using: .utf8)!

        let result = ReferencedURL.fromData(data: data)

        #expect(result != nil)
        #expect(result?.first?.displayName == "apple.com")
        #expect(result?.last?.displayName == "zebra.com")
    }
}

// MARK: - FunctionCallRecord Tests

struct FunctionCallRecordTests {

    @Test func testFunctionCallRecordInit() {
        let record = FunctionCallRecord(name: "myFunction")

        #expect(record.name == "myFunction")
        #expect(record.status == .executing)
        #expect(record.result == nil)
    }

    @Test func testFunctionCallRecordMarkAsFinishedSuccess() {
        var record = FunctionCallRecord(name: "testFunc")

        record.markAsFinished(status: .succeeded, result: "Success result")

        #expect(record.status == .succeeded)
        #expect(record.result == "Success result")
    }

    @Test func testFunctionCallRecordMarkAsFinishedFailure() {
        var record = FunctionCallRecord(name: "testFunc")

        record.markAsFinished(status: .failed, result: "Error message")

        #expect(record.status == .failed)
        #expect(record.result == "Error message")
    }

    @Test func testFunctionCallRecordStatusDidExecute() {
        #expect(FunctionCallRecord.Status.succeeded.didExecute == true)
        #expect(FunctionCallRecord.Status.failed.didExecute == true)
        #expect(FunctionCallRecord.Status.executing.didExecute == false)
    }

    @Test func testFunctionCallRecordStatusCaseIterable() {
        let allCases = FunctionCallRecord.Status.allCases

        #expect(allCases.count == 3)
        #expect(allCases.contains(.succeeded))
        #expect(allCases.contains(.failed))
        #expect(allCases.contains(.executing))
    }

    @Test func testFunctionCallRecordEquatable() {
        let record1 = FunctionCallRecord(name: "func1")
        var record2 = record1
        let record3 = FunctionCallRecord(name: "func1")

        #expect(record1 == record2)
        #expect(record1 != record3) // Different IDs

        record2.name = "modified"
        #expect(record1 != record2)
    }

    @Test func testFunctionCallRecordHashable() {
        let record1 = FunctionCallRecord(name: "func")
        let record2 = record1

        var set = Set<FunctionCallRecord>()
        set.insert(record1)
        set.insert(record2)

        #expect(set.count == 1)
    }

    @Test func testFunctionCallRecordEncodeDecode() throws {
        var record = FunctionCallRecord(name: "encodeTest")
        record.markAsFinished(status: .succeeded, result: "Done")

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(record)
        let decoded = try decoder.decode(FunctionCallRecord.self, from: data)

        #expect(decoded.id == record.id)
        #expect(decoded.name == record.name)
        #expect(decoded.status == record.status)
        #expect(decoded.result == record.result)
    }

    @Test func testFunctionCallRecordStatusEncodeDecode() throws {
        let statuses: [FunctionCallRecord.Status] = [.succeeded, .failed, .executing]

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for status in statuses {
            let data = try encoder.encode(status)
            let decoded = try decoder.decode(FunctionCallRecord.Status.self, from: data)
            #expect(decoded == status)
        }
    }
}

// MARK: - Snapshot Tests

struct SnapshotTests {

    @Test func testSnapshotInitDefault() {
        let snapshot = Snapshot()

        #expect(snapshot.text.isEmpty)
        #expect(snapshot.site == nil)
        #expect(snapshot.type == .text)
        #expect(snapshot.originalText == nil)
    }

    @Test func testSnapshotInitWithText() {
        let snapshot = Snapshot(text: "Some code")

        #expect(snapshot.text == "Some code")
        #expect(snapshot.type == .text)
    }

    @Test func testSnapshotTypeWithSite() {
        let site = Snapshot.Site(html: "<html></html>")
        let snapshot = Snapshot(site: site)

        #expect(snapshot.type == .site)
    }

    @Test func testSnapshotTextModificationTracksOriginal() {
        var snapshot = Snapshot(text: "Original text")

        #expect(snapshot.originalText == nil)

        snapshot.text = "Modified text"

        #expect(snapshot.originalText == "Original text")
        #expect(snapshot.text == "Modified text")
    }

    @Test func testSnapshotOriginalTextOnlySetOnce() {
        var snapshot = Snapshot(text: "First")

        snapshot.text = "Second"
        snapshot.text = "Third"

        #expect(snapshot.originalText == "First")
    }

    @Test func testSnapshotIdentifiable() {
        let snapshot1 = Snapshot(text: "Test 1")
        let snapshot2 = Snapshot(text: "Test 2")

        #expect(snapshot1.id != snapshot2.id)
    }

    @Test func testSnapshotEquatableById() {
        let snapshot1 = Snapshot(text: "Test")
        var snapshot2 = snapshot1
        let snapshot3 = Snapshot(text: "Test")

        #expect(snapshot1 == snapshot2)
        #expect(snapshot1 != snapshot3)

        // Modifying text shouldn't affect equality (based on id)
        snapshot2.text = "Modified"
        #expect(snapshot1 == snapshot2)
    }

    @Test func testSnapshotHashable() {
        let snapshot1 = Snapshot(text: "Test")
        let snapshot2 = snapshot1

        var set = Set<Snapshot>()
        set.insert(snapshot1)
        set.insert(snapshot2)

        #expect(set.count == 1)
    }

    @Test func testSnapshotEncodeDecode() throws {
        let snapshot = Snapshot(text: "Encode test")

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(snapshot)
        let decoded = try decoder.decode(Snapshot.self, from: data)

        #expect(decoded.id == snapshot.id)
        #expect(decoded.text == snapshot.text)
    }

    @Test func testSnapshotTypeRawValues() {
        // Access Snapshot.Type enum values via snapshot instance
        let snapshot = Snapshot(text: "test")
        #expect(snapshot.type.rawValue == "text")

        let site = Snapshot.Site(html: "<html></html>")
        let siteSnapshot = Snapshot(site: site)
        #expect(siteSnapshot.type.rawValue == "site")
    }

    @Test func testSnapshotTypeCaseIterable() {
        // Test that both type values exist by creating instances
        let textSnapshot = Snapshot(text: "text")
        let siteSnapshot = Snapshot(site: Snapshot.Site(html: "<html></html>"))

        // Verify the type enum has the expected values
        #expect(textSnapshot.type == .text)
        #expect(siteSnapshot.type == .site)
    }

    @Test func testSnapshotExtractCodeFromMarkdown() {
        let markdown = """
        Here is some code:

        ```swift
        func hello() {
            print("Hello, World!")
        }

        func goodbye() {
            print("Goodbye!")
        }
        ```
        """

        let snapshot = Snapshot.extractCode(from: markdown)

        #expect(snapshot != nil)
        #expect(snapshot?.text.contains("func hello()") == true)
    }

    @Test func testSnapshotExtractCodeNoCodeBlocks() {
        let markdown = "Just some plain text without code blocks."

        let snapshot = Snapshot.extractCode(from: markdown)

        #expect(snapshot == nil)
    }

    @Test func testSnapshotExtractCodeSingleLine() {
        let markdown = """
        ```swift
        print("one liner")
        ```
        """

        let snapshot = Snapshot.extractCode(from: markdown)

        // Single line should return nil (threshold is 1 line)
        #expect(snapshot == nil)
    }
}

// MARK: - Snapshot.Site Tests

struct SnapshotSiteTests {

    @Test func testSiteInit() {
        let site = Snapshot.Site(html: "<html></html>")

        #expect(site.html == "<html></html>")
        #expect(site.css == nil)
        #expect(site.js == nil)
    }

    @Test func testSiteInitWithAllComponents() {
        let site = Snapshot.Site(
            html: "<html></html>",
            css: "body { color: red; }",
            js: "console.log('hello');"
        )

        #expect(site.html == "<html></html>")
        #expect(site.css == "body { color: red; }")
        #expect(site.js == "console.log('hello');")
    }

    @Test func testSiteIdentifiable() {
        let site1 = Snapshot.Site(html: "<html>1</html>")
        let site2 = Snapshot.Site(html: "<html>2</html>")

        #expect(site1.id != site2.id)
    }

    @Test func testSiteHashable() {
        let site1 = Snapshot.Site(html: "<html></html>")
        let site2 = site1

        var set = Set<Snapshot.Site>()
        set.insert(site1)
        set.insert(site2)

        #expect(set.count == 1)
    }

    @Test func testSiteEncodeDecode() throws {
        let site = Snapshot.Site(
            html: "<html></html>",
            css: "body {}",
            js: "alert();"
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(site)
        let decoded = try decoder.decode(Snapshot.Site.self, from: data)

        #expect(decoded.id == site.id)
        #expect(decoded.html == site.html)
        #expect(decoded.css == site.css)
        #expect(decoded.js == site.js)
    }

    @Test func testSiteExtractFromMarkdownHTML() {
        let markdown = """
        Here's a website:

        ```html
        <html>
        <body>
            <h1>Hello</h1>
        </body>
        </html>
        ```
        """

        let site = Snapshot.Site.extractSite(from: markdown)

        #expect(site != nil)
        #expect(site?.html.contains("<h1>Hello</h1>") == true)
    }

    @Test func testSiteExtractFromMarkdownWithCSS() {
        let markdown = """
        ```html
        <html><body>Content</body></html>
        ```

        ```css
        body { margin: 0; }
        ```
        """

        let site = Snapshot.Site.extractSite(from: markdown)

        #expect(site != nil)
        #expect(site?.html != nil)
        #expect(site?.css?.contains("margin: 0") == true)
    }

    @Test func testSiteExtractFromMarkdownWithJS() {
        let markdown = """
        ```html
        <html><body>Content</body></html>
        ```

        ```javascript
        console.log("Hello");
        ```
        """

        let site = Snapshot.Site.extractSite(from: markdown)

        #expect(site != nil)
        #expect(site?.js?.contains("console.log") == true)
    }

    @Test func testSiteExtractFromMarkdownNoHTML() {
        let markdown = """
        Just CSS without HTML:

        ```css
        body { color: blue; }
        ```
        """

        let site = Snapshot.Site.extractSite(from: markdown)

        // HTML is required
        #expect(site == nil)
    }

    @Test func testSiteExtractFromMarkdownNoCodeBlocks() {
        let markdown = "Just plain text without any code blocks."

        let site = Snapshot.Site.extractSite(from: markdown)

        #expect(site == nil)
    }

    @Test func testSiteDirectoryUrlContainsId() {
        let site = Snapshot.Site(html: "<html></html>")

        #expect(site.directoryUrl.path.contains(site.id.uuidString))
    }

    @Test func testSiteUrlEndsWithIndexHtml() {
        let site = Snapshot.Site(html: "<html></html>")

        #expect(site.url.lastPathComponent == "index.html")
    }
}

// MARK: - Message.MessageSubset.Content Tests

struct MessageSubsetContentTests {

    @Test func testContentTextEncodeDecode() throws {
        let content = Message.MessageSubset.Content.text("Hello, world!")

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(content)
        let decoded = try decoder.decode(Message.MessageSubset.Content.self, from: data)

        if case .text(let text) = decoded {
            #expect(text == "Hello, world!")
        } else {
            Issue.record("Expected text content")
        }
    }

    @Test func testContentImageURLEncodeDecode() throws {
        let imageURL = Message.MessageSubset.ImageURL(url: "data:image/png;base64,abc123")
        let content = Message.MessageSubset.Content.imageURL(imageURL)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(content)
        let decoded = try decoder.decode(Message.MessageSubset.Content.self, from: data)

        if case .imageURL(let url) = decoded {
            #expect(url.url == "data:image/png;base64,abc123")
        } else {
            Issue.record("Expected imageURL content")
        }
    }
}

// MARK: - Message.MessageSubset.ContentValue Tests

struct MessageSubsetContentValueTests {

    @Test func testContentValueTextOnlyEncodeDecode() throws {
        let contentValue = Message.MessageSubset.ContentValue.textOnly("Simple text")

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(contentValue)
        let decoded = try decoder.decode(Message.MessageSubset.ContentValue.self, from: data)

        if case .textOnly(let text) = decoded {
            #expect(text == "Simple text")
        } else {
            Issue.record("Expected textOnly content value")
        }
    }

    @Test func testContentValueMultimodalEncodeDecode() throws {
        let contents: [Message.MessageSubset.Content] = [
            .text("Description"),
            .imageURL(Message.MessageSubset.ImageURL(url: "data:image/png;base64,xyz"))
        ]
        let contentValue = Message.MessageSubset.ContentValue.multimodal(contents)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(contentValue)
        let decoded = try decoder.decode(Message.MessageSubset.ContentValue.self, from: data)

        if case .multimodal(let decodedContents) = decoded {
            #expect(decodedContents.count == 2)
        } else {
            Issue.record("Expected multimodal content value")
        }
    }
}
