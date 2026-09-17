package com.boogios.template.data.settings

import androidx.annotation.StringRes
import androidx.appcompat.app.AppCompatDelegate
import androidx.core.os.LocaleListCompat
import com.boogios.template.R

enum class AppLanguage(
    val localeTag: String,
    @get:StringRes val labelRes: Int,
) {
    SYSTEM("", R.string.language_system),
    ENGLISH_US("en-US", R.string.language_english_us),
    ENGLISH_GB("en-GB", R.string.language_english_gb),
    ENGLISH_CA("en-CA", R.string.language_english_ca),
    ENGLISH_AU("en-AU", R.string.language_english_au),
    KOREAN("ko", R.string.language_korean),
    JAPANESE("ja", R.string.language_japanese),
    GERMAN("de-DE", R.string.language_german),
    FRENCH("fr-FR", R.string.language_french),
    PORTUGUESE_BR("pt-BR", R.string.language_portuguese_br),
    VIETNAMESE("vi", R.string.language_vietnamese),
    ;

    companion object {
        val displayCases: List<AppLanguage> = values().toList()

        fun fromLocaleTag(tag: String): AppLanguage =
            values().firstOrNull { it.localeTag.equals(tag, ignoreCase = true) } ?: SYSTEM
    }
}

object AppLanguageManager {
    fun current(): AppLanguage {
        val tag = AppCompatDelegate.getApplicationLocales().toLanguageTags()
            .split(',')
            .firstOrNull()
            .orEmpty()
        return if (tag.isBlank()) AppLanguage.SYSTEM else AppLanguage.fromLocaleTag(tag)
    }

    fun set(language: AppLanguage) {
        val locales = if (language == AppLanguage.SYSTEM) {
            LocaleListCompat.getEmptyLocaleList()
        } else {
            LocaleListCompat.forLanguageTags(language.localeTag)
        }
        AppCompatDelegate.setApplicationLocales(locales)
    }
}
