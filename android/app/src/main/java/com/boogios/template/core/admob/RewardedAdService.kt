package com.boogios.template.core.admob

import android.app.Activity
import com.boogios.template.core.config.AppConfig
import com.google.android.gms.ads.AdError
import com.google.android.gms.ads.AdRequest
import com.google.android.gms.ads.FullScreenContentCallback
import com.google.android.gms.ads.LoadAdError
import com.google.android.gms.ads.rewarded.RewardItem
import com.google.android.gms.ads.rewarded.RewardedAd
import com.google.android.gms.ads.rewarded.RewardedAdLoadCallback

object RewardedAdService {
    private var rewardedAd: RewardedAd? = null
    private var isLoading = false
    private var isShowing = false
    private var pendingPresentation: ((RewardedAd?) -> Unit)? = null

    fun preload(activity: Activity, adUnitId: String = AppConfig.adMobRewardId) {
        if (!AppConfig.hasAdMobRewardConfiguration || !AdMobManager.canRequestAds || rewardedAd != null || isLoading) return
        load(activity, adUnitId)
    }

    fun present(
        activity: Activity,
        adUnitId: String = AppConfig.adMobRewardId,
        onEarnReward: () -> Unit,
        onDismiss: (() -> Unit)? = null,
        onFail: (() -> Unit)? = null,
    ) {
        if (!AppConfig.hasAdMobRewardConfiguration || !AdMobManager.canRequestAds) {
            onFail?.invoke()
            onDismiss?.invoke()
            return
        }
        if (isShowing) return

        val loadedAd = rewardedAd
        if (loadedAd != null) {
            showLoadedAd(activity, adUnitId, loadedAd, onEarnReward, onDismiss, onFail)
        } else {
            pendingPresentation = { ad ->
                if (ad == null) {
                    onFail?.invoke()
                } else {
                    showLoadedAd(activity, adUnitId, ad, onEarnReward, onDismiss, onFail)
                }
            }
            load(activity, adUnitId)
        }
    }

    private fun load(
        activity: Activity,
        adUnitId: String,
        completion: ((RewardedAd?) -> Unit)? = null,
    ) {
        if (isLoading) return
        isLoading = true

        RewardedAd.load(
            activity,
            adUnitId,
            AdRequest.Builder().build(),
            object : RewardedAdLoadCallback() {
                override fun onAdLoaded(ad: RewardedAd) {
                    isLoading = false
                    rewardedAd = ad
                    val pending = pendingPresentation
                    pendingPresentation = null
                    (completion ?: pending)?.invoke(ad)
                }

                override fun onAdFailedToLoad(error: LoadAdError) {
                    isLoading = false
                    rewardedAd = null
                    val pending = pendingPresentation
                    pendingPresentation = null
                    (completion ?: pending)?.invoke(null)
                }
            },
        )
    }

    private fun showLoadedAd(
        activity: Activity,
        adUnitId: String,
        ad: RewardedAd,
        onEarnReward: () -> Unit,
        onDismiss: (() -> Unit)?,
        onFail: (() -> Unit)?,
    ) {
        if (isShowing) return
        rewardedAd = null
        isShowing = true

        ad.fullScreenContentCallback = object : FullScreenContentCallback() {
            override fun onAdDismissedFullScreenContent() {
                isShowing = false
                onDismiss?.invoke()
                preload(activity, adUnitId)
            }

            override fun onAdFailedToShowFullScreenContent(error: AdError) {
                isShowing = false
                onFail?.invoke()
                onDismiss?.invoke()
                preload(activity, adUnitId)
            }
        }

        ad.show(activity) { _: RewardItem -> onEarnReward() }
    }
}
