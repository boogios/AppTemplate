//
//  L10n.swift
//  AppTemplate
//

import Foundation

enum L10n {
    
    static func text(
        en: String,
        ko: String,
        ja: String,
        enGB: String? = nil,
        enCA: String? = nil,
        enAU: String? = nil,
        deDE: String? = nil,
        frFR: String? = nil,
        ptBR: String? = nil,
        vi: String? = nil
    ) -> String {
        switch AppLanguage.current.resolved {
        case .korean:
            return ko
        case .japanese:
            return ja
        case .englishUS:
            return en
        case .englishGB:
            return enGB ?? en
        case .englishCA:
            return enCA ?? en
        case .englishAU:
            return enAU ?? en
        case .german:
            return deDE ?? en
        case .french:
            return frFR ?? en
        case .portugueseBR:
            return ptBR ?? en
        case .vietnamese:
            return vi ?? en
        case .system:
            return en
        }
    }
}
