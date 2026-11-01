package com.boogios.template.core.foundation

import android.content.Context
import com.boogios.template.core.analytics.MixpanelManager
import com.boogios.template.data.premium.*
import com.boogios.template.data.settings.*

class AppDependencies(
    context: Context,
    isolated: Boolean = AppRuntime.isIsolated,
    settingsRepository: PreferenceRepository = if (isolated) MemoryPreferences() else DataStorePreferences.settings(context),
    onboardingRepository: PreferenceRepository = if (isolated) MemoryPreferences() else DataStorePreferences.onboarding(context),
    billing: BillingGateway = if (isolated) PreviewBillingGateway() else PlayBillingGateway(context),
    val advertising: AdvertisingClient = if (isolated) AdvertisingClient.Disabled else AdvertisingClient.Live,
    val notifications: NotificationClient = if (isolated) NotificationClient.Disabled else NotificationClient.Live,
    val analytics: AnalyticsClient = if (isolated) AnalyticsClient.Disabled else object : AnalyticsClient {
        override fun track(event: AppEvent) = MixpanelManager.track(event.wireName)
        override fun setNickname(nickname: String) = MixpanelManager.setUserProperties(nickname)
    },
) {
    val settings = SettingsStore(settingsRepository)
    val onboarding = OnboardingStore(onboardingRepository, analytics)
    val premium = PremiumStore(billing, analytics)
    fun prepare() { premium.prepare() }
}
