package com.boogios.template

import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class TemplateSmokeTest {
    @get:Rule
    val composeTestRule = createAndroidComposeRule<MainActivity>()

    @Test
    fun settingsSmokeFlowShowsCoreRowsWithoutNotifications() {
        composeTestRule.activity.runOnUiThread {
            composeTestRule.activity.onboardingStore.complete("Test User")
        }
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

        composeTestRule.onNodeWithTag("settings.premium").assertExists().performClick()
        composeTestRule.onNodeWithTag("premium.close").assertExists()
        composeTestRule.onNodeWithTag("premium.unavailable").assertExists()
        composeTestRule.onNodeWithTag("premium.close").performClick()
    }
}
