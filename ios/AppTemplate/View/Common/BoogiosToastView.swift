//
//  BoogiosToastView.swift
//  AppTemplate
//

import SwiftUI

struct BoogiosToastView: View {
    
    let message: String
    
    var body: some View {
        Text(message)
            .font(.pretendardMedium(size: 14))
            .foregroundStyle(Color.boogiosWhite)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Color.boogiosGray9.opacity(0.92))
            .cornerRadius(24)
    }
}
