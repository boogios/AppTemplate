package com.boogios.template.navigation

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.platform.testTag
import com.boogios.template.R
import com.boogios.template.data.settings.OnboardingStore
import com.boogios.template.data.settings.SettingsStore
import com.boogios.template.data.premium.PremiumStore
import com.boogios.template.features.home.HomeScreen
import com.boogios.template.features.onboarding.OnboardingMode
import com.boogios.template.features.onboarding.OnboardingScreen
import com.boogios.template.features.premium.PremiumPaywallDialog
import com.boogios.template.features.settings.SettingsScreen
import com.boogios.template.core.ui.theme.BoogiosThemeTokens
import androidx.compose.ui.unit.dp

@Composable
fun AppRoot(
    settingsStore: SettingsStore,
    onboardingStore: OnboardingStore,
    premiumStore: PremiumStore,
    isPrivacyOptionsRequired: Boolean,
    onOpenPrivacyOptions: () -> Unit,
    onRequestNotifications: (onFinished: () -> Unit) -> Unit,
    onRequestAdPrivacy: (onFinished: () -> Unit) -> Unit,
    onRequestReview: () -> Unit,
) {
    if (!onboardingStore.hasCompletedOnboarding) {
        OnboardingScreen(
            mode = OnboardingMode.INITIAL,
            onComplete = { onboardingStore.complete(it) },
            onReplayDismiss = {},
            onRequestNotifications = onRequestNotifications,
            onRequestAdPrivacy = onRequestAdPrivacy,
        )
        return
    }

    if (onboardingStore.isReplayPresented) {
        OnboardingScreen(
            mode = OnboardingMode.REPLAY,
            initialNickname = onboardingStore.nickname,
            onComplete = {},
            onReplayDismiss = onboardingStore::dismissReplay,
            onRequestNotifications = { it() },
            onRequestAdPrivacy = { it() },
        )
        return
    }

    var selectedTab by rememberSaveable { mutableIntStateOf(0) }
    var isPremiumPresented by rememberSaveable { mutableStateOf(false) }

    Scaffold(
        containerColor = BoogiosThemeTokens.colors.gray1,
        bottomBar = {
            NavigationBar(
                containerColor = BoogiosThemeTokens.colors.gray1,
                tonalElevation = 0.dp,
            ) {
                NavigationBarItem(
                    selected = selectedTab == 0,
                    onClick = { selectedTab = 0 },
                    modifier = Modifier.testTag("tab.home"),
                    icon = { Icon(Icons.Default.Home, contentDescription = null) },
                    label = { Text(stringResource(R.string.home_tab)) },
                    colors = NavigationBarItemDefaults.colors(
                        selectedIconColor = MaterialTheme.colorScheme.primary,
                        selectedTextColor = MaterialTheme.colorScheme.primary,
                        indicatorColor = MaterialTheme.colorScheme.primaryContainer,
                        unselectedIconColor = MaterialTheme.colorScheme.onSurfaceVariant,
                        unselectedTextColor = MaterialTheme.colorScheme.onSurfaceVariant,
                    ),
                )
                NavigationBarItem(
                    selected = selectedTab == 1,
                    onClick = { selectedTab = 1 },
                    modifier = Modifier.testTag("tab.settings"),
                    icon = { Icon(Icons.Default.Settings, contentDescription = null) },
                    label = { Text(stringResource(R.string.settings_tab)) },
                    colors = NavigationBarItemDefaults.colors(
                        selectedIconColor = MaterialTheme.colorScheme.primary,
                        selectedTextColor = MaterialTheme.colorScheme.primary,
                        indicatorColor = MaterialTheme.colorScheme.primaryContainer,
                        unselectedIconColor = MaterialTheme.colorScheme.onSurfaceVariant,
                        unselectedTextColor = MaterialTheme.colorScheme.onSurfaceVariant,
                    ),
                )
            }
        },
    ) { innerPadding ->
        when (selectedTab) {
            0 -> HomeScreen(modifier = Modifier.padding(innerPadding))
            else -> SettingsScreen(
                modifier = Modifier.padding(innerPadding),
                settingsStore = settingsStore,
                premiumStore = premiumStore,
                isPrivacyOptionsRequired = isPrivacyOptionsRequired,
                onOpenPrivacyOptions = onOpenPrivacyOptions,
                onReplayOnboarding = onboardingStore::presentReplay,
                onOpenPremium = { isPremiumPresented = true },
                onRequestReview = onRequestReview,
            )
        }
    }

    if (isPremiumPresented) {
        PremiumPaywallDialog(premiumStore = premiumStore, onDismiss = { isPremiumPresented = false })
    }
}
