package com.boogios.template.core.config

import com.boogios.template.BuildConfig

object AppConfig {
    const val appName = "AppTemplateAndroid"

    const val supportUrl = "https://www.instagram.com/dev._.boogios"
    const val developerAppsUrl = "https://boogios-studio.vercel.app/"
    const val termsUrl = "https://example.com/terms"
    const val privacyUrl = "https://example.com/privacy"

    // Replace these IDs with products created in Google Play Console.
    // The generator replaces the com.boogios.template prefix with the new application ID.
    const val premiumMonthlyProductId = "com.boogios.template.premium.monthly"
    const val premiumYearlyProductId = "com.boogios.template.premium.yearly"
    const val premiumLifetimeProductId = "com.boogios.template.premium.lifetime"

    val adMobAppId: String get() = BuildConfig.ADMOB_APP_ID.trim()
    val adMobBannerId: String get() = BuildConfig.ADMOB_BANNER_ID.trim()
    val adMobNativeId: String get() = BuildConfig.ADMOB_NATIVE_ID.trim()
    val adMobNativeRequestId: String
        get() = if (BuildConfig.DEBUG && hasAdMobConfiguration) {
            "ca-app-pub-3940256099942544/2247696110"
        } else {
            adMobNativeId
        }
    val adMobRewardId: String get() = BuildConfig.ADMOB_REWARD_ID.trim()
    val adMobTestDevice: String get() = BuildConfig.ADMOB_TEST_DEVICE.trim()
    val mixpanelToken: String get() = BuildConfig.MIXPANEL_TOKEN.trim()
    val supabaseUrl: String get() = BuildConfig.SUPABASE_URL.trim().trimEnd('/')
    val supabasePublishableKey: String get() = BuildConfig.SUPABASE_PUBLISHABLE_KEY.trim()
    val supabaseRedirectUrl: String get() = BuildConfig.SUPABASE_REDIRECT_URL.trim()

    val hasAdMobConfiguration: Boolean
        get() = !isPlaceholder(adMobAppId)

    val hasAdMobBannerConfiguration: Boolean
        get() = hasAdMobConfiguration && !isPlaceholder(adMobBannerId)

    val hasAdMobNativeConfiguration: Boolean
        get() = hasAdMobConfiguration && !isPlaceholder(adMobNativeRequestId)

    val hasAdMobRewardConfiguration: Boolean
        get() = hasAdMobConfiguration && !isPlaceholder(adMobRewardId)

    val hasMixpanelConfiguration: Boolean
        get() = !isPlaceholder(mixpanelToken)

    val hasSupabaseConfiguration: Boolean
        get() = !isPlaceholder(supabaseUrl) && !isPlaceholder(supabasePublishableKey)

    private fun isPlaceholder(value: String): Boolean {
        val trimmed = value.trim()
        return trimmed.isEmpty() ||
            trimmed.startsWith("your_") ||
            trimmed.startsWith("ca-app-pub-000000") ||
            trimmed == "ca-app-pub-3940256099942544~3347511713" ||
            trimmed == "ca-app-pub-3940256099942544/6300978111" ||
            trimmed == "ca-app-pub-3940256099942544/2247696110" ||
            trimmed == "ca-app-pub-3940256099942544/5224354917" ||
            trimmed == "https://your-project-ref.supabase.co" ||
            trimmed == "com.example.app://auth-callback"
    }
}

fun openExternalUrl(context: android.content.Context, url: String): Boolean {
    return try {
        context.startActivity(
            android.content.Intent(
                android.content.Intent.ACTION_VIEW,
                android.net.Uri.parse(url),
            ),
        )
        true
    } catch (_: android.content.ActivityNotFoundException) {
        false
    }
}
