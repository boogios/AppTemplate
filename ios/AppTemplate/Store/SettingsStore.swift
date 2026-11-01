import Foundation
import SwiftUI

@MainActor
final class SettingsStore: ObservableObject {
    @Published private(set) var selectedLanguageRaw = AppLanguage.system.rawValue
    @Published private(set) var selectedThemeRaw = AppTheme.system.rawValue
    @Published private(set) var loadState: LoadState = .loading
    @Published private(set) var saveFailed = false
    @Published var toastMessage: String?
    private let preferences: PreferencesClient
    private var retrySave: (() -> Void)?

    init(preferences: PreferencesClient? = nil) { self.preferences = preferences ?? .defaults(.standard); reload() }
    var selectedLanguage: AppLanguage { AppLanguage(rawValue: selectedLanguageRaw) ?? .system }
    var selectedTheme: AppTheme { AppTheme(rawValue: selectedThemeRaw) ?? .system }
    func reload() {
        loadState = .loading
        do {
            let language = try preferences.string(AppLanguage.storageKey, fallback: AppLanguage.system.rawValue)
            let theme = try preferences.string("appTheme", fallback: AppTheme.system.rawValue)
            selectedLanguageRaw = language; selectedThemeRaw = theme; loadState = .ready
        } catch { loadState = .failed }
    }
    func setLanguage(_ language: AppLanguage) {
        save(key: AppLanguage.storageKey, value: language.rawValue) { [weak self] in self?.selectedLanguageRaw = language.rawValue }
    }
    func setTheme(_ theme: AppTheme) {
        save(key: "appTheme", value: theme.rawValue) { [weak self] in self?.selectedThemeRaw = theme.rawValue }
    }
    func retry() { if let retrySave { retrySave() } else { reload() } }
    private func save(key: String, value: String, apply: @escaping () -> Void) {
        guard loadState == .ready else { return }
        do {
            try preferences.write([key: value]); apply(); saveFailed = false; retrySave = nil
            toastMessage = key == "appTheme" ? MyPageL10n.themeUpdatedToast : MyPageL10n.languageUpdatedToast
        } catch {
            saveFailed = true
            retrySave = { [weak self] in self?.save(key: key, value: value, apply: apply) }
        }
    }
}
