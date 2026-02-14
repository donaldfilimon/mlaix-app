//
//  KnowledgeGraphTests.swift
//  MLAIXTests
//
//  Tests for KnowledgeGraph: entity/relationship/community management and queries.
//

import Foundation
import Testing
@testable import MLAIX

struct KnowledgeGraphTests {

    // MARK: - Entity Management

    @Test func addAndFindEntityById() {
        let graph = KnowledgeGraph(resourceId: UUID())
        let entity = GraphEntity(
            name: "Alice",
            type: "Person",
            description: "A test person",
            sourceChunks: [0, 1]
        )
        graph.addEntity(entity)
        let found = graph.findEntity(id: entity.id)
        #expect(found != nil, "Should find entity by ID")
        #expect(found?.name == "Alice")
    }

    @Test func findEntityByName() {
        let graph = KnowledgeGraph(resourceId: UUID())
        let entity = GraphEntity(
            name: "Bob",
            type: "Person",
            description: "Another person"
        )
        graph.addEntity(entity)
        let found = graph.findEntity(name: "bob")
        #expect(found != nil, "Name search should be case-insensitive")
        #expect(found?.id == entity.id)
    }

    @Test func findEntityByNameNotFound() {
        let graph = KnowledgeGraph(resourceId: UUID())
        let result = graph.findEntity(name: "NonExistent")
        #expect(result == nil)
    }

    @Test func addMultipleEntities() {
        let graph = KnowledgeGraph(resourceId: UUID())
        let entities = (0..<5).map { i in
            GraphEntity(name: "Entity\(i)", type: "Test", description: "Desc \(i)")
        }
        graph.addEntities(entities)
        #expect(graph.entityCount == 5)
    }

    @Test func updateEntityReplacesOld() {
        let graph = KnowledgeGraph(resourceId: UUID())
        var entity = GraphEntity(
            name: "Original",
            type: "Test",
            description: "Original description",
            sourceChunks: [0]
        )
        graph.addEntity(entity)
        entity.description = "Updated description"
        entity.sourceChunks = [1, 2]
        graph.updateEntity(entity)

        let found = graph.findEntity(id: entity.id)
        #expect(found?.description == "Updated description")
        // Old chunk mapping should be removed
        #expect(graph.getEntities(inChunk: 0).isEmpty, "Old chunk mapping should be removed")
        // New chunk mappings should exist
        #expect(graph.getEntities(inChunk: 1).count == 1)
        #expect(graph.getEntities(inChunk: 2).count == 1)
    }

    // MARK: - Relationship Management

    @Test func addRelationshipBetweenExistingEntities() {
        let graph = KnowledgeGraph(resourceId: UUID())
        let alice = GraphEntity(name: "Alice", type: "Person", description: "Person A")
        let bob = GraphEntity(name: "Bob", type: "Person", description: "Person B")
        graph.addEntities([alice, bob])

        let rel = GraphRelationship(
            sourceEntityId: alice.id,
            targetEntityId: bob.id,
            relationshipType: "KNOWS",
            description: "Alice knows Bob",
            strength: 0.8
        )
        graph.addRelationship(rel)
        #expect(graph.relationshipCount == 1)
    }

    @Test func addRelationshipWithMissingEntityIsIgnored() {
        let graph = KnowledgeGraph(resourceId: UUID())
        let alice = GraphEntity(name: "Alice", type: "Person", description: "Person A")
        graph.addEntity(alice)

        let rel = GraphRelationship(
            sourceEntityId: alice.id,
            targetEntityId: UUID(), // non-existent
            relationshipType: "KNOWS",
            description: "Alice knows nobody",
            strength: 0.5
        )
        graph.addRelationship(rel)
        #expect(graph.relationshipCount == 0, "Should not add relationship with missing target entity")
    }

    @Test func getRelationshipsForEntity() {
        let graph = KnowledgeGraph(resourceId: UUID())
        let a = GraphEntity(name: "A", type: "T", description: "")
        let b = GraphEntity(name: "B", type: "T", description: "")
        let c = GraphEntity(name: "C", type: "T", description: "")
        graph.addEntities([a, b, c])

        graph.addRelationship(GraphRelationship(sourceEntityId: a.id, targetEntityId: b.id, relationshipType: "R", description: "", strength: 1))
        graph.addRelationship(GraphRelationship(sourceEntityId: c.id, targetEntityId: a.id, relationshipType: "R", description: "", strength: 1))
        graph.addRelationship(GraphRelationship(sourceEntityId: b.id, targetEntityId: c.id, relationshipType: "R", description: "", strength: 1))

        let aRels = graph.getRelationships(for: a.id)
        #expect(aRels.count == 2, "A should have 2 relationships (as source and target)")
    }

    @Test func getRelatedEntities() {
        let graph = KnowledgeGraph(resourceId: UUID())
        let a = GraphEntity(name: "A", type: "T", description: "")
        let b = GraphEntity(name: "B", type: "T", description: "")
        let c = GraphEntity(name: "C", type: "T", description: "")
        graph.addEntities([a, b, c])

        graph.addRelationship(GraphRelationship(sourceEntityId: a.id, targetEntityId: b.id, relationshipType: "R", description: "", strength: 1))
        graph.addRelationship(GraphRelationship(sourceEntityId: a.id, targetEntityId: c.id, relationshipType: "R", description: "", strength: 1))

        let related = graph.getRelatedEntities(for: a.id)
        let relatedNames = Set(related.map(\.name))
        #expect(relatedNames == ["B", "C"])
    }

    // MARK: - Community Management

    @Test func addAndQueryCommunities() {
        let graph = KnowledgeGraph(resourceId: UUID())
        let a = GraphEntity(name: "A", type: "T", description: "")
        let b = GraphEntity(name: "B", type: "T", description: "")
        graph.addEntities([a, b])

        let community = Community(
            level: 0,
            memberEntityIds: [a.id, b.id],
            subCommunityIds: []
        )
        graph.addCommunity(community)
        #expect(graph.communityCount == 1)

        let level0 = graph.getCommunities(at: 0)
        #expect(level0.count == 1)
        let level1 = graph.getCommunities(at: 1)
        #expect(level1.isEmpty)
    }

    // MARK: - Chunk Queries

    @Test func chunkToEntityMapping() {
        let graph = KnowledgeGraph(resourceId: UUID())
        let e1 = GraphEntity(name: "E1", type: "T", description: "", sourceChunks: [0, 1])
        let e2 = GraphEntity(name: "E2", type: "T", description: "", sourceChunks: [1, 2])
        graph.addEntities([e1, e2])

        let chunk0 = graph.getEntities(inChunk: 0)
        #expect(chunk0.count == 1, "Chunk 0 should have 1 entity")
        #expect(chunk0.first?.name == "E1")

        let chunk1 = graph.getEntities(inChunk: 1)
        #expect(chunk1.count == 2, "Chunk 1 should have 2 entities")

        let multiChunk = graph.getEntities(inChunks: [0, 2])
        #expect(multiChunk.count == 2, "Chunks 0+2 should yield 2 unique entities")
    }

    @Test func emptyChunkReturnsEmpty() {
        let graph = KnowledgeGraph(resourceId: UUID())
        let result = graph.getEntities(inChunk: 99)
        #expect(result.isEmpty)
    }

    // MARK: - Graph Statistics

    @Test func statisticsReflectState() {
        let graph = KnowledgeGraph(resourceId: UUID())
        let a = GraphEntity(name: "A", type: "T", description: "", sourceChunks: [0])
        let b = GraphEntity(name: "B", type: "T", description: "", sourceChunks: [1])
        graph.addEntities([a, b])
        graph.addRelationship(GraphRelationship(sourceEntityId: a.id, targetEntityId: b.id, relationshipType: "R", description: "", strength: 1))
        graph.addCommunity(Community(level: 0, memberEntityIds: [a.id, b.id], subCommunityIds: []))

        let stats = graph.getStatistics()
        #expect(stats["entities"] == 2)
        #expect(stats["relationships"] == 1)
        #expect(stats["communities"] == 1)
        #expect(stats["chunks_with_entities"] == 2)
    }

    // MARK: - Merge

    @Test func mergeGraphsCombinesData() {
        let graph1 = KnowledgeGraph(resourceId: UUID())
        let a = GraphEntity(name: "A", type: "T", description: "")
        graph1.addEntity(a)

        let graph2 = KnowledgeGraph(resourceId: UUID())
        let b = GraphEntity(name: "B", type: "T", description: "")
        graph2.addEntity(b)

        graph1.merge(graph2)
        #expect(graph1.entityCount == 2)
        #expect(graph1.findEntity(name: "B") != nil, "Merged entity should be findable")
    }

    // MARK: - Codable Round-Trip

    @Test func codableRoundTrip() throws {
        let graph = KnowledgeGraph(resourceId: UUID())
        let a = GraphEntity(name: "A", type: "Person", description: "Test A", sourceChunks: [0, 1])
        let b = GraphEntity(name: "B", type: "Place", description: "Test B", sourceChunks: [2])
        graph.addEntities([a, b])
        graph.addRelationship(GraphRelationship(sourceEntityId: a.id, targetEntityId: b.id, relationshipType: "LOCATED_IN", description: "A is in B", strength: 0.9))
        graph.addCommunity(Community(level: 0, memberEntityIds: [a.id, b.id], subCommunityIds: []))

        let data = try JSONEncoder().encode(graph)
        let decoded = try JSONDecoder().decode(KnowledgeGraph.self, from: data)

        #expect(decoded.entityCount == 2)
        #expect(decoded.relationshipCount == 1)
        #expect(decoded.communityCount == 1)
        #expect(decoded.resourceId == graph.resourceId)
        #expect(decoded.findEntity(name: "A")?.type == "Person")
    }

    // MARK: - Sendable

    @Test func knowledgeGraphIsSendable() async {
        let graph = KnowledgeGraph(resourceId: UUID())
        let entity = GraphEntity(name: "Test", type: "T", description: "")
        graph.addEntity(entity)

        let result = await Task.detached {
            graph.entityCount
        }.value
        #expect(result == 1, "KnowledgeGraph should be safely accessible from another task")
    }
}
