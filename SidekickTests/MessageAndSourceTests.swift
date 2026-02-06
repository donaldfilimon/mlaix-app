//
//  MessageAndSourceTests.swift
//  MLAITests
//
//  Tests for SearchResult, Source, Sources, and related types.
//

import Foundation
import Testing

@testable import MLAI

// MARK: - Source Tests

struct SourceTests {

    @Test func testSourceInit() {
        let source = Source(text: "Some content", source: "https://example.com")
        #expect(source.text == "Some content")
        #expect(source.source == "https://example.com")
    }

    @Test func testSourceInfoComputed() {
        let source = Source(text: "Content here", source: "https://example.com/page")
        let info = source.info
        #expect(info.url == "https://example.com/page")
        #expect(info.text == "Content here")
    }

    @Test func testSourceEqualityByAllFields() {
        var a = Source(text: "A", source: "https://a.com")
        var b = Source(text: "B", source: "https://b.com")
        #expect(a != b)

        // Source uses synthesized Equatable (all fields must match)
        b.id = a.id
        b.text = a.text
        b.source = a.source
        #expect(a == b)
    }

    @Test func testSourceHashable() {
        let source = Source(text: "text", source: "url")
        var set: Set<Source> = []
        set.insert(source)
        set.insert(source) // duplicate
        #expect(set.count == 1)
    }

    @Test func testSourceCodableRoundtrip() throws {
        let original = Source(text: "Hello", source: "https://example.com")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Source.self, from: data)
        #expect(decoded.id == original.id)
        #expect(decoded.text == original.text)
        #expect(decoded.source == original.source)
    }
}

// MARK: - SourceInfo Tests

struct SourceInfoTests {

    @Test func testSourceInfoInit() {
        let info = Source.SourceInfo(url: "https://test.com", text: "Info text")
        #expect(info.url == "https://test.com")
        #expect(info.text == "Info text")
    }

    @Test func testSourceInfoCodableRoundtrip() throws {
        let original = Source.SourceInfo(url: "https://a.com", text: "content")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Source.SourceInfo.self, from: data)
        #expect(decoded.url == original.url)
        #expect(decoded.text == original.text)
    }
}

// MARK: - SourceContent Tests

struct SourceContentTests {

    @Test func testSourceContentInit() {
        let content = Source.SourceContent(url: "https://test.com", content: "<html>hi</html>")
        #expect(content.url == "https://test.com")
        #expect(content.content == "<html>hi</html>")
    }

    @Test func testSourceContentCodableRoundtrip() throws {
        let original = Source.SourceContent(url: "https://b.com", content: "page body")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Source.SourceContent.self, from: data)
        #expect(decoded.url == original.url)
        #expect(decoded.content == original.content)
    }
}

// MARK: - Sources Container Tests

struct SourcesContainerTests {

    @Test func testSourcesInit() {
        let msgId = UUID()
        let sources = Sources(
            messageId: msgId,
            sources: [
                Source(text: "A", source: "https://a.com"),
                Source(text: "B", source: "https://b.com"),
            ]
        )
        #expect(sources.messageId == msgId)
        #expect(sources.sources.count == 2)
    }

    @Test func testSourcesCodableRoundtrip() throws {
        let original = Sources(
            messageId: UUID(),
            sources: [Source(text: "text", source: "src")]
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Sources.self, from: data)
        #expect(decoded.id == original.id)
        #expect(decoded.messageId == original.messageId)
        #expect(decoded.sources.count == 1)
        #expect(decoded.sources.first?.text == "text")
    }

    @Test func testEmptySources() {
        let sources = Sources(messageId: UUID(), sources: [])
        #expect(sources.sources.isEmpty)
    }

    @Test func testSourcesHashable() {
        let sources = Sources(messageId: UUID(), sources: [])
        var set: Set<Sources> = []
        set.insert(sources)
        set.insert(sources)
        #expect(set.count == 1)
    }
}

// MARK: - SearchResult Tests (via Codable)

struct SearchResultTests {

    /// Helper to create a SearchResult via JSON since the init requires SimilaritySearchKit types
    private static func makeSearchResult(
        text: String,
        score: Float,
        metadata: [String: String]
    ) throws -> SearchResult {
        let id = UUID()
        let json: [String: Any] = [
            "id": id.uuidString,
            "text": text,
            "score": score,
            "metadata": metadata,
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        return try JSONDecoder().decode(SearchResult.self, from: data)
    }

    @Test func testItemIndexFromMetadata() throws {
        let result = try Self.makeSearchResult(
            text: "chunk content",
            score: 0.95,
            metadata: ["itemIndex": "3", "source": "/tmp/file.txt"]
        )
        #expect(result.itemIndex == 3)
    }

    @Test func testItemIndexMissing() throws {
        let result = try Self.makeSearchResult(
            text: "content",
            score: 0.5,
            metadata: ["source": "/tmp/file.txt"]
        )
        #expect(result.itemIndex == nil)
    }

    @Test func testItemIndexNonNumeric() throws {
        let result = try Self.makeSearchResult(
            text: "content",
            score: 0.5,
            metadata: ["itemIndex": "abc"]
        )
        #expect(result.itemIndex == nil)
    }

    @Test func testSourceUrlFromMetadata() throws {
        let result = try Self.makeSearchResult(
            text: "content",
            score: 0.8,
            metadata: ["source": "https://example.com/page"]
        )
        #expect(result.sourceUrl != nil)
        #expect(result.sourceUrl?.absoluteString == "https://example.com/page")
    }

    @Test func testSourceUrlMissing() throws {
        let result = try Self.makeSearchResult(
            text: "content",
            score: 0.8,
            metadata: [:]
        )
        #expect(result.sourceUrl == nil)
    }

    @Test func testSourceUrlTextForWebUrl() throws {
        let result = try Self.makeSearchResult(
            text: "content",
            score: 0.9,
            metadata: ["source": "https://example.com/page"]
        )
        #expect(result.sourceUrlText == "https://example.com/page")
    }

    @Test func testSourceUrlTextForFileUrl() throws {
        let result = try Self.makeSearchResult(
            text: "content",
            score: 0.9,
            metadata: ["source": "/tmp/test.txt"]
        )
        // File URLs return posixPath
        #expect(result.sourceUrlText != nil)
    }

    @Test func testCodableRoundtrip() throws {
        let original = try Self.makeSearchResult(
            text: "test text",
            score: 0.75,
            metadata: ["itemIndex": "1", "source": "https://test.com"]
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SearchResult.self, from: data)
        #expect(decoded.id == original.id)
        #expect(decoded.text == original.text)
        #expect(decoded.score == original.score)
        #expect(decoded.itemIndex == original.itemIndex)
    }
}
