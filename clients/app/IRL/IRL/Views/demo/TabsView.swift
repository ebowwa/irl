//
//  TabsView.swift
//  irl
//
//  Created by Elijah Arbee on 8/29/24.
//
/** 
TODO:
- make more customizable: add drag & drop & reusable for the MainTabMenu
- add shop + marketplace
- this currently shows double for the 
**/
import SwiftUI

struct Feature: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
}

struct TabsView: View {
    @State private var features: [Feature] = [
        Feature(name: "Chat", icon: "bubble.left.and.bubble.right.fill", color: .blue),
        Feature(name: "Transcript", icon: "text.bubble.fill", color: .green),
        Feature(name: "Advocate", icon: "person.fill.checkmark", color: .purple),
        Feature(name: "Coach", icon: "figure.mind.and.body", color: .orange),
        Feature(name: "Custom Plugins", icon: "puzzlepiece.fill", color: .pink)
    ]
    @State private var isAddingFeature = false

    var body: some View {
        NavigationView {
            List {
                ForEach(features) { feature in
                    HStack {
                        Image(systemName: feature.icon)
                            .foregroundColor(feature.color)
                            .font(.system(size: 24))
                        Text(feature.name)
                            .font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 8)
                }
                .onDelete(perform: deleteFeature)
                .onMove(perform: moveFeature)
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("AI Features")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isAddingFeature = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingFeature) {
                AddFeatureView(isPresented: $isAddingFeature, features: $features)
            }
        }
    }

    private func deleteFeature(at offsets: IndexSet) {
        features.remove(atOffsets: offsets)
    }

    private func moveFeature(from source: IndexSet, to destination: Int) {
        features.move(fromOffsets: source, toOffset: destination)
    }
}

struct AddFeatureView: View {
    @Binding var isPresented: Bool
    @Binding var features: [Feature]
    @State private var newFeatureName = ""
    @State private var newFeatureIcon = "star.fill"
    @State private var newFeatureColor: Color = .blue

    var body: some View {
        NavigationView {
            Form {
                TextField("Feature Name", text: $newFeatureName)
                Picker("Icon", selection: $newFeatureIcon) {
                    ForEach(["star.fill", "wand.and.stars", "brain", "network", "cube.transparent"], id: \.self) { icon in
                        Image(systemName: icon).tag(icon)
                    }
                }
                ColorPicker("Color", selection: $newFeatureColor)
                Button("Add Feature") {
                    let newFeature = Feature(name: newFeatureName, icon: newFeatureIcon, color: newFeatureColor)
                    features.append(newFeature)
                    isPresented = false
                }
                .disabled(newFeatureName.isEmpty)
            }
            .navigationTitle("Add New AI Feature")
            .navigationBarItems(trailing: Button("Cancel") { isPresented = false })
        }
    }
}

struct AITabsView_Previews: PreviewProvider {
    static var previews: some View {
        TabsView()
    }
}
