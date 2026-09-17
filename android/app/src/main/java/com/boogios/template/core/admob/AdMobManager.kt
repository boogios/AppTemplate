package com.boogios.template.core.admob

import android.app.Activity
import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.boogios.template.core.config.AppConfig
import com.boogios.template.BuildConfig
import com.google.android.gms.ads.MobileAds
import com.google.android.gms.ads.RequestConfiguration
import com.google.android.ump.ConsentInformation
import com.google.android.ump.ConsentRequestParameters
import com.google.android.ump.UserMessagingPlatform

object AdMobManager {
    var canRequestAds by mutableStateOf(false)
        private set

    var isPrivacyOptionsRequired by mutableStateOf(false)
        private set

    private var consentInformation: ConsentInformation? = null
    private var didRequestConsent = false
    private var didStartAds = false

    fun start(activity: Activity) {
        requestConsentForOnboarding(activity) {}
    }

    fun requestConsentForOnboarding(activity: Activity, onFinished: () -> Unit) {
        if (!AppConfig.hasAdMobConfiguration || didRequestConsent) {
            onFinished()
            return
        }
        didRequestConsent = true

        if (BuildConfig.DEBUG && AppConfig.adMobTestDevice.isNotBlank()) {
            MobileAds.setRequestConfiguration(
                RequestConfiguration.Builder()
                    .setTestDeviceIds(listOf(AppConfig.adMobTestDevice))
                    .build(),
            )
        }

        val information = UserMessagingPlatform.getConsentInformation(activity.applicationContext)
        consentInformation = information
        information.requestConsentInfoUpdate(
            activity,
            ConsentRequestParameters.Builder().build(),
            {
                refreshConsentState(information)
                UserMessagingPlatform.loadAndShowConsentFormIfRequired(activity) {
                    refreshConsentState(information)
                    startMobileAdsIfAllowed(activity.applicationContext)
                    onFinished()
                }
            },
            {
                refreshConsentState(information)
                startMobileAdsIfAllowed(activity.applicationContext)
                onFinished()
            },
        )
    }

    fun presentPrivacyOptions(activity: Activity) {
        val information = consentInformation ?: return
        UserMessagingPlatform.showPrivacyOptionsForm(activity) {
            refreshConsentState(information)
            startMobileAdsIfAllowed(activity.applicationContext)
        }
    }

    private fun refreshConsentState(information: ConsentInformation) {
        canRequestAds = information.canRequestAds()
        isPrivacyOptionsRequired = information.privacyOptionsRequirementStatus ==
            ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED
    }

    private fun startMobileAdsIfAllowed(context: Context) {
        if (!canRequestAds || didStartAds) return
        didStartAds = true
        MobileAds.initialize(context.applicationContext)
    }
}
