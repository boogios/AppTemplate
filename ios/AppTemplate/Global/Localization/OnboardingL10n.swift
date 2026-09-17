//
//  OnboardingL10n.swift
//  AppTemplate
//

import Foundation

enum OnboardingL10n {

    static var introOneTitle: String {
        L10n.text(
            en: "Start your app journey",
            ko: "나만의 앱을 시작해요",
            ja: "自分だけのアプリを始めましょう",
            deDE: "Starte deine App-Reise",
            frFR: "Commencez votre aventure",
            ptBR: "Comece sua jornada no app",
            vi: "Bắt đầu hành trình ứng dụng"
        )
    }

    static var introOneDescription: String {
        L10n.text(
            en: "Build \(AppConfig.appName) with the features and experience you want.",
            ko: "원하는 기능과 경험을 담아 \(AppConfig.appName)을 만들어보세요.",
            ja: "欲しい機能と体験を詰め込んだ\(AppConfig.appName)を始めましょう。",
            deDE: "Gestalte \(AppConfig.appName) mit deinen eigenen Funktionen und Erlebnissen.",
            frFR: "Créez \(AppConfig.appName) avec les fonctions et l’expérience que vous souhaitez.",
            ptBR: "Crie o \(AppConfig.appName) com os recursos e a experiência que você deseja.",
            vi: "Tạo \(AppConfig.appName) với những tính năng và trải nghiệm bạn muốn."
        )
    }

    static var introTwoTitle: String {
        L10n.text(
            en: "Make it feel like yours",
            ko: "처음부터 편리하게",
            ja: "最初から快適に",
            deDE: "Mach es zu deinem",
            frFR: "Une expérience qui vous ressemble",
            ptBR: "Do seu jeito desde o início",
            vi: "Thoải mái ngay từ đầu"
        )
    }

    static var introTwoDescription: String {
        L10n.text(
            en: "Review notification and advertising settings, then make the app your own.",
            ko: "알림과 광고 설정을 확인하고 나에게 맞는 앱을 시작해요.",
            ja: "通知と広告の設定を確認して、自分に合ったアプリを始めましょう。",
            deDE: "Prüfe Benachrichtigungs- und Werbeeinstellungen und passe die App an.",
            frFR: "Vérifiez les réglages des notifications et de la publicité pour personnaliser l’app.",
            ptBR: "Confira as configurações de notificações e anúncios para personalizar o app.",
            vi: "Xem lại cài đặt thông báo và quảng cáo để cá nhân hóa ứng dụng."
        )
    }

    static var nicknameTitle: String {
        L10n.text(
            en: "What should we call you?",
            ko: "어떻게 불러드릴까요?",
            ja: "何とお呼びしましょうか？",
            deDE: "Wie sollen wir dich nennen?",
            frFR: "Comment devons-nous vous appeler ?",
            ptBR: "Como devemos chamar você?",
            vi: "Chúng tôi nên gọi bạn là gì?"
        )
    }

    static var nicknameDescription: String {
        L10n.text(
            en: "Enter a nickname to use in the app.",
            ko: "앱에서 사용할 닉네임을 입력해주세요.",
            ja: "アプリで使うニックネームを入力してください。",
            deDE: "Gib einen Spitznamen für die App ein.",
            frFR: "Saisissez un pseudo à utiliser dans l’app.",
            ptBR: "Digite um apelido para usar no app.",
            vi: "Nhập biệt danh bạn muốn dùng trong ứng dụng."
        )
    }

    static var nicknamePlaceholder: String {
        L10n.text(
            en: "Nickname",
            ko: "닉네임",
            ja: "ニックネーム",
            deDE: "Spitzname",
            frFR: "Pseudo",
            ptBR: "Apelido",
            vi: "Biệt danh"
        )
    }

    static var nicknameValidation: String {
        L10n.text(
            en: "Enter 1–20 characters.",
            ko: "닉네임은 1~20자로 입력해주세요.",
            ja: "1～20文字で入力してください。",
            deDE: "Gib 1–20 Zeichen ein.",
            frFR: "Saisissez entre 1 et 20 caractères.",
            ptBR: "Digite de 1 a 20 caracteres.",
            vi: "Nhập từ 1–20 ký tự."
        )
    }

    static var notificationsTitle: String {
        L10n.text(
            en: "Stay in the loop",
            ko: "중요한 소식을 놓치지 않도록",
            ja: "大切なお知らせを見逃さないために",
            deDE: "Bleib auf dem Laufenden",
            frFR: "Restez informé",
            ptBR: "Fique por dentro",
            vi: "Đừng bỏ lỡ thông tin quan trọng"
        )
    }

    static var notificationsDescription: String {
        L10n.text(
            en: "Allow notifications so the app can let you know when it matters.",
            ko: "알림을 허용하면 필요한 순간에 알려드릴 수 있어요.",
            ja: "通知を許可すると、必要なタイミングでお知らせできます。",
            deDE: "Erlaube Benachrichtigungen, damit die App dich rechtzeitig informieren kann.",
            frFR: "Autorisez les notifications pour être alerté au bon moment.",
            ptBR: "Permita notificações para receber avisos quando for importante.",
            vi: "Cho phép thông báo để ứng dụng nhắc bạn khi cần thiết."
        )
    }

    static var advertisingTitle: String {
        L10n.text(
            en: "Help us improve the app",
            ko: "더 나은 앱을 만들기 위해",
            ja: "より良いアプリのために",
            deDE: "Hilf uns, die App zu verbessern",
            frFR: "Aidez-nous à améliorer l’app",
            ptBR: "Ajude-nos a melhorar o app",
            vi: "Giúp chúng tôi cải thiện ứng dụng"
        )
    }

    static var advertisingDescription: String {
        L10n.text(
            en: "Review advertising privacy choices and select what works for you.",
            ko: "광고 개인정보 설정을 확인하고 원하는 방식으로 선택해주세요.",
            ja: "広告のプライバシー設定を確認し、自分に合う方法を選びましょう。",
            deDE: "Prüfe die Datenschutzoptionen für Werbung und wähle, was für dich passt.",
            frFR: "Consultez les choix de confidentialité publicitaire et sélectionnez ce qui vous convient.",
            ptBR: "Confira as opções de privacidade dos anúncios e escolha o que funciona para você.",
            vi: "Xem các lựa chọn riêng tư cho quảng cáo và chọn cách phù hợp với bạn."
        )
    }

    static var next: String {
        L10n.text(en: "Next", ko: "다음", ja: "次へ", deDE: "Weiter", frFR: "Suivant", ptBR: "Avançar", vi: "Tiếp theo")
    }

    static var start: String {
        L10n.text(en: "Get started", ko: "시작하기", ja: "始める", deDE: "Loslegen", frFR: "Commencer", ptBR: "Começar", vi: "Bắt đầu")
    }

    static var allowNotifications: String {
        L10n.text(en: "Allow notifications", ko: "알림 허용하기", ja: "通知を許可", deDE: "Benachrichtigungen erlauben", frFR: "Autoriser les notifications", ptBR: "Permitir notificações", vi: "Cho phép thông báo")
    }

    static var continueButton: String {
        L10n.text(en: "Continue", ko: "계속", ja: "続ける", deDE: "Fortfahren", frFR: "Continuer", ptBR: "Continuar", vi: "Tiếp tục")
    }

    static var replayTitle: String {
        L10n.text(en: "Welcome back", ko: "다시 만나서 반가워요", ja: "おかえりなさい", deDE: "Willkommen zurück", frFR: "Bon retour", ptBR: "Que bom ter você de volta", vi: "Chào mừng bạn trở lại")
    }
}
