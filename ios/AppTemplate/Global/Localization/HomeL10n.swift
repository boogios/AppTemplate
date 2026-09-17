//
//  HomeL10n.swift
//  AppTemplate
//

import Foundation

enum HomeL10n {
    
    static var title: String {
        L10n.text(en: "Start from a clean base", ko: "깔끔한 기본 앱에서 시작해요", ja: "きれいな土台から始めましょう")
    }
    
    static var subtitle: String {
        L10n.text(
            en: "Design tokens, localization, settings, and Boogios-style structure are ready.",
            ko: "디자인 토큰, 다국어, 설정 화면, Boogios식 구조가 준비되어 있어요.",
            ja: "デザイントークン、多言語、設定画面、Boogios式の構造がそろっています。"
        )
    }
    
    static var cardTitle: String {
        L10n.text(en: "Next step", ko: "다음 작업", ja: "次の作業")
    }
    
    static var cardDescription: String {
        L10n.text(
            en: "Replace this home screen with the first real feature of your new app.",
            ko: "이 홈 화면을 새 앱의 첫 실제 기능으로 바꾸면 돼요.",
            ja: "このホーム画面を新しいアプリの最初の機能に置き換えてください。"
        )
    }
}
