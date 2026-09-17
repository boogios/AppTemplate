package com.boogios.template

import android.Manifest
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import com.boogios.template.core.admob.AdMobManager
import com.boogios.template.data.settings.NotificationPermissionManager
import com.boogios.template.data.settings.OnboardingStore
import com.boogios.template.data.settings.SettingsStore
import com.boogios.template.core.review.InAppReviewManager
import com.boogios.template.data.premium.PremiumStore
import com.boogios.template.navigation.AppRoot
import com.boogios.template.core.ui.theme.AppTemplateTheme

class MainActivity : ComponentActivity() {
    lateinit var onboardingStore: OnboardingStore
        private set
    lateinit var premiumStore: PremiumStore
        private set
    private val inAppReviewManager by lazy { InAppReviewManager(applicationContext) }

    private var pendingNotificationCompletion: (() -> Unit)? = null
    private val notificationPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission(),
    ) {
        NotificationPermissionManager.markDecided(this)
        pendingNotificationCompletion?.invoke()
        pendingNotificationCompletion = null
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        onboardingStore = OnboardingStore(applicationContext)
        premiumStore = PremiumStore(applicationContext)
        setContent {
            val settingsStore = remember { SettingsStore(applicationContext) }
            DisposableEffect(settingsStore) {
                onDispose {
                    settingsStore.close()
                    onboardingStore.close()
                    premiumStore.close()
                }
            }
            AppTemplateTheme(themeMode = settingsStore.themeMode) {
                LaunchedEffect(onboardingStore.hasCompletedOnboarding) {
                    if (onboardingStore.hasCompletedOnboarding) {
                        AdMobManager.start(this@MainActivity)
                    }
                }
                Surface(modifier = Modifier.fillMaxSize()) {
                    AppRoot(
                        settingsStore = settingsStore,
                        onboardingStore = onboardingStore,
                        premiumStore = premiumStore,
                        isPrivacyOptionsRequired = AdMobManager.isPrivacyOptionsRequired,
                        onOpenPrivacyOptions = { AdMobManager.presentPrivacyOptions(this@MainActivity) },
                        onRequestNotifications = ::requestNotificationPermission,
                        onRequestAdPrivacy = { onFinished ->
                            AdMobManager.requestConsentForOnboarding(this@MainActivity, onFinished)
                        },
                        onRequestReview = { inAppReviewManager.requestReview(this@MainActivity) },
                    )
                }
            }
        }
    }

    private fun requestNotificationPermission(onFinished: () -> Unit) {
        if (!NotificationPermissionManager.shouldRequest(this)) {
            onFinished()
            return
        }
        pendingNotificationCompletion = onFinished
        notificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
    }
}
