//
//  SantasToyManagerApp.swift
//  Complete SwiftUI + JSON + CoreData App
//

import SwiftUI
import Foundation
import CoreData

// MARK: - Toy Model for JSON (Struct)
struct Toy: Codable, Identifiable {
    var id = UUID()
    var name: String
    var amount: Int
    var category: String?
}

// MARK: - Core Data Model Helper
extension ToyEntity {
    var wrappedName: String { name ?? "Unknown" }
    var wrappedCategory: String { category ?? "Uncategorized" }
}

// MARK: - Toy Manager
class ToyManager: ObservableObject {
    @Published var toys: [Toy] = []
    private let container: NSPersistentContainer

    init(container: NSPersistentContainer = PersistenceController.shared.container) {
        self.container = container
        loadFromCoreData()
    }

    // Create
    func createToy(name: String, amount: Int) {
        let toy = ToyEntity(context: container.viewContext)
        toy.id = UUID()
        toy.name = name
        toy.amount = Int32(amount)
        toy.category = nil
        saveContext()
        loadFromCoreData()
    }

    // Update Quantity
    func updateQuantity(for toyName: String, to amount: Int) {
        let request: NSFetchRequest<ToyEntity> = ToyEntity.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", toyName)
        if let results = try? container.viewContext.fetch(request),
           let toy = results.first {
            toy.amount = Int32(amount)
            saveContext()
            loadFromCoreData()
        }
    }

    // Add Category to All
    func addCategory(_ category: String) {
        let request: NSFetchRequest<ToyEntity> = ToyEntity.fetchRequest()
        if let results = try? container.viewContext.fetch(request) {
            for toy in results {
                toy.category = category
            }
            saveContext()
            loadFromCoreData()
        }
    }

    // Load from Core Data
    func loadFromCoreData() {
        let request: NSFetchRequest<ToyEntity> = ToyEntity.fetchRequest()
        if let results = try? container.viewContext.fetch(request) {
            toys = results.map {
                Toy(id: $0.id ?? UUID(), name: $0.wrappedName, amount: Int($0.amount), category: $0.category)
            }
        }
    }

    private func saveContext() {
        if container.viewContext.hasChanges {
            try? container.viewContext.save()
        }
    }
}

// MARK: - Persistence Controller
struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SantasToyModel")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
}

// MARK: - SwiftUI View
struct ContentView: View {
    @StateObject private var toyManager = ToyManager()
    @State private var name = ""
    @State private var amount = ""
    @State private var category = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Add New Toy")) {
                    TextField("Name", text: $name)
                    TextField("Amount", text: $amount)
                        .keyboardType(.numberPad)
                    Button("Add") {
                        if let amt = Int(amount) {
                            toyManager.createToy(name: name, amount: amt)
                            name = ""
                            amount = ""
                        }
                    }
                }

                Section(header: Text("Add Category to All")) {
                    TextField("Category", text: $category)
                    Button("Apply") {
                        toyManager.addCategory(category)
                        category = ""
                    }
                }

                Section(header: Text("Toys List")) {
                    ForEach(toyManager.toys) { toy in
                        VStack(alignment: .leading) {
                            Text(toy.name).font(.headline)
                            Text("Amount: \(toy.amount)")
                            if let cat = toy.category {
                                Text("Category: \(cat)").font(.subheadline).foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Santa's Toy Manager")
        }
    }
}

// MARK: - App Entry
@main
struct SantasToyManagerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
