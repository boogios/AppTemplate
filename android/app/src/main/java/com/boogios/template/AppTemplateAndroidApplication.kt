package com.boogios.template

import android.app.Application
import com.boogios.template.core.analytics.MixpanelManager

class AppTemplateAndroidApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        MixpanelManager.initializeIfConfigured(this)
    }
}
