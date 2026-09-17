//
//  HomeView.swift
//  AppTemplate
//

import SwiftUI

struct HomeView: View {
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(HomeL10n.title)
                        .font(.headline1)
                        .foregroundStyle(Color.boogiosGray9)
                    
                    Text(HomeL10n.subtitle)
                        .font(.body2)
                        .foregroundStyle(Color.boogiosGray7)
                        .lineSpacing(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .boogiosCardStyle()
                
                VStack(alignment: .leading, spacing: 10) {
                    Text(HomeL10n.cardTitle)
                        .font(.subtitle2)
                        .foregroundStyle(Color.boogiosMain)
                    
                    Text(HomeL10n.cardDescription)
                        .font(.body2)
                        .foregroundStyle(Color.boogiosGray7)
                        .lineSpacing(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .boogiosCardStyle()
            }
            .padding(20)
        }
        .background(Color.boogiosGray1)
        .customNavigationBar(title: AppConfig.appName)
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
