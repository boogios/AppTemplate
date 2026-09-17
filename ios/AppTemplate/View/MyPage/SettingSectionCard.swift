//
//  SettingSectionCard.swift
//  AppTemplate
//

import SwiftUI

struct SettingSectionCard: View {
    
    let section: SettingSection
    let onTap: (SettingItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 28) {
                ForEach(Array(section.items.enumerated()), id: \.element.id) { _, item in
                    Button {
                        onTap(item)
                    } label: {
                        SettingRow(item: item)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(item.accessibilityIdentifier ?? item.title)
                }
            }
            .padding(20)
        }
        .background(Color.boogiosWhite)
        .cornerRadius(16)
    }
}

struct SettingRow: View {
    
    let item: SettingItem
    
    var body: some View {
        HStack(spacing: 12) {
            Text(item.title)
                .font(.body2)
                .foregroundStyle(item.role == .destructive ? Color.red : Color.boogiosGray7)
            
            Spacer()
            
            if let trailing = item.trailingText {
                HStack(spacing: 6) {
                    Text(trailing)
                        .font(.pretendardMedium(size: 12))
                        .foregroundStyle(Color.boogiosGray5)
                    
                    if item.showsChevron {
                        Image(systemName: "chevron.right")
                            .font(.pretendardMedium(size: 14))
                            .foregroundStyle(Color.boogiosGray5)
                    }
                }
            } else if item.showsChevron {
                Image(systemName: "chevron.right")
                    .font(.pretendardMedium(size: 14))
                    .foregroundStyle(Color.boogiosGray5)
            }
        }
        .contentShape(Rectangle())
    }
}
