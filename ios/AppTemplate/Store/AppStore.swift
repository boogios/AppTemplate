//
//  AppStore.swift
//  AppTemplate
//

import Foundation

final class AppStore: ObservableObject {
    
    @Published var selectedTab: AppTab = .home
}
