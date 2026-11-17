//
//  AppModel.swift
//  RAU.am
//
//  Created by artak on 17.10.26.
//  Copyright © 2026 Russian-Armenian University. All rights reserved.
//


import SwiftUI
import NetworkLayer

enum AppTab: Hashable { case home, news, anons, institutes, menu }

/// App-wide state: the selected language and the `API` configured for it.
@MainActor
final class AppModel: ObservableObject {
    static let baseURL = URL(string: "https://rau.am/api/v1")!
    private static let languageKey = "app.language"

    @Published var selectedTab: AppTab = .home

    @Published var language: AppLanguage {
        didSet {
            guard oldValue != language else { return }
            UserDefaults.standard.set(language.rawValue, forKey: Self.languageKey)
            api = Self.makeAPI(language)
            generation += 1                      // screens reload when this changes
        }
    }

    @Published private(set) var api: API
    @Published private(set) var generation = 0

    init() {
        let saved = UserDefaults.standard.string(forKey: Self.languageKey).flatMap(AppLanguage.init(rawValue:))
        let initial = saved ?? .deviceDefault
        language = initial
        api = Self.makeAPI(initial)
    }

    /// Every request carries `?lang=<id>`.
    private static func makeAPI(_ language: AppLanguage) -> API {
        API(baseURL: baseURL, queryItems: [URLQueryItem(name: "lang", value: String(language.apiID))])
    }
}
