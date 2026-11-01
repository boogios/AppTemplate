package com.boogios.template.core.admob

import android.app.Activity
import com.boogios.template.core.config.AppConfig
import com.boogios.template.core.foundation.*
import com.boogios.template.core.analytics.MixpanelManager
import com.google.android.gms.ads.*
import com.google.android.gms.ads.rewarded.RewardedAd
import com.google.android.gms.ads.rewarded.RewardedAdLoadCallback
import java.lang.ref.WeakReference

object RewardedAdService {
    private var rewardedAd: RewardedAd? = null
    private var loadedId: String? = null
    private var loadingId: String? = null
    private var pending: ((RewardedAd?) -> Unit)? = null
    private val requests = RewardGate()
    private val attempt get() = requests.current
    private val available: Boolean get() = !AppRuntime.isIsolated && AppConfig.hasAdMobRewardConfiguration && AdMobManager.canRequestAds

    fun preload(activity: Activity, adUnitId: String = AppConfig.adMobRewardId) {
        if (available && rewardedAd == null && loadingId == null) load(activity, adUnitId)
    }
    fun present(activity: Activity, adUnitId: String = AppConfig.adMobRewardId,
                onEarnReward: () -> Unit, onDismiss: (() -> Unit)? = null, onFail: (() -> Unit)? = null) {
        presentResult(activity, adUnitId) {
            when (it) {
                RewardedAdOutcome.REWARDED -> onEarnReward()
                RewardedAdOutcome.DISMISSED -> onDismiss?.invoke()
                RewardedAdOutcome.FAILED -> onFail?.invoke()
            }
        }
    }
    fun presentResult(activity: Activity, adUnitId: String, completion: (RewardedAdOutcome) -> Unit) {
        MixpanelManager.track(AppEvent.REWARDED_AD_REQUESTED.wireName)
        val request = RewardAttempt {
            MixpanelManager.track(when (it) {
                RewardedAdOutcome.REWARDED -> AppEvent.REWARDED_AD_COMPLETED
                RewardedAdOutcome.DISMISSED -> AppEvent.REWARDED_AD_DISMISSED
                RewardedAdOutcome.FAILED -> AppEvent.REWARDED_AD_FAILED
            }.wireName)
            completion(it)
        }
        if (!requests.begin(request, available && (loadingId == null || loadingId == adUnitId))) return
        val weakActivity = WeakReference(activity)
        val show: (RewardedAd?) -> Unit = show@{ ad ->
            if (attempt !== request) return@show
            val owner = weakActivity.get()
            if (ad == null || owner == null || owner.isDestroyed || owner.isFinishing) { finish(request, true); return@show }
            rewardedAd = null; loadedId = null
            ad.fullScreenContentCallback = object : FullScreenContentCallback() {
                override fun onAdDismissedFullScreenContent() { finish(request) }
                override fun onAdFailedToShowFullScreenContent(error: AdError) { finish(request, true) }
            }
            ad.show(owner) { request.earn() }
        }
        if (rewardedAd != null && loadedId == adUnitId) show(rewardedAd)
        else { rewardedAd = null; loadedId = null; pending = show; if (loadingId == null) load(activity, adUnitId) }
    }
    private fun load(activity: Activity, id: String) {
        loadingId = id
        RewardedAd.load(activity.applicationContext, id, AdRequest.Builder().build(), object : RewardedAdLoadCallback() {
            override fun onAdLoaded(ad: RewardedAd) {
                loadingId = null; rewardedAd = ad; loadedId = id
                val callback = pending; pending = null; callback?.invoke(ad)
            }
            override fun onAdFailedToLoad(error: LoadAdError) {
                loadingId = null; rewardedAd = null; loadedId = null
                val callback = pending; pending = null; callback?.invoke(null)
            }
        })
    }
    private fun finish(request: RewardAttempt, failed: Boolean = false) {
        if (attempt !== request) return
        pending = null
        requests.finish(request, failed)
    }
}
