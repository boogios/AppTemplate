package com.boogios.template.data.settings

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.emptyPreferences
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.boogios.template.core.analytics.MixpanelManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch

private val Context.onboardingDataStore by preferencesDataStore(name = "onboarding_state")

class OnboardingStore(context: Context) {
    private val applicationContext = context.applicationContext
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    var hasCompletedOnboarding by mutableStateOf(false)
        private set

    var nickname by mutableStateOf("")
        private set

    var isReplayPresented by mutableStateOf(false)
        private set

    init {
        scope.launch {
            applicationContext.onboardingDataStore.data
                .catch { emit(emptyPreferences()) }
                .collect { preferences ->
                    hasCompletedOnboarding = preferences[KEY_COMPLETED] == "true"
                    nickname = preferences[KEY_NICKNAME].orEmpty()
                }
        }
    }

    fun complete(input: String): Boolean {
        val normalized = input.trim()
        if (!isValidNickname(normalized)) return false

        nickname = normalized
        hasCompletedOnboarding = true
        scope.launch {
            applicationContext.onboardingDataStore.edit { preferences ->
                preferences[KEY_COMPLETED] = "true"
                preferences[KEY_NICKNAME] = normalized
            }
        }
        MixpanelManager.setUserProperties(normalized)
        MixpanelManager.track("onboarding_completed")
        return true
    }

    fun presentReplay() {
        if (!hasCompletedOnboarding) return
        isReplayPresented = true
        MixpanelManager.track("onboarding_replayed")
    }

    fun dismissReplay() {
        isReplayPresented = false
    }

    fun resetForTesting() {
        hasCompletedOnboarding = false
        nickname = ""
        isReplayPresented = false
        scope.launch { applicationContext.onboardingDataStore.edit { it.clear() } }
    }

    fun close() {
        scope.cancel()
    }

    companion object {
        fun isValidNickname(input: String): Boolean {
            val normalized = input.trim()
            return normalized.length in 1..20
        }

        private val KEY_COMPLETED = stringPreferencesKey("onboarding_completed")
        private val KEY_NICKNAME = stringPreferencesKey("onboarding_nickname")
    }
}
