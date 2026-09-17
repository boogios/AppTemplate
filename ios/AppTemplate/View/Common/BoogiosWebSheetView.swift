//
//  BoogiosWebSheetView.swift
//  AppTemplate
//

import SwiftUI

struct BoogiosWebSheetView: View {
    
    let url: URL
    let title: String
    
    var body: some View {
        BoogiosWebView(url: url)
            .ignoresSafeArea(edges: .bottom)
            .customNavigationBar(title: title)
            .background(Color.boogiosGray1)
    }
}
