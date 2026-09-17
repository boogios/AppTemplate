//
//  CommonL10n.swift
//  AppTemplate
//

import Foundation

enum CommonL10n {
    
    static var tabHome: String {
        L10n.text(en: "Home", ko: "홈", ja: "ホーム", deDE: "Start", frFR: "Accueil", ptBR: "Início", vi: "Trang chủ")
    }
    
    static var tabSettings: String {
        L10n.text(en: "Settings", ko: "설정", ja: "設定", deDE: "Einstellungen", frFR: "Réglages", ptBR: "Ajustes", vi: "Cài đặt")
    }
    
    static var done: String {
        L10n.text(en: "Done", ko: "완료", ja: "完了", deDE: "Fertig", frFR: "Terminé", ptBR: "Concluído", vi: "Xong")
    }
    
    static var close: String {
        L10n.text(en: "Close", ko: "닫기", ja: "閉じる", deDE: "Schließen", frFR: "Fermer", ptBR: "Fechar", vi: "Đóng")
    }
    
    static var adBadge: String {
        L10n.text(en: "Ad", ko: "광고", ja: "広告", deDE: "Anzeige", frFR: "Pub", ptBR: "Anúncio", vi: "Quảng cáo")
    }
    
    static var adCallToActionFallback: String {
        L10n.text(en: "Open", ko: "열기", ja: "開く", deDE: "Öffnen", frFR: "Ouvrir", ptBR: "Abrir", vi: "Mở")
    }
}
