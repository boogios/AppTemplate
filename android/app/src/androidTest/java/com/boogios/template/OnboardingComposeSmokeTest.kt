package com.boogios.template

import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.performScrollTo
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextInput
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.boogios.template.data.settings.ThemeMode
import com.boogios.template.features.onboarding.OnboardingMode
import com.boogios.template.features.onboarding.OnboardingScreen
import com.boogios.template.core.ui.theme.AppTemplateTheme
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class OnboardingComposeSmokeTest {
    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun onboardingSmokeFlowReachesHomeCallback() {
        var completedNickname = ""
        composeTestRule.setContent {
            AppTemplateTheme(themeMode = ThemeMode.SYSTEM) {
                OnboardingScreen(
                    mode = OnboardingMode.INITIAL,
                    onComplete = { completedNickname = it },
                    onReplayDismiss = {},
                    onRequestNotifications = { it() },
                    onRequestAdPrivacy = { it() },
                )
            }
        }

        saveQAScreenshot("onboarding")
        composeTestRule.onNodeWithTag("onboarding.next").performScrollTo().performClick()
        composeTestRule.onNodeWithTag("onboarding.next").performScrollTo().performClick()
        composeTestRule.onNodeWithTag("onboarding.nickname").performTextInput(" Boogi ")
        composeTestRule.onNodeWithTag("onboarding.next").performScrollTo().performClick()
        composeTestRule.onNodeWithTag("onboarding.next").performScrollTo().performClick()
        composeTestRule.onNodeWithTag("onboarding.start").performScrollTo().performClick()

        assertEquals("Boogi", completedNickname)
    }

    @Test
    fun largeTextGermanDarkReplayButtonStaysReachable() {
        composeTestRule.setContent {
            val context = androidx.compose.ui.platform.LocalContext.current
            val config = android.content.res.Configuration(context.resources.configuration).apply { setLocale(java.util.Locale.GERMAN) }
            val density = androidx.compose.ui.platform.LocalDensity.current
            androidx.compose.runtime.CompositionLocalProvider(
                androidx.compose.ui.platform.LocalContext provides context.createConfigurationContext(config),
                androidx.compose.ui.platform.LocalConfiguration provides config,
                androidx.compose.ui.platform.LocalDensity provides androidx.compose.ui.unit.Density(density.density, 2f),
            ) {
                AppTemplateTheme(themeMode = ThemeMode.DARK) {
                    OnboardingScreen(mode = OnboardingMode.REPLAY, onComplete = {}, onReplayDismiss = {}, onRequestNotifications = { it() }, onRequestAdPrivacy = { it() })
                }
            }
        }
        composeTestRule.onNodeWithTag("onboarding.next").performScrollTo().assertIsDisplayed()
        saveQAScreenshot("onboarding-german-large-dark")
        composeTestRule.onNodeWithTag("onboarding.next").performClick()
        composeTestRule.onNodeWithTag("onboarding.start").performScrollTo().assertIsDisplayed()
    }

    @Test
    fun onboardingReplaySmokeFlowShowsIntroductionOnly() {
        var didDismiss = false
        composeTestRule.setContent {
            AppTemplateTheme(themeMode = ThemeMode.SYSTEM) {
                OnboardingScreen(
                    mode = OnboardingMode.REPLAY,
                    initialNickname = "Saved name",
                    onComplete = {},
                    onReplayDismiss = { didDismiss = true },
                    onRequestNotifications = { it() },
                    onRequestAdPrivacy = { it() },
                )
            }
        }

        composeTestRule.onNodeWithTag("onboarding.next").performScrollTo().performClick()
        composeTestRule.onNodeWithTag("onboarding.start").performScrollTo().performClick()

        assertEquals(true, didDismiss)
    }
}
