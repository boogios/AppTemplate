//
//  BoogiosToggleStyle.swift
//  AppTemplate
//

import SwiftUI

struct BoogiosToggleStyle: ToggleStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 50)
                .fill(configuration.isOn ? Color.boogiosMain : Color.boogiosGray3)
                .frame(width: 44, height: 24)
                .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
            
            Circle()
                .fill(Color.boogiosWhite)
                .frame(width: 18, height: 18)
                .shadow(color: Color.boogiosGray10.opacity(0.12), radius: 2, y: 1)
                .offset(x: configuration.isOn ? 10 : -10)
                .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            configuration.isOn.toggle()
        }
    }
}

struct BoogiosOutlineToggleStyle: ToggleStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 50)
                .fill(configuration.isOn ? Color.boogiosMainSofter : Color.boogiosWhite)
                .frame(width: 44, height: 24)
                .overlay(
                    RoundedRectangle(cornerRadius: 50)
                        .stroke(configuration.isOn ? Color.boogiosMain : Color.boogiosGray3, lineWidth: 1.5)
                )
                .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
            
            Circle()
                .fill(configuration.isOn ? Color.boogiosMain : Color.boogiosGray5)
                .frame(width: 16, height: 16)
                .offset(x: configuration.isOn ? 10 : -10)
                .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            configuration.isOn.toggle()
        }
    }
}
