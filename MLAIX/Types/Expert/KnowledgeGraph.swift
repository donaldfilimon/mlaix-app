//
//  KnowledgeGraph.swift
//  MLAI
//
//  Created by John Bean on 11/10/25.
//

import Foundation
import SQLite
import OSLog
import Synchronization

/// A knowledge graph containing entities, relationships, and hierarchical communities
public final class KnowledgeGraph: Codable, Sendable {
	
	/// A `Logger` object for ``KnowledgeGraph`` objects
	private static let logger: Logger = .init(
		subsystem: Bundle.main.logSubsystem,
		category: String(describing: KnowledgeGraph.self)
	)
	
	/// Internal mutable state protected by Mutex
	private struct GraphState {
		var entitiesDict: [UUID: GraphEntity] = [:]
		var relationships: [GraphRelationship] = []
		var communities: [Community] = []
		var chunkToEntities: [Int: Set<UUID>] = [:]
	}
	private let state: Mutex<GraphState>
	
	/// The resource ID this graph belongs to
	public let resourceId: UUID
	
	// MARK: - Computed Properties
	
	/// Computed property returning all entities as an array
	public var entities: [GraphEntity] {
		state.withLock { Array($0.entitiesDict.values) }
	}
	
	/// Computed property returning entity count
	public var entityCount: Int {
		state.withLock { $0.entitiesDict.count }
	}
	
	/// Computed property returning all relationships
	public var relationships: [GraphRelationship] {
		state.withLock { $0.relationships }
	}
	
	/// Computed property returning relationship count
	public var relationshipCount: Int {
		state.withLock { $0.relationships.count }
	}
	
	/// Computed property returning all communities
	public var communities: [Community] {
		state.withLock { $0.communities }
	}
	
	/// Computed property returning community count
	public var communityCount: Int {
		state.withLock { $0.communities.count }
	}
	
	/// Computed property returning chunk-to-entity mapping
	public var chunkToEntities: [Int: Set<UUID>] {
		state.withLock { $0.chunkToEntities }
	}
	
	// MARK: - Initialization
	
	init(resourceId: UUID) {
		self.resourceId = resourceId
		self.state = Mutex(GraphState())
	}
	
	// MARK: - Entity Management
	
	/// Add an entity to the graph
	/// - Parameter entity: The entity to add
	public func addEntity(_ entity: GraphEntity) {
		state.withLock { s in
			s.entitiesDict[entity.id] = entity
			// Update chunk mappings
			for chunkIndex in entity.sourceChunks {
				if s.chunkToEntities[chunkIndex] == nil {
					s.chunkToEntities[chunkIndex] = Set()
				}
				s.chunkToEntities[chunkIndex]?.insert(entity.id)
			}
		}
	}
	
	/// Add multiple entities to the graph
	/// - Parameter entities: The entities to add
	public func addEntities(_ entities: [GraphEntity]) {
		for entity in entities {
			addEntity(entity)
		}
	}
	
	/// Find an entity by ID
	/// - Parameter id: The entity ID
	/// - Returns: The entity if found
	public func findEntity(id: UUID) -> GraphEntity? {
		state.withLock { $0.entitiesDict[id] }
	}
	
	/// Find an entity by name
	/// - Parameter name: The entity name
	/// - Returns: The entity if found
	public func findEntity(name: String) -> GraphEntity? {
		state.withLock { s in
			s.entitiesDict.values.first { $0.name.lowercased() == name.lowercased() }
		}
	}
	
	/// Update an existing entity
	/// - Parameter entity: The updated entity
	public func updateEntity(_ entity: GraphEntity) {
		state.withLock { s in
			// Remove old chunk mappings
			if let oldEntity = s.entitiesDict[entity.id] {
				for chunkIndex in oldEntity.sourceChunks {
					s.chunkToEntities[chunkIndex]?.remove(entity.id)
				}
			}
			// Add entity with new mappings
			s.entitiesDict[entity.id] = entity
			for chunkIndex in entity.sourceChunks {
				if s.chunkToEntities[chunkIndex] == nil {
					s.chunkToEntities[chunkIndex] = Set()
				}
				s.chunkToEntities[chunkIndex]?.insert(entity.id)
			}
		}
	}
	
	// MARK: - Relationship Management
	
	/// Add a relationship to the graph
	/// - Parameter relationship: The relationship to add
	public func addRelationship(_ relationship: GraphRelationship) {
		state.withLock { s in
			// Validate that both entities exist
			guard s.entitiesDict[relationship.sourceEntityId] != nil,
				  s.entitiesDict[relationship.targetEntityId] != nil else {
				Self.logger.warning("Attempted to add relationship with non-existent entities")
				return
			}
			s.relationships.append(relationship)
		}
	}
	
	/// Add multiple relationships to the graph
	/// - Parameter relationships: The relationships to add
	public func addRelationships(_ relationships: [GraphRelationship]) {
		for relationship in relationships {
			addRelationship(relationship)
		}
	}
	
	/// Get all relationships for a given entity
	/// - Parameter entityId: The entity ID
	/// - Returns: Array of relationships where the entity is source or target
	public func getRelationships(for entityId: UUID) -> [GraphRelationship] {
		state.withLock { s in
			s.relationships.filter {
				$0.sourceEntityId == entityId || $0.targetEntityId == entityId
			}
		}
	}
	
	/// Get related entities for a given entity (entities connected by relationships)
	/// - Parameter entityId: The entity ID
	/// - Returns: Array of related entities
	public func getRelatedEntities(for entityId: UUID) -> [GraphEntity] {
		state.withLock { s in
			let relatedIds = s.relationships.filter {
				$0.sourceEntityId == entityId || $0.targetEntityId == entityId
			}.flatMap { rel in
				[rel.sourceEntityId, rel.targetEntityId]
			}.filter { $0 != entityId }
			
			return relatedIds.compactMap { s.entitiesDict[$0] }
		}
	}
	
	// MARK: - Community Management
	
	/// Add a community to the graph
	/// - Parameter community: The community to add
	public func addCommunity(_ community: Community) {
		state.withLock { $0.communities.append(community) }
	}
	
	/// Add multiple communities to the graph
	/// - Parameter communities: The communities to add
	public func addCommunities(_ communities: [Community]) {
		state.withLock { $0.communities.append(contentsOf: communities) }
	}
	
	/// Get all communities at a specific level
	/// - Parameter level: The hierarchical level
	/// - Returns: Array of communities at that level
	public func getCommunities(at level: Int) -> [Community] {
		state.withLock { $0.communities.filter { $0.level == level } }
	}
	
	// MARK: - Chunk Queries
	
	/// Get all entities that appear in a specific chunk
	/// - Parameter chunkIndex: The chunk index
	/// - Returns: Array of entities in that chunk
	public func getEntities(inChunk chunkIndex: Int) -> [GraphEntity] {
		state.withLock { s in
			guard let entityIds = s.chunkToEntities[chunkIndex] else {
				return []
			}
			return entityIds.compactMap { s.entitiesDict[$0] }
		}
	}
	
	/// Get all entities that appear in any of the given chunks
	/// - Parameter chunkIndices: The chunk indices
	/// - Returns: Array of unique entities
	public func getEntities(inChunks chunkIndices: [Int]) -> [GraphEntity] {
		state.withLock { s in
			var entityIds = Set<UUID>()
			for chunkIndex in chunkIndices {
				if let ids = s.chunkToEntities[chunkIndex] {
					entityIds.formUnion(ids)
				}
			}
			return entityIds.compactMap { s.entitiesDict[$0] }
		}
	}
	
	// MARK: - Graph Statistics
	
	/// Get statistics about the graph
	/// - Returns: Dictionary with statistics
	public func getStatistics() -> [String: Int] {
		state.withLock { s in
			[
				"entities": s.entitiesDict.count,
				"relationships": s.relationships.count,
				"communities": s.communities.count,
				"chunks_with_entities": s.chunkToEntities.count
			]
		}
	}
	
	// MARK: - Merge
	
	/// Merge another knowledge graph into this one
	/// - Parameter other: The graph to merge
	public func merge(_ other: KnowledgeGraph) {
		// Merge entities
		for entity in other.entities {
			addEntity(entity)
		}
		
		// Merge relationships
		for relationship in other.relationships {
			addRelationship(relationship)
		}
		
		// Merge communities
		addCommunities(other.communities)
	}
	
	// MARK: - Codable
	
	enum CodingKeys: String, CodingKey {
		case entitiesDict
		case relationships
		case communities
		case chunkToEntities
		case resourceId
	}
	
	required public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		let decodedEntities = try container.decode([UUID: GraphEntity].self, forKey: .entitiesDict)
		let decodedRelationships = try container.decode([GraphRelationship].self, forKey: .relationships)
		let decodedCommunities = try container.decode([Community].self, forKey: .communities)
		resourceId = try container.decode(UUID.self, forKey: .resourceId)
		
		// Decode chunkToEntities with Set<UUID>
		let chunkDict = try container.decode([String: [String]].self, forKey: .chunkToEntities)
		var decodedChunkToEntities: [Int: Set<UUID>] = [:]
		for (key, value) in chunkDict {
			if let chunkIndex = Int(key) {
				decodedChunkToEntities[chunkIndex] = Set(value.compactMap { UUID(uuidString: $0) })
			}
		}
		self.state = Mutex(GraphState(
			entitiesDict: decodedEntities,
			relationships: decodedRelationships,
			communities: decodedCommunities,
			chunkToEntities: decodedChunkToEntities
		))
	}
	
	public func encode(to encoder: Encoder) throws {
		try state.withLock { s in
			var container = encoder.container(keyedBy: CodingKeys.self)
			
			try container.encode(s.entitiesDict, forKey: .entitiesDict)
			try container.encode(s.relationships, forKey: .relationships)
			try container.encode(s.communities, forKey: .communities)
			try container.encode(resourceId, forKey: .resourceId)
			
			// Encode chunkToEntities
			var chunkDict: [String: [String]] = [:]
			for (key, value) in s.chunkToEntities {
				chunkDict[String(key)] = value.map { $0.uuidString }
			}
			try container.encode(chunkDict, forKey: .chunkToEntities)
		}
	}
}

