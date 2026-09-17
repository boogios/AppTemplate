package com.boogios.template.core.admob

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.viewinterop.AndroidView
import com.boogios.template.core.config.AppConfig
import com.google.android.gms.ads.AdRequest
import com.google.android.gms.ads.AdSize
import com.google.android.gms.ads.AdView

@Composable
fun BannerAdView(
    modifier: Modifier = Modifier,
    adUnitId: String = AppConfig.adMobBannerId,
) {
    if (!AppConfig.hasAdMobBannerConfiguration || !AdMobManager.canRequestAds) return

    val context = LocalContext.current
    val configuration = LocalConfiguration.current
    val adWidth = configuration.screenWidthDp.coerceAtLeast(1)

    AndroidView(
        modifier = modifier.fillMaxWidth(),
        factory = {
            AdView(it).apply {
                setAdSize(
                    AdSize.getLargeAnchoredAdaptiveBannerAdSize(it, adWidth),
                )
                setAdUnitId(adUnitId)
                loadAd(AdRequest.Builder().build())
            }
        },
        update = { adView ->
            adView.contentDescription = context.getString(com.boogios.template.R.string.ad_content_description)
        },
    )
}
