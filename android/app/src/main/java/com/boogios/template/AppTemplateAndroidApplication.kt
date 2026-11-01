package com.boogios.template

import android.app.Application
import com.boogios.template.core.analytics.MixpanelManager

class AppTemplateAndroidApplication : Application() {
    val dependencies by lazy { com.boogios.template.core.foundation.AppDependencies(this) }
    override fun onCreate() {
        super.onCreate()
        if (!com.boogios.template.core.foundation.AppRuntime.isIsolated) MixpanelManager.initializeIfConfigured(this)
    }
}
