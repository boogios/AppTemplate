//
//  BoogiosNavigationButton.swift
//  AppTemplate
//

import SwiftUI

struct BoogiosNavigationButton: View {
    
    let title: String
    var systemImage: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.pretendardSemiBold(size: 15))
                
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.pretendardSemiBold(size: 14))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundStyle(Color.boogiosWhite)
            .background(Color.boogiosMain)
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
}
