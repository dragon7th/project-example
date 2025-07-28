//
//  SantasToyManagerApp.swift
//  Complete SwiftUI + JSON App
//

import SwiftUI
import Foundation

// MARK: - Toy Model
struct Toy: Codable, Identifiable {
    var id = UUID()
    var name: String
    var amount: Int
    var category: String?
}

// MARK: - Toy Manager with JSON Persistence
class ToyManager: ObservableObject {
    @Published private(set) var toys: [Toy] = []

    // Create
    func createToy(name: String, amount: Int) {
        let toy = Toy(name: name, amount: amount)
        toys.append(toy)
        saveToJSON()
    }

    // Update quantity
    func updateQuantity(for toyName: String, to amount: Int) {
        guard let index = toys.firstIndex(where: { $0.name == toyName }) else { return }
        toys[index].amount = amount
        saveToJSON()
    }

    // Add category
    func addCategory(_ category: String) {
        toys = toys.map { toy in
            var modified = toy
            modified.category = category
            return modified
        }
        saveToJSON()
    }

    // MARK: JSON Persistence
    private let fileName = "toys.json"

    func saveToJSON() {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(toys) else { return }
        if let url = getDocumentsDirectory()?.appendingPathComponent(fileName) {
            try? data.write(to: url)
        }
    }

    func loadFromJSON() {
        guard let url = getDocumentsDirectory()?.appendingPathComponent(fileName),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Toy].self, from: data) else { return }
        self.toys = decoded
    }

    private func getDocumentsDirectory() -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
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
            .onAppear {
                toyManager.loadFromJSON()
            }
        }
    }
}

// MARK: - App Entry
@main
struct SantasToyManagerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
