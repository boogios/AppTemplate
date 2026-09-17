//
//  NavigationPathManager.swift
//  AppTemplate
//

import SwiftUI

final class NavigationPathManager: ObservableObject {
    
    @Published var homePath = NavigationPath()
    @Published var myPagePath = NavigationPath()
}
