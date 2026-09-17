package com.boogios.template.core.analytics

import android.content.Context
import com.boogios.template.core.config.AppConfig
import com.boogios.template.BuildConfig
import com.mixpanel.android.mpmetrics.MixpanelAPI
import org.json.JSONObject

object MixpanelManager {
    private var mixpanel: MixpanelAPI? = null

    fun initializeIfConfigured(context: Context) {
        if (mixpanel != null || !AppConfig.hasMixpanelConfiguration) return

        mixpanel = MixpanelAPI.getInstance(
            context.applicationContext,
            AppConfig.mixpanelToken,
            false,
        )
        mixpanel?.registerSuperProperties(
            JSONObject().apply {
                put("platform", "Android")
                put("app_version", BuildConfig.VERSION_NAME)
                put("build_number", BuildConfig.VERSION_CODE.toString())
            },
        )
    }

    fun identify(userId: String) {
        mixpanel?.identify(userId)
        mixpanel?.people?.set(
            JSONObject().apply {
                put("platform", "Android")
                put("user_id", userId)
            },
        )
    }

    fun reset() {
        mixpanel?.reset()
    }

    fun setUserProperties(nickname: String) {
        mixpanel?.people?.set(
            JSONObject().apply { put("\$name", nickname) },
        )
    }

    fun setUserMembershipStatus(status: Boolean) {
        mixpanel?.people?.set(
            JSONObject().apply { put("membership_status", status.toString()) },
        )
    }

    fun setUserProperty(key: String, value: String) {
        mixpanel?.people?.set(
            JSONObject().apply { put(key, value) },
        )
    }

    fun track(event: String, properties: Map<String, Any?> = emptyMap()) {
        val payload = JSONObject()
        properties.forEach { (key, value) ->
            if (value != null) payload.put(key, value)
        }
        mixpanel?.track(event, payload)
    }

    fun flush() {
        mixpanel?.flush()
    }
}
