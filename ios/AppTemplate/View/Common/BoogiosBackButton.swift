//
//  BoogiosBackButton.swift
//  AppTemplate
//

import SwiftUI

struct BoogiosBackButton: View {
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.backward")
                .font(.pretendardSemiBold(size: 18))
                .foregroundStyle(Color.boogiosGray8)
                .frame(width: 40, height: 40)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
