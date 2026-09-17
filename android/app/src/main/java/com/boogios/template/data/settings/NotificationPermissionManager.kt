package com.boogios.template.data.settings

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat

object NotificationPermissionManager {
    private const val PREFERENCES_NAME = "onboarding_permissions"
    private const val NOTIFICATION_DECIDED_KEY = "notification_decided"

    fun shouldRequest(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return false
        if (context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
                .getBoolean(NOTIFICATION_DECIDED_KEY, false)
        ) return false

        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.POST_NOTIFICATIONS,
        ) != PackageManager.PERMISSION_GRANTED
    }

    fun markDecided(context: Context) {
        context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(NOTIFICATION_DECIDED_KEY, true)
            .apply()
    }
}
