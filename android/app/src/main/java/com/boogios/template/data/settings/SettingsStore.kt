package com.boogios.template.data.settings

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.datastore.preferences.SharedPreferencesMigration
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.emptyPreferences
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch

private val Context.appSettingsDataStore by preferencesDataStore(
    name = "app_settings",
    produceMigrations = { context ->
        listOf(SharedPreferencesMigration(context, "app_settings"))
    },
)

enum class ThemeMode {
    SYSTEM,
    LIGHT,
    DARK,
    ;

    companion object {
        fun fromStorage(value: String?): ThemeMode =
            values().firstOrNull { it.name == value } ?: SYSTEM
    }
}

class SettingsStore(context: Context) {
    private val applicationContext = context.applicationContext
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    var themeMode by mutableStateOf(ThemeMode.SYSTEM)
        private set

    val selectedLanguage: AppLanguage
        get() = AppLanguageManager.current()

    init {
        scope.launch {
            applicationContext.appSettingsDataStore.data
                .catch { emit(emptyPreferences()) }
                .collect { preferences ->
                    themeMode = ThemeMode.fromStorage(preferences[KEY_THEME])
                }
        }
    }

    fun setLanguage(language: AppLanguage) {
        AppLanguageManager.set(language)
    }

    fun setTheme(theme: ThemeMode) {
        themeMode = theme
        scope.launch {
            applicationContext.appSettingsDataStore.edit { preferences ->
                preferences[KEY_THEME] = theme.name
            }
        }
    }

    fun close() {
        scope.cancel()
    }

    private companion object {
        val KEY_THEME = stringPreferencesKey("app_theme")
    }
}
