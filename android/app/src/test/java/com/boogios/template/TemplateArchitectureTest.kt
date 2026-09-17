package com.boogios.template

import com.boogios.template.core.config.AppConfig
import com.boogios.template.data.settings.AppLanguage
import com.boogios.template.data.settings.OnboardingStore
import com.boogios.template.data.settings.ThemeMode
import com.boogios.template.data.premium.PremiumStore
import org.junit.Assert.assertEquals
import org.junit.Test

class TemplateArchitectureTest {
    @Test
    fun defaultThemeIsSystem() {
        assertEquals(ThemeMode.SYSTEM, ThemeMode.fromStorage(null))
    }

    @Test
    fun tenTemplateLanguagesRemainAvailable() {
        assertEquals(10, AppLanguage.displayCases.count { it != AppLanguage.SYSTEM })
        assertEquals(AppLanguage.KOREAN, AppLanguage.fromLocaleTag("ko"))
        assertEquals(AppLanguage.PORTUGUESE_BR, AppLanguage.fromLocaleTag("pt-BR"))
    }

    @Test
    fun developerAppsUrlIsConfigured() {
        assertEquals("https://boogios-studio.vercel.app/", AppConfig.developerAppsUrl)
    }

    @Test
    fun premiumProductIdsAreConfiguredForTemplateReplacement() {
        assertEquals(
            listOf(
                "com.boogios.template.premium.yearly",
                "com.boogios.template.premium.monthly",
                "com.boogios.template.premium.lifetime",
            ),
            PremiumStore.productIds,
        )
    }

    @Test
    fun onboardingNicknameIsTrimmedAndLimitedToTwentyCharacters() {
        assertEquals(true, OnboardingStore.isValidNickname(" Boogi "))
        assertEquals(false, OnboardingStore.isValidNickname("   "))
        assertEquals(false, OnboardingStore.isValidNickname("123456789012345678901"))
    }
}
