//
//  PremiumL10n.swift
//  AppTemplate
//

import Foundation

enum PremiumL10n {
    static var cardTitle: String { L10n.text(en: "Premium", ko: "프리미엄", ja: "プレミアム", deDE: "Premium", frFR: "Premium", ptBR: "Premium", vi: "Premium") }
    static var cardDescription: String { L10n.text(en: "Unlock the full app experience", ko: "앱의 모든 기능을 이용해보세요", ja: "アプリのすべての機能を解放", deDE: "Das volle App-Erlebnis freischalten", frFR: "Débloquez toute l'expérience", ptBR: "Desbloqueie toda a experiência", vi: "Mở khóa toàn bộ trải nghiệm") }
    static var cardActiveDescription: String { L10n.text(en: "Premium is active", ko: "프리미엄을 이용 중이에요", ja: "プレミアムを利用中", deDE: "Premium ist aktiv", frFR: "Premium est actif", ptBR: "O Premium está ativo", vi: "Premium đang hoạt động") }
    static var paywallTitle: String { L10n.text(en: "Make more with Premium", ko: "프리미엄으로 더 편리하게", ja: "プレミアムでもっと便利に", deDE: "Mehr mit Premium machen", frFR: "Allez plus loin avec Premium", ptBR: "Faça mais com o Premium", vi: "Làm được nhiều hơn với Premium") }
    static var paywallSubtitle: String { L10n.text(en: "Unlock the full experience and enjoy the app without limits.", ko: "모든 기능을 열고 더 편리하게 앱을 이용해보세요.", ja: "すべての機能を解放して、アプリをもっと便利に。", deDE: "Schalte alle Funktionen frei und nutze die App ohne Limits.", frFR: "Débloquez toutes les fonctions et profitez de l'app sans limites.", ptBR: "Desbloqueie todos os recursos e use o app sem limites.", vi: "Mở khóa mọi tính năng và dùng ứng dụng không giới hạn.") }
    static var benefitsTitle: String { L10n.text(en: "Premium benefits", ko: "프리미엄 혜택", ja: "プレミアムの特典", deDE: "Premium-Vorteile", frFR: "Avantages Premium", ptBR: "Benefícios Premium", vi: "Quyền lợi Premium") }
    static var benefitUnlimited: String { L10n.text(en: "Use premium features without limits", ko: "프리미엄 기능을 제한 없이 이용", ja: "プレミアム機能を無制限で利用", deDE: "Premium-Funktionen ohne Limits", frFR: "Fonctions Premium sans limites", ptBR: "Recursos Premium sem limites", vi: "Dùng tính năng Premium không giới hạn") }
    static var benefitAdFree: String { L10n.text(en: "A cleaner, ad-free experience", ko: "광고 없이 더 깔끔하게 이용", ja: "広告なしで快適に利用", deDE: "Ein werbefreies Erlebnis", frFR: "Une expérience sans publicité", ptBR: "Uma experiência sem anúncios", vi: "Trải nghiệm không quảng cáo") }
    static var benefitUpdates: String { L10n.text(en: "Future premium features included", ko: "앞으로 추가될 프리미엄 기능 포함", ja: "今後のプレミアム機能も含む", deDE: "Künftige Premium-Funktionen inklusive", frFR: "Les futures fonctions Premium incluses", ptBR: "Inclui futuros recursos Premium", vi: "Bao gồm tính năng Premium trong tương lai") }
    static var plansTitle: String { L10n.text(en: "Choose a plan", ko: "플랜을 선택해주세요", ja: "プランを選択", deDE: "Plan auswählen", frFR: "Choisir un forfait", ptBR: "Escolha um plano", vi: "Chọn gói") }
    static var monthly: String { L10n.text(en: "Monthly", ko: "월간 구독", ja: "月額プラン", deDE: "Monatlich", frFR: "Mensuel", ptBR: "Mensal", vi: "Hàng tháng") }
    static var yearly: String { L10n.text(en: "Yearly", ko: "연간 구독", ja: "年間プラン", deDE: "Jährlich", frFR: "Annuel", ptBR: "Anual", vi: "Hàng năm") }
    static var lifetime: String { L10n.text(en: "Lifetime", ko: "평생 이용권", ja: "買い切り", deDE: "Lebenslang", frFR: "À vie", ptBR: "Vitalício", vi: "Trọn đời") }
    static var recommended: String { L10n.text(en: "Best value", ko: "추천", ja: "おすすめ", deDE: "Empfohlen", frFR: "Recommandé", ptBR: "Recomendado", vi: "Đề xuất") }
    static var renewsUntilCancelled: String { L10n.text(en: "Renews until cancelled", ko: "해지 전까지 자동 갱신", ja: "解約するまで自動更新", deDE: "Verlängert sich bis zur Kündigung", frFR: "Renouvellement automatique", ptBR: "Renova até o cancelamento", vi: "Tự động gia hạn đến khi hủy") }
    static var lifetimeDescription: String { L10n.text(en: "One-time purchase", ko: "한 번 결제로 평생 이용", ja: "一度の購入で永久利用", deDE: "Einmaliger Kauf", frFR: "Achat unique", ptBR: "Compra única", vi: "Mua một lần") }
    static var purchase: String { L10n.text(en: "Get Premium", ko: "프리미엄 시작하기", ja: "プレミアムを始める", deDE: "Premium erhalten", frFR: "Obtenir Premium", ptBR: "Obter Premium", vi: "Mở khóa Premium") }
    static var restore: String { L10n.text(en: "Restore purchases", ko: "구매 복원", ja: "購入を復元", deDE: "Käufe wiederherstellen", frFR: "Restaurer les achats", ptBR: "Restaurar compras", vi: "Khôi phục giao dịch mua") }
    static var productsUnavailable: String { L10n.text(en: "Premium products are not available yet. Add the product IDs in App Store Connect first.", ko: "아직 프리미엄 상품을 준비 중이에요. 먼저 App Store Connect에 상품을 등록해주세요.", ja: "プレミアム商品はまだ利用できません。App Store Connectに商品を登録してください。", deDE: "Premium-Produkte sind noch nicht verfügbar. Registriere sie zuerst in App Store Connect.", frFR: "Les produits Premium ne sont pas encore disponibles. Ajoutez-les d'abord dans App Store Connect.", ptBR: "Os produtos Premium ainda não estão disponíveis. Cadastre-os primeiro no App Store Connect.", vi: "Sản phẩm Premium chưa khả dụng. Hãy thêm sản phẩm trong App Store Connect trước.") }
    static var purchaseSucceeded: String { L10n.text(en: "Premium is ready", ko: "프리미엄을 이용할 수 있어요", ja: "プレミアムを利用できます", deDE: "Premium ist bereit", frFR: "Premium est prêt", ptBR: "O Premium está pronto", vi: "Premium đã sẵn sàng") }
    static var purchasePending: String { L10n.text(en: "Your purchase is pending.", ko: "구매가 처리 중이에요.", ja: "購入を処理中です。", deDE: "Dein Kauf ist ausstehend.", frFR: "Votre achat est en attente.", ptBR: "Sua compra está pendente.", vi: "Giao dịch mua đang chờ xử lý.") }
    static var purchaseFailed: String { L10n.text(en: "The purchase could not be completed.", ko: "구매를 완료하지 못했어요.", ja: "購入を完了できませんでした。", deDE: "Der Kauf konnte nicht abgeschlossen werden.", frFR: "L'achat n'a pas pu être finalisé.", ptBR: "Não foi possível concluir a compra.", vi: "Không thể hoàn tất giao dịch mua.") }
    static var purchaseRestored: String { L10n.text(en: "Your purchase has been restored.", ko: "구매를 복원했어요.", ja: "購入を復元しました。", deDE: "Dein Kauf wurde wiederhergestellt.", frFR: "Votre achat a été restauré.", ptBR: "Sua compra foi restaurada.", vi: "Đã khôi phục giao dịch mua.") }
    static var nothingToRestore: String { L10n.text(en: "There is no previous purchase to restore.", ko: "복원할 구매 내역이 없어요.", ja: "復元できる購入履歴がありません。", deDE: "Keine früheren Käufe zum Wiederherstellen.", frFR: "Aucun achat précédent à restaurer.", ptBR: "Não há compras anteriores para restaurar.", vi: "Không có giao dịch mua trước đây để khôi phục.") }
    static var restoreFailed: String { L10n.text(en: "Purchases could not be restored.", ko: "구매를 복원하지 못했어요.", ja: "購入を復元できませんでした。", deDE: "Käufe konnten nicht wiederhergestellt werden.", frFR: "Impossible de restaurer les achats.", ptBR: "Não foi possível restaurar as compras.", vi: "Không thể khôi phục giao dịch mua.") }
    static var active: String { L10n.text(en: "Premium is active", ko: "프리미엄 이용 중", ja: "プレミアム利用中", deDE: "Premium ist aktiv", frFR: "Premium est actif", ptBR: "O Premium está ativo", vi: "Premium đang hoạt động") }
    static var activeDescription: String { L10n.text(en: "You already have access to premium features.", ko: "프리미엄 기능을 이용할 수 있어요.", ja: "プレミアム機能をご利用いただけます。", deDE: "Du hast bereits Zugriff auf Premium-Funktionen.", frFR: "Vous avez déjà accès aux fonctions Premium.", ptBR: "Você já tem acesso aos recursos Premium.", vi: "Bạn đã có quyền truy cập các tính năng Premium.") }

    static func productTitle(_ productID: String, fallback: String) -> String {
        switch productID {
        case AppConfig.premiumMonthlyProductID: return monthly
        case AppConfig.premiumYearlyProductID: return yearly
        case AppConfig.premiumLifetimeProductID: return lifetime
        default: return fallback
        }
    }
}
