//
//  Color+.swift
//  AppTemplate
//

import SwiftUI
import UIKit

extension Color {
    
    init(hex: String) {
        self = Self.makeColor(hex: hex)
    }
    
    static let boogiosMain = Color(hex: AppConfig.mainColorHex)
    static let boogiosMainSoft = Color.dynamicDerived(from: AppConfig.mainColorHex, lightMixingWithWhite: 0.72, darkMixingWithBlack: 0.35)
    static let boogiosMainSofter = Color.dynamicDerived(from: AppConfig.mainColorHex, lightMixingWithWhite: 0.88, darkMixingWithBlack: 0.55)
    
    static let boogiosWhite = Color.dynamic(light: "#FFFFFF", dark: "#1C1C1E")
    static let boogiosGray1 = Color.dynamic(light: "#F7F8FA", dark: "#000000")
    static let boogiosGray2 = Color.dynamic(light: "#EEF0F4", dark: "#2C2C2E")
    static let boogiosGray3 = Color.dynamic(light: "#DBDEE5", dark: "#3A3A3C")
    static let boogiosGray4 = Color.dynamic(light: "#C3C8D1", dark: "#48484A")
    static let boogiosGray5 = Color.dynamic(light: "#8C929F", dark: "#636366")
    static let boogiosGray6 = Color.dynamic(light: "#6C7280", dark: "#8E8E93")
    static let boogiosGray7 = Color.dynamic(light: "#4D525D", dark: "#AEAEB2")
    static let boogiosGray8 = Color.dynamic(light: "#333844", dark: "#C7C7CC")
    static let boogiosGray9 = Color.dynamic(light: "#1B1F27", dark: "#F2F2F7")
    static let boogiosGray10 = Color.dynamic(light: "#0B0D12", dark: "#FFFFFF")
    
    private static func dynamic(light: String, dark: String) -> Color {
        Color(
            UIColor { traitCollection in
                let hex = traitCollection.userInterfaceStyle == .dark ? dark : light
                let components = Self.components(from: hex)
                return UIColor(
                    red: CGFloat(components.red),
                    green: CGFloat(components.green),
                    blue: CGFloat(components.blue),
                    alpha: CGFloat(components.opacity)
                )
            }
        )
    }
    
    private static func dynamicDerived(from hex: String, lightMixingWithWhite whiteAmount: Double, darkMixingWithBlack blackAmount: Double) -> Color {
        Color(
            UIColor { traitCollection in
                let color = traitCollection.userInterfaceStyle == .dark
                    ? Self.derivedComponents(from: hex, mixingWithBlack: blackAmount)
                    : Self.derivedComponents(from: hex, mixingWithWhite: whiteAmount)
                return UIColor(
                    red: CGFloat(color.red),
                    green: CGFloat(color.green),
                    blue: CGFloat(color.blue),
                    alpha: CGFloat(color.opacity)
                )
            }
        )
    }
    
    private static func derived(from hex: String, mixingWithWhite amount: Double) -> Color {
        let components = Self.derivedComponents(from: hex, mixingWithWhite: amount)
        
        return Color(
            .sRGB,
            red: components.red,
            green: components.green,
            blue: components.blue,
            opacity: components.opacity
        )
    }
    
    private static func derivedComponents(from hex: String, mixingWithWhite amount: Double) -> (red: Double, green: Double, blue: Double, opacity: Double) {
        let components = Self.components(from: hex)
        let amount = min(max(amount, 0), 1)
        
        return (
            red: components.red + (1 - components.red) * amount,
            green: components.green + (1 - components.green) * amount,
            blue: components.blue + (1 - components.blue) * amount,
            opacity: components.opacity
        )
    }
    
    private static func derivedComponents(from hex: String, mixingWithBlack amount: Double) -> (red: Double, green: Double, blue: Double, opacity: Double) {
        let components = Self.components(from: hex)
        let amount = min(max(amount, 0), 1)
        
        return (
            red: components.red * (1 - amount),
            green: components.green * (1 - amount),
            blue: components.blue * (1 - amount),
            opacity: components.opacity
        )
    }
    
    private static func makeColor(hex: String) -> Color {
        let components = Self.components(from: hex)
        return Color(.sRGB, red: components.red, green: components.green, blue: components.blue, opacity: components.opacity)
    }
    
    private static func components(from hex: String) -> (red: Double, green: Double, blue: Double, opacity: Double) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 71, 92, 239)
        }
        
        return (
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
