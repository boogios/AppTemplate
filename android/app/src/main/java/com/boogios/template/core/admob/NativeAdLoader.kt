package com.boogios.template.core.admob

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.boogios.template.core.config.AppConfig
import com.google.android.gms.ads.AdListener
import com.google.android.gms.ads.AdLoader
import com.google.android.gms.ads.AdRequest
import com.google.android.gms.ads.LoadAdError
import com.google.android.gms.ads.nativead.NativeAd

class NativeAdLoader(
    context: Context,
    private val adUnitId: String = AppConfig.adMobNativeRequestId,
) {
    private val applicationContext = context.applicationContext
    private var adLoader: AdLoader? = null
    private var isActive = false

    var nativeAd by mutableStateOf<NativeAd?>(null)
        private set
    var isLoading by mutableStateOf(false)
        private set
    var didFailToLoad by mutableStateOf(false)
        private set
    var lastErrorMessage by mutableStateOf<String?>(null)
        private set

    fun start() {
        if (isActive) return
        isActive = true
        nativeAd = null
        isLoading = false
        didFailToLoad = false
        lastErrorMessage = null
    }

    fun stop() {
        isActive = false
        nativeAd?.destroy()
        nativeAd = null
        isLoading = false
        didFailToLoad = false
        lastErrorMessage = null
        adLoader = null
    }

    fun loadAdIfNeeded() {
        if (!AppConfig.hasAdMobNativeConfiguration || !AdMobManager.canRequestAds || nativeAd != null || isLoading) return
        loadAd()
    }

    fun consumeCurrentAdAndPreloadNext() {
        nativeAd?.destroy()
        nativeAd = null
        loadAdIfNeeded()
    }

    private fun loadAd() {
        if (!isActive) start()
        if (!AppConfig.hasAdMobNativeConfiguration || !AdMobManager.canRequestAds || isLoading) return

        isLoading = true
        didFailToLoad = false
        lastErrorMessage = null

        adLoader = AdLoader.Builder(applicationContext, adUnitId)
            .forNativeAd { loadedAd ->
                if (!isActive) {
                    loadedAd.destroy()
                    return@forNativeAd
                }
                nativeAd?.destroy()
                nativeAd = loadedAd
                isLoading = false
                didFailToLoad = false
                lastErrorMessage = null
            }
            .withAdListener(object : AdListener() {
                override fun onAdFailedToLoad(error: LoadAdError) {
                    nativeAd = null
                    isLoading = false
                    didFailToLoad = true
                    lastErrorMessage = error.message
                }
            })
            .build()

        adLoader?.loadAd(AdRequest.Builder().build())
    }
}
