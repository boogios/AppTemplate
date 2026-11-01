package com.boogios.template

import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertSame
import org.junit.Assert.assertEquals
import com.boogios.template.core.foundation.LoadState
import com.boogios.template.data.settings.ThemeMode
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class TemplateSmokeTest {
    @get:Rule
    val composeTestRule = createAndroidComposeRule<MainActivity>()

    @Test
    fun activityRecreationKeepsServicesAndSavedTheme() {
        val original = (composeTestRule.activity.application as AppTemplateAndroidApplication).dependencies
        composeTestRule.waitUntil(5000) { original.settings.loadState == LoadState.READY }
        composeTestRule.runOnIdle { original.settings.setTheme(ThemeMode.DARK) }
        composeTestRule.waitUntil(5000) { original.settings.themeMode == ThemeMode.DARK }
        composeTestRule.activityRule.scenario.recreate()
        composeTestRule.runOnIdle {
            val restored = (composeTestRule.activity.application as AppTemplateAndroidApplication).dependencies
            assertSame(original, restored)
            assertSame(original.premium, composeTestRule.activity.premiumStore)
            assertEquals(ThemeMode.DARK, restored.settings.themeMode)
        }
    }

    @Test
    fun settingsSmokeFlowShowsCoreRowsWithoutNotifications() {
        composeTestRule.waitUntil(5000) { composeTestRule.activity.onboardingStore.loadState == LoadState.READY }
        composeTestRule.activity.runOnUiThread {
            composeTestRule.activity.onboardingStore.complete("Test User")
        }
        composeTestRule.waitUntil(5000) { composeTestRule.activity.onboardingStore.hasCompletedOnboarding }
        composeTestRule.onNodeWithTag("tab.settings")
            .assertExists()
            .performClick()

        composeTestRule.onNodeWithTag("settings.language").assertExists()
        composeTestRule.onNodeWithTag("settings.theme").assertExists()
        composeTestRule.onNodeWithTag("settings.developer-apps").assertExists()
        composeTestRule.onNodeWithTag("settings.review").assertExists()
        composeTestRule.onNodeWithTag("settings.replay-onboarding").assertExists()
        composeTestRule.onNodeWithTag("settings.support").assertExists()
        composeTestRule.onNodeWithTag("settings.notifications").assertDoesNotExist()

        saveQAScreenshot("settings")
        composeTestRule.onNodeWithTag("settings.premium").assertExists().performClick()
        composeTestRule.onNodeWithTag("premium.close").assertExists()
        composeTestRule.onNodeWithTag("premium.unavailable").assertExists()
        saveQAScreenshot("paywall-empty")
        composeTestRule.onNodeWithTag("premium.close").performClick()
    }
}
