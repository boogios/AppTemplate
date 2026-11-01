package com.boogios.template.core.admob

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import com.boogios.template.core.config.AppConfig
import com.boogios.template.core.ui.components.BoogiosPrimaryButton

@Composable
fun RewardedAdButton(
    text: String,
    modifier: Modifier = Modifier,
    onEarnReward: () -> Unit,
    onFail: (() -> Unit)? = null,
) {
    val advertising = com.boogios.template.core.foundation.LocalAdvertisingClient.current
    val context = LocalContext.current
    val activity = context.findActivity()

    BoogiosPrimaryButton(
        text = text,
        modifier = modifier,
        enabled = activity != null &&
            AppConfig.hasAdMobRewardConfiguration &&
            AdMobManager.canRequestAds,
        onClick = {
            activity?.let {
                advertising.reward(it) { result ->
                    when (result) {
                        com.boogios.template.core.foundation.RewardedAdOutcome.REWARDED -> onEarnReward()
                        com.boogios.template.core.foundation.RewardedAdOutcome.FAILED -> onFail?.invoke()
                        com.boogios.template.core.foundation.RewardedAdOutcome.DISMISSED -> Unit
                    }
                }
            }
        },
    )
}

private tailrec fun Context.findActivity(): Activity? = when (this) {
    is Activity -> this
    is ContextWrapper -> baseContext.findActivity()
    else -> null
}
