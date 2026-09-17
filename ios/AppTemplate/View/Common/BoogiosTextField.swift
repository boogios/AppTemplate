//
//  BoogiosTextField.swift
//  AppTemplate
//

import SwiftUI

struct BoogiosTextField: View {
    
    let title: String
    @Binding var text: String
    
    var body: some View {
        TextField(title, text: $text)
            .font(.body1)
            .foregroundStyle(Color.boogiosGray9)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.boogiosWhite)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.boogiosGray3, lineWidth: 1)
            )
    }
}
