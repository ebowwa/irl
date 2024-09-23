//
//  MemoryModule.swift
//  irl
// TODO: Integrate Knowledge Graph
//  Created by Elijah Arbee on 9/6/24.
//
import SwiftUI
import CoreData
import NaturalLanguage

// MARK: - Data Models

struct Memory: Identifiable, Codable {
    let id: UUID
    let content: String
    let type: MemoryType
    let timestamp: Date
    var embedding: [Float]?
}

enum MemoryType: String, Codable, CaseIterable {
    case chat
    case background
    case inference
}

// MARK: - Knowledge Graph Models

struct KnowledgeNode: Identifiable {
    let id: UUID
    let name: String
    var memoryIds: [UUID] // Relation to memories
    var relationships: [KnowledgeRelation]
}

struct KnowledgeRelation {
    let sourceId: UUID
    let targetId: UUID
    let relationType: RelationType
}

enum RelationType: String {
    case cause
    case effect
    case dependency
    case reference
}

// MARK: - View Model

class MemoryViewModel: ObservableObject {
    @Published var memories: [Memory] = []
    @Published var embeddingsSearchQuery: String = ""
    @Published var searchResults: [Memory] = []
    @Published var knowledgeGraph: [KnowledgeNode] = [] // Store nodes
    
    private let memoryManager: MemoryManager
    
    init() {
        self.memoryManager = MemoryManager()
        loadMemories()
        loadKnowledgeGraph()
    }
    
    func loadMemories() {
        memories = memoryManager.fetchAllMemories()
    }
    
    func loadKnowledgeGraph() {
        knowledgeGraph = memoryManager.fetchKnowledgeGraph()
    }
    
    func addMemory(content: String, type: MemoryType) {
        if let newMemory = memoryManager.createMemory(content: content, type: type) {
            memories.append(newMemory)
        } else {
            print("Failed to create memory")
        }
    }
    
    func deleteMemory(memory: Memory) {
        memoryManager.deleteMemory(memory)
        if let index = memories.firstIndex(where: { $0.id == memory.id }) {
            memories.remove(at: index)
        }
    }
    
    func searchEmbeddings() {
        searchResults = memoryManager.searchMemories(query: embeddingsSearchQuery)
    }
    
    func addNodeToGraph(name: String, relatedMemoryIds: [UUID], relationships: [KnowledgeRelation]) {
        let newNode = KnowledgeNode(id: UUID(), name: name, memoryIds: relatedMemoryIds, relationships: relationships)
        knowledgeGraph.append(newNode)
        memoryManager.saveKnowledgeNode(newNode)
    }
    
    func addRelationship(sourceId: UUID, targetId: UUID, type: RelationType) {
        let relation = KnowledgeRelation(sourceId: sourceId, targetId: targetId, relationType: type)
        memoryManager.addKnowledgeRelation(relation)
    }
}

// MARK: - Views

struct MemorySettingsView: View {
    @StateObject private var viewModel = MemoryViewModel()
    @State private var newMemoryContent: String = ""
    @State private var selectedMemoryType: MemoryType = .chat
    @State private var newNodeName: String = ""
    @State private var relatedMemoryIds: [UUID] = []
    @State private var relationType: RelationType = .reference
    
    var body: some View {
        Form {
            Section(header: Text("Add New Memory")) {
                TextEditor(text: $newMemoryContent)
                    .frame(height: 100)
                
                Picker("Memory Type", selection: $selectedMemoryType) {
                    ForEach(MemoryType.allCases, id: \.self) { type in
                        Text(type.rawValue.capitalized).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Button("Add Memory") {
                    viewModel.addMemory(content: newMemoryContent, type: selectedMemoryType)
                    newMemoryContent = ""
                }
                .disabled(newMemoryContent.isEmpty)
            }
            
            Section(header: Text("Existing Memories")) {
                List {
                    ForEach(viewModel.memories) { memory in
                        VStack(alignment: .leading) {
                            Text(memory.content)
                                .font(.body)
                            Text(memory.type.rawValue.capitalized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onDelete(perform: deleteMemories)
                }
            }
            
            Section(header: Text("Embeddings Search")) {
                TextField("Search query", text: $viewModel.embeddingsSearchQuery)
                Button("Search") {
                    viewModel.searchEmbeddings()
                }
                
                if !viewModel.searchResults.isEmpty {
                    List(viewModel.searchResults) { result in
                        VStack(alignment: .leading) {
                            Text(result.content)
                                .font(.body)
                            Text(result.type.rawValue.capitalized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Section(header: Text("Knowledge Graph")) {
                TextField("New Node Name", text: $newNodeName)
                Button("Add Node") {
                    viewModel.addNodeToGraph(name: newNodeName, relatedMemoryIds: relatedMemoryIds, relationships: [])
                    newNodeName = ""
                }
                List {
                    ForEach(viewModel.knowledgeGraph) { node in
                        VStack(alignment: .leading) {
                            Text(node.name)
                                .font(.body)
                        }
                    }
                }
            }
        }
    }
    
    private func deleteMemories(at offsets: IndexSet) {
        for index in offsets {
            let memory = viewModel.memories[index]
            viewModel.deleteMemory(memory: memory)
        }
    }
}

// MARK: - Memory Manager

class MemoryManager {
    private let container: NSPersistentContainer
    private let embeddingModel: NLEmbedding

    init() {
        container = NSPersistentContainer(name: "MemoryStore")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        guard let embeddingModel = NLEmbedding.sentenceEmbedding(for: .english) else {
            fatalError("Failed to load sentence embedding model")
        }
        self.embeddingModel = embeddingModel
    }
    
    func createMemory(content: String, type: MemoryType) -> Memory? {
        let context = container.viewContext
        guard let entity = NSEntityDescription.entity(forEntityName: "Memory", in: context) else {
            print("Failed to get Memory entity")
            return nil
        }
        
        let newMemory = NSManagedObject(entity: entity, insertInto: context)
        
        let id = UUID()
        newMemory.setValue(id, forKey: "id")
        newMemory.setValue(content, forKey: "content")
        newMemory.setValue(type.rawValue, forKey: "type")
        newMemory.setValue(Date(), forKey: "timestamp")
        
        if let embedding = embeddingModel.vector(for: content) {
            newMemory.setValue(embedding, forKey: "embedding")
            
            do {
                try context.save()
                return Memory(id: id, content: content, type: type, timestamp: Date(), embedding: embedding.map { Float($0) })
            } catch {
                print("Failed to save memory: \(error)")
                return nil
            }
        } else {
            print("Failed to create embedding for memory")
            return nil
        }
    }
    
    func fetchAllMemories() -> [Memory] {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Memory")
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.compactMap { result in
                guard let id = result.value(forKey: "id") as? UUID,
                      let content = result.value(forKey: "content") as? String,
                      let typeString = result.value(forKey: "type") as? String,
                      let type = MemoryType(rawValue: typeString),
                      let timestamp = result.value(forKey: "timestamp") as? Date,
                      let embedding = result.value(forKey: "embedding") as? [Double] else {
                    return nil
                }
                return Memory(id: id, content: content, type: type, timestamp: timestamp, embedding: embedding.map { Float($0) })
            }
        } catch {
            print("Failed to fetch memories: \(error)")
            return []
        }
    }
    
    func fetchKnowledgeGraph() -> [KnowledgeNode] {
        // Fetch knowledge graph data from CoreData or any storage
        // This function needs to be implemented based on your storage strategy.
        return []
    }
    
    func saveKnowledgeNode(_ node: KnowledgeNode) {
        // Save the node to the storage (CoreData, etc.)
        // Implementation is needed based on your strategy.
    }
    
    func addKnowledgeRelation(_ relation: KnowledgeRelation) {
        // Save relationship to storage
        // This function needs to be implemented as per the storage strategy
    }
    
    func deleteMemory(_ memory: Memory) {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Memory")
        fetchRequest.predicate = NSPredicate(format: "id == %@", memory.id as CVarArg)
        
        do {
            if let result = try context.fetch(fetchRequest).first {
                context.delete(result)
                try context.save()
            }
        } catch {
            print("Failed to delete memory: \(error)")
        }
    }
    
    func searchMemories(query: String) -> [Memory] {
        guard let queryEmbedding = embeddingModel.vector(for: query) else {
            return []
        }
        
        let allMemories = fetchAllMemories()
        let sortedMemories = allMemories.compactMap { memory -> (Memory, Float)? in
            guard let memoryEmbedding = memory.embedding else { return nil }
            let similarity = cosineSimilarity(queryEmbedding.map { Float($0) }, memoryEmbedding)
            return (memory, similarity)
        }
        .sorted { $0.1 > $1.1 }
        
        return sortedMemories.prefix(5).map { $0.0 }
    }
    
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return 0 }
        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        return dotProduct / (magnitudeA * magnitudeB)
    }
}
