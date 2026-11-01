package com.boogios.template.core.foundation

import androidx.compose.runtime.staticCompositionLocalOf
import android.app.Activity
import com.boogios.template.core.admob.AdMobManager
import com.boogios.template.core.admob.RewardedAdService
import com.boogios.template.data.settings.NotificationPermissionManager

val LocalAdvertisingClient = staticCompositionLocalOf<AdvertisingClient> { AdvertisingClient.Disabled }

/** Activities are call arguments only; application-scoped clients never retain them. */
interface AdvertisingClient {
    val privacyOptionsRequired: Boolean
    fun consent(activity: Activity, completion: () -> Unit)
    fun privacyOptions(activity: Activity)
    fun reward(activity: Activity, completion: (RewardedAdOutcome) -> Unit)

    object Live : AdvertisingClient {
        override val privacyOptionsRequired get() = AdMobManager.isPrivacyOptionsRequired
        override fun consent(activity: Activity, completion: () -> Unit) = AdMobManager.requestConsentForOnboarding(activity, completion)
        override fun privacyOptions(activity: Activity) = AdMobManager.presentPrivacyOptions(activity)
        override fun reward(activity: Activity, completion: (RewardedAdOutcome) -> Unit) = RewardedAdService.presentResult(activity, com.boogios.template.core.config.AppConfig.adMobRewardId, completion)
    }
    object Disabled : AdvertisingClient {
        override val privacyOptionsRequired = false
        override fun consent(activity: Activity, completion: () -> Unit) = completion()
        override fun privacyOptions(activity: Activity) = Unit
        override fun reward(activity: Activity, completion: (RewardedAdOutcome) -> Unit) = completion(RewardedAdOutcome.FAILED)
    }
}

fun interface NotificationClient {
    fun shouldRequest(activity: Activity): Boolean
    companion object {
        val Live = NotificationClient { NotificationPermissionManager.shouldRequest(it) }
        val Disabled = NotificationClient { false }
    }
}
