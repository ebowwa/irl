//
//  SearchView.swift
//  irl
//
//  Created by Elijah Arbee on 8/29/24.
//
/**
- search through memories
- tickets of your life
- also a llm chat to have an analytical agent throughout your memories
*/
import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @State private var searchResults: [SearchResult] = []

    var body: some View {
        VStack {
            SearchBar(text: $searchText, onCommit: performSearch)

            List(searchResults) { result in
                SearchResultRow(result: result)
            }
        }
        .navigationBarTitle("Search", displayMode: .inline)
    }

    func performSearch() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.searchResults = [
                SearchResult(id: UUID(), title: "Result 1", description: "Description for Result 1"),
                SearchResult(id: UUID(), title: "Result 2", description: "Description for Result 2"),
                SearchResult(id: UUID(), title: "Result 3", description: "Description for Result 3")
            ]
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    var onCommit: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search", text: $text, onCommit: onCommit)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.horizontal)
    }
}

struct SearchResult: Identifiable {
    let id: UUID
    let title: String
    let description: String
}

struct SearchResultRow: View {
    let result: SearchResult

    var body: some View {
        VStack(alignment: .leading) {
            Text(result.title)
                .font(.headline)
            Text(result.description)
                .font(.subheadline)
                .foregroundColor(Color("SecondaryTextColor"))
        }
    }
}

// Note: This view and its components are self-contained and don't directly depend on AppState
