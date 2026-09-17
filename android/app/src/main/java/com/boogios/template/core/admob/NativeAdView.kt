package com.boogios.template.core.admob

import android.content.Context
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.view.Gravity
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.viewinterop.AndroidView
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.core.content.ContextCompat
import com.boogios.template.core.config.AppConfig
import com.boogios.template.R
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView

@Composable
fun NativeAdCard(
    modifier: Modifier = Modifier,
    adUnitId: String = AppConfig.adMobNativeRequestId,
) {
    if (!AppConfig.hasAdMobNativeConfiguration || !AdMobManager.canRequestAds) return

    val context = LocalContext.current
    val loader = remember(context, adUnitId) { NativeAdLoader(context, adUnitId) }

    DisposableEffect(loader) {
        loader.start()
        loader.loadAdIfNeeded()
        onDispose { loader.stop() }
    }

    val nativeAd = loader.nativeAd
    if (nativeAd != null) {
        AndroidView(
            modifier = modifier.fillMaxWidth(),
            factory = { NativeAdCardContainer(it) },
            update = { it.bind(nativeAd) },
        )
    }
}

class NativeAdCardContainer(context: Context) : LinearLayout(context) {
    private val adView = NativeAdView(context)
    private val mediaView = MediaView(context)
    private val adBadge = TextView(context)
    private val iconView = ImageView(context)
    private val headlineView = TextView(context)
    private val advertiserView = TextView(context)
    private val bodyView = TextView(context)
    private val callToActionView = TextView(context)

    init {
        orientation = VERTICAL
        background = roundedBackground(color(R.color.surface_default), dp(16))
        clipToOutline = true

        mediaView.layoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            dp(140),
        )
        mediaView.setBackgroundColor(color(R.color.gray2))

        adBadge.text = context.getString(R.string.ad_badge)
        adBadge.setTextColor(Color.WHITE)
        adBadge.textSize = 10f
        adBadge.gravity = Gravity.CENTER
        adBadge.background = roundedBackground(color(R.color.brand_main), dp(5))
        adBadge.layoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.WRAP_CONTENT,
            dp(20),
        ).apply { setMargins(dp(14), dp(10), dp(14), 0) }

        iconView.scaleType = ImageView.ScaleType.CENTER_CROP
        iconView.background = roundedBackground(color(R.color.gray2), dp(10))
        iconView.layoutParams = LinearLayout.LayoutParams(dp(44), dp(44))

        headlineView.setTextColor(color(R.color.gray10))
        headlineView.textSize = 15f
        headlineView.maxLines = 2

        advertiserView.setTextColor(color(R.color.gray5))
        advertiserView.textSize = 11f
        advertiserView.maxLines = 1

        bodyView.setTextColor(color(R.color.gray6))
        bodyView.textSize = 12f
        bodyView.maxLines = 2
        bodyView.setPadding(dp(14), dp(8), dp(14), dp(14))

        callToActionView.setTextColor(Color.WHITE)
        callToActionView.textSize = 13f
        callToActionView.gravity = Gravity.CENTER
        callToActionView.background = roundedBackground(color(R.color.brand_main), dp(14))
        callToActionView.layoutParams = LinearLayout.LayoutParams(dp(88), dp(32)).apply {
            gravity = Gravity.CENTER_VERTICAL
            setMargins(dp(8), 0, dp(14), 0)
        }

        val assetRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(14), dp(8), 0, 0)
            addView(iconView)
            val textColumn = LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
                    .apply { setMargins(dp(10), 0, 0, 0) }
                addView(headlineView)
                addView(advertiserView)
            }
            addView(textColumn)
            addView(callToActionView)
        }

        val content = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            addView(mediaView)
            addView(adBadge)
            addView(assetRow)
            addView(bodyView)
        }
        adView.layoutParams = LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
        )
        adView.addView(content)
        addView(adView)

        adView.headlineView = headlineView
        adView.bodyView = bodyView
        adView.advertiserView = advertiserView
        adView.iconView = iconView
        adView.mediaView = mediaView
        adView.callToActionView = callToActionView
    }

    fun bind(ad: NativeAd) {
        headlineView.text = ad.headline
        bodyView.text = ad.body
        bodyView.visibility = if (ad.body.isNullOrBlank()) GONE else VISIBLE
        advertiserView.text = ad.advertiser
        advertiserView.visibility = if (ad.advertiser.isNullOrBlank()) GONE else VISIBLE
        iconView.setImageDrawable(ad.icon?.drawable)
        iconView.visibility = if (ad.icon?.drawable == null) GONE else VISIBLE
        callToActionView.text = ad.callToAction ?: context.getString(R.string.ad_call_to_action_fallback)
        callToActionView.visibility = if (ad.callToAction.isNullOrBlank()) GONE else VISIBLE
        mediaView.mediaContent = ad.mediaContent
        adView.setNativeAd(ad)
    }

    private fun roundedBackground(color: Int, radiusDp: Int): GradientDrawable =
        GradientDrawable().apply {
            setColor(color)
            cornerRadius = dp(radiusDp).toFloat()
        }

    private fun dp(value: Int): Int =
        (value * resources.displayMetrics.density).roundToInt()

    private fun color(resourceId: Int): Int = ContextCompat.getColor(context, resourceId)
}

private fun Float.roundToInt(): Int = kotlin.math.round(this).toInt()
