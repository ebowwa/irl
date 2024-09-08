//
//  LanguageSettingsView.swift
//  irl
//
//  Created by Elijah Arbee on 8/29/24.
//
// LanguageSettingsView.swift
// TODO: AUTODETECT Language
import SwiftUI

struct LanguageSettingsView: View {
    @Binding var selectedLanguage: Language

    var body: some View {
        Picker("Select Language", selection: $selectedLanguage) {
            ForEach(Language.allCases, id: \.self) { language in
                Text(language.rawValue.capitalized).tag(language)
            }
        }
    }
}

