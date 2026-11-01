//
//  HomeL10n.swift
//  AppTemplate
//

import Foundation

enum HomeL10n {
    
    static var title: String {
        L10n.text(en: "Start from a clean base", ko: "깔끔한 기본 앱에서 시작해요", ja: "きれいな土台から始めましょう", deDE: "Mit einer klaren Basis starten", frFR: "Partez sur de bonnes bases", ptBR: "Comece com uma base organizada", vi: "Bắt đầu từ nền tảng gọn gàng")
    }
    
    static var subtitle: String {
        L10n.text(
            en: "Design tokens, localization, settings, and Boogios-style structure are ready.",
            ko: "디자인 토큰, 다국어, 설정 화면, Boogios식 구조가 준비되어 있어요.",
            ja: "デザイントークン、多言語、設定画面、Boogios式の構造がそろっています。",
            deDE: "Designtokens, Übersetzungen, Einstellungen und die Boogios-Struktur sind bereit.",
            frFR: "Les styles, les traductions, les réglages et la structure Boogios sont prêts.",
            ptBR: "Estilos, traduções, configurações e a estrutura Boogios estão prontos.",
            vi: "Các kiểu thiết kế, bản dịch, cài đặt và cấu trúc Boogios đã sẵn sàng."
        )
    }
    
    static var cardTitle: String {
        L10n.text(en: "Next step", ko: "다음 작업", ja: "次の作業", deDE: "Nächster Schritt", frFR: "Prochaine étape", ptBR: "Próximo passo", vi: "Bước tiếp theo")
    }
    
    static var cardDescription: String {
        L10n.text(
            en: "Replace this home screen with the first real feature of your new app.",
            ko: "이 홈 화면을 새 앱의 첫 실제 기능으로 바꾸면 돼요.",
            ja: "このホーム画面を新しいアプリの最初の機能に置き換えてください。",
            deDE: "Ersetze diese Startseite durch die erste Funktion deiner neuen App.",
            frFR: "Remplacez cet écran par la première fonctionnalité de votre application.",
            ptBR: "Substitua esta tela inicial pela primeira funcionalidade do seu novo app.",
            vi: "Thay màn hình chính này bằng tính năng đầu tiên của ứng dụng mới."
        )
    }
}
