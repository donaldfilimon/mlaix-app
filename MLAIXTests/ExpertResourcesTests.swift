//
//  ExpertResourcesTests.swift
//  MLAITests
//
//  Tests for Expert, Resource, GraphEntity, GraphRelationship, and Community types.
//

import Foundation
import Testing

@testable import MLAIX

// MARK: - Expert Tests

struct ExpertTests {

    @Test func testDefaultExpertHasExpectedProperties() {
        let expert = Expert.default
        #expect(expert.name == String(localized: "Default"))
        #expect(expert.symbolName == "person.fill")
        #expect(expert.useWebSearch == false)
        #expect(expert.persistResources == false)
        #expect(expert.isDefault == true)
        #expect(expert.systemPrompt == nil)
    }

    @Test func testCustomExpertIsNotDefault() {
        let expert = Expert(
            name: "Science",
            symbolName: "atom",
            color: .green
        )
        #expect(expert.isDefault == false)
        #expect(expert.name == "Science")
    }

    @Test func testExpertDefaultsForOptionalProperties() {
        let expert = Expert(
            name: "Test",
            symbolName: "star",
            color: .red
        )
        #expect(expert.useWebSearch == true)
        #expect(expert.persistResources == true)
        #expect(expert.systemPrompt == nil)
        #expect(expert.resources.resources.isEmpty)
    }

    @Test func testExpertEqualityById() {
        var a = Expert(name: "A", symbolName: "star", color: .red)
        var b = Expert(name: "B", symbolName: "moon", color: .blue)
        #expect(a != b)

        // Same id makes them equal regardless of other properties
        b.id = a.id
        #expect(a == b)
    }

    @Test func testUseGraphRAGDelegatesToResources() {
        var expert = Expert(name: "Test", symbolName: "star", color: .red)
        #expect(expert.useGraphRAG == false)

        expert.useGraphRAG = true
        #expect(expert.useGraphRAG == true)
        #expect(expert.resources.useGraphRAG == true)
    }
}

// MARK: - Resource Tests

struct ResourceTests {

    @Test func testFileResourceProperties() {
        let url = URL(fileURLWithPath: "/tmp/test.pdf")
        let resource = Resource(url: url)
        #expect(resource.isWebResource == false)
        #expect(resource.name == "test.pdf")
        #expect(resource.filename == "test.pdf")
    }

    @Test func testWebResourceProperties() {
        let url = URL(string: "https://example.com/page")!
        let resource = Resource(url: url)
        #expect(resource.isWebResource == true)
        #expect(resource.name == "https://example.com/page")
        #expect(resource.filename == "example.com")
    }

    @Test func testLeafNodeForFile() {
        let url = URL(fileURLWithPath: "/tmp/test.txt")
        let resource = Resource(url: url)
        // A file with no children is a leaf node
        #expect(resource.isLeafNode == true)
    }

    @Test func testLeafNodeForDirectory() {
        let url = URL(fileURLWithPath: "/tmp/testdir/", isDirectory: true)
        let resource = Resource(url: url)
        // A directory path is never a leaf node, even with no children
        #expect(resource.isLeafNode == false)
    }

    @Test func testLeafNodeWithChildren() {
        let url = URL(fileURLWithPath: "/tmp/test.txt")
        var resource = Resource(url: url)
        resource.children = [Resource(url: URL(fileURLWithPath: "/tmp/child.txt"))]
        // Has children -> not a leaf
        #expect(resource.isLeafNode == false)
    }

    @Test func testScannedSinceLastModifiedDefaultIsFalse() {
        let url = URL(fileURLWithPath: "/tmp/test.txt")
        let resource = Resource(url: url)
        // prevIndexDate defaults to .distantPast, so should not be scanned
        #expect(resource.prevIndexDate == .distantPast)
    }

    @Test func testIndexStateTransitions() {
        var state = Resource.IndexState.noIndex
        #expect(state == .noIndex)

        state.startIndex()
        #expect(state == .indexing)

        state.finishIndex()
        #expect(state == .indexed)
    }

    @Test func testProgressUpdateInit() {
        let progress = Resource.ProgressUpdate(
            current: 5,
            total: 10,
            stage: "Indexing",
            entities: 3,
            fractionComplete: 0.5
        )
        #expect(progress.current == 5)
        #expect(progress.total == 10)
        #expect(progress.stage == "Indexing")
        #expect(progress.entities == 3)
        #expect(progress.fractionComplete == 0.5)
    }

    @Test func testProgressUpdateDefaultEntities() {
        let progress = Resource.ProgressUpdate(
            current: 1,
            total: 1,
            stage: "Done",
            fractionComplete: 1.0
        )
        #expect(progress.entities == 0)
    }
}

// MARK: - GraphEntity Tests

struct GraphEntityTests {

    @Test func testBasicInit() {
        let entity = GraphEntity(
            name: "Swift",
            type: "Language",
            description: "A programming language"
        )
        #expect(entity.name == "Swift")
        #expect(entity.type == "Language")
        #expect(entity.description == "A programming language")
        #expect(entity.sourceChunks.isEmpty)
        #expect(entity.embedding == nil)
    }

    @Test func testInitWithAllParameters() {
        let id = UUID()
        let entity = GraphEntity(
            id: id,
            name: "Apple",
            type: "Organization",
            description: "A tech company",
            sourceChunks: [0, 2, 5],
            embedding: [0.1, 0.2, 0.3]
        )
        #expect(entity.id == id)
        #expect(entity.sourceChunks == [0, 2, 5])
        #expect(entity.embedding == [0.1, 0.2, 0.3])
    }

    @Test func testEqualityById() {
        let id = UUID()
        let a = GraphEntity(id: id, name: "A", type: "T", description: "D1")
        let b = GraphEntity(id: id, name: "B", type: "T", description: "D2")
        // Same id -> equal, despite different names
        #expect(a == b)
    }

    @Test func testInequalityByDifferentId() {
        let a = GraphEntity(name: "Same", type: "T", description: "D")
        let b = GraphEntity(name: "Same", type: "T", description: "D")
        // Different auto-generated ids -> not equal
        #expect(a != b)
    }

    @Test func testHashConsistency() {
        let id = UUID()
        let a = GraphEntity(id: id, name: "A", type: "T", description: "D")
        let b = GraphEntity(id: id, name: "B", type: "T", description: "D")
        #expect(a.hashValue == b.hashValue)
    }

    @Test func testCodableRoundtrip() throws {
        let entity = GraphEntity(
            name: "Test",
            type: "Concept",
            description: "A test entity",
            sourceChunks: [1, 3],
            embedding: [0.5, 0.6]
        )
        let data = try JSONEncoder().encode(entity)
        let decoded = try JSONDecoder().decode(GraphEntity.self, from: data)
        #expect(decoded.id == entity.id)
        #expect(decoded.name == entity.name)
        #expect(decoded.sourceChunks == entity.sourceChunks)
        #expect(decoded.embedding == entity.embedding)
    }
}

// MARK: - GraphRelationship Tests

struct GraphRelationshipTests {

    @Test func testBasicInit() {
        let srcId = UUID()
        let tgtId = UUID()
        let rel = GraphRelationship(
            sourceEntityId: srcId,
            targetEntityId: tgtId,
            relationshipType: "works_at",
            description: "Employee works at company"
        )
        #expect(rel.sourceEntityId == srcId)
        #expect(rel.targetEntityId == tgtId)
        #expect(rel.relationshipType == "works_at")
        #expect(rel.strength == 1.0) // default
        #expect(rel.sourceChunks.isEmpty)
    }

    @Test func testStrengthClampedToUpperBound() {
        let rel = GraphRelationship(
            sourceEntityId: UUID(),
            targetEntityId: UUID(),
            relationshipType: "test",
            description: "test",
            strength: 5.0
        )
        #expect(rel.strength == 1.0)
    }

    @Test func testStrengthClampedToLowerBound() {
        let rel = GraphRelationship(
            sourceEntityId: UUID(),
            targetEntityId: UUID(),
            relationshipType: "test",
            description: "test",
            strength: -2.0
        )
        #expect(rel.strength == 0.0)
    }

    @Test func testStrengthMidRange() {
        let rel = GraphRelationship(
            sourceEntityId: UUID(),
            targetEntityId: UUID(),
            relationshipType: "test",
            description: "test",
            strength: 0.75
        )
        #expect(rel.strength == 0.75)
    }

    @Test func testStrengthBoundaryValues() {
        let atZero = GraphRelationship(
            sourceEntityId: UUID(), targetEntityId: UUID(),
            relationshipType: "t", description: "d", strength: 0.0
        )
        let atOne = GraphRelationship(
            sourceEntityId: UUID(), targetEntityId: UUID(),
            relationshipType: "t", description: "d", strength: 1.0
        )
        #expect(atZero.strength == 0.0)
        #expect(atOne.strength == 1.0)
    }

    @Test func testEqualityById() {
        let id = UUID()
        let a = GraphRelationship(
            id: id, sourceEntityId: UUID(), targetEntityId: UUID(),
            relationshipType: "a", description: "a"
        )
        let b = GraphRelationship(
            id: id, sourceEntityId: UUID(), targetEntityId: UUID(),
            relationshipType: "b", description: "b"
        )
        #expect(a == b)
    }

    @Test func testCodableRoundtrip() throws {
        let rel = GraphRelationship(
            sourceEntityId: UUID(),
            targetEntityId: UUID(),
            relationshipType: "related_to",
            description: "General relation",
            strength: 0.42,
            sourceChunks: [0, 1]
        )
        let data = try JSONEncoder().encode(rel)
        let decoded = try JSONDecoder().decode(GraphRelationship.self, from: data)
        #expect(decoded.id == rel.id)
        #expect(decoded.strength == rel.strength)
        #expect(decoded.sourceChunks == rel.sourceChunks)
    }
}

// MARK: - Community Tests

struct CommunityTests {

    @Test func testBasicInit() {
        let community = Community(level: 0)
        #expect(community.level == 0)
        #expect(community.memberEntityIds.isEmpty)
        #expect(community.subCommunityIds.isEmpty)
        #expect(community.summary == "")
        #expect(community.embedding == nil)
        #expect(community.title == "Untitled Community")
    }

    @Test func testLevelClampedToNonNegative() {
        let community = Community(level: -5)
        #expect(community.level == 0)
    }

    @Test func testLevelZeroUnchanged() {
        let community = Community(level: 0)
        #expect(community.level == 0)
    }

    @Test func testPositiveLevelPreserved() {
        let community = Community(level: 3)
        #expect(community.level == 3)
    }

    @Test func testInitWithAllParameters() {
        let id = UUID()
        let entityIds = [UUID(), UUID()]
        let subIds = [UUID()]
        let community = Community(
            id: id,
            level: 2,
            memberEntityIds: entityIds,
            subCommunityIds: subIds,
            summary: "A test community",
            embedding: [0.1, 0.2],
            title: "Test Group"
        )
        #expect(community.id == id)
        #expect(community.level == 2)
        #expect(community.memberEntityIds.count == 2)
        #expect(community.subCommunityIds.count == 1)
        #expect(community.summary == "A test community")
        #expect(community.title == "Test Group")
    }

    @Test func testEqualityById() {
        let id = UUID()
        let a = Community(id: id, level: 0, summary: "A")
        let b = Community(id: id, level: 1, summary: "B")
        #expect(a == b)
    }

    @Test func testHashConsistency() {
        let id = UUID()
        let a = Community(id: id, level: 0)
        let b = Community(id: id, level: 5, title: "Different")
        #expect(a.hashValue == b.hashValue)
    }

    @Test func testCodableRoundtrip() throws {
        let community = Community(
            level: 1,
            memberEntityIds: [UUID(), UUID()],
            summary: "Science topics",
            title: "Science"
        )
        let data = try JSONEncoder().encode(community)
        let decoded = try JSONDecoder().decode(Community.self, from: data)
        #expect(decoded.id == community.id)
        #expect(decoded.level == community.level)
        #expect(decoded.memberEntityIds == community.memberEntityIds)
        #expect(decoded.title == community.title)
    }
}

// MARK: - Resources Container Tests

struct ResourcesContainerTests {

    @Test func testDefaultResourcesAreEmpty() {
        let resources = Resources()
        #expect(resources.resources.isEmpty)
        #expect(resources.status == nil)
        #expect(resources.useGraphRAG == false)
        #expect(resources.graphStatus == nil)
    }

    @Test func testResourcesStatusEnum() {
        let allCases = Resources.Status.allCases
        #expect(allCases.contains(.indexing))
        #expect(allCases.contains(.ready))
        #expect(allCases.count == 2)
    }

    @Test func testGraphStatusEnum() {
        let allCases = Resources.GraphStatus.allCases
        #expect(allCases.contains(.building))
        #expect(allCases.contains(.ready))
        #expect(allCases.contains(.error))
        #expect(allCases.count == 3)
    }
}
