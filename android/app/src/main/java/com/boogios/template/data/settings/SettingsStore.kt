package com.boogios.template.data.settings

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.boogios.template.core.foundation.LoadState
import kotlinx.coroutines.*

enum class ThemeMode {
    SYSTEM, LIGHT, DARK;
    companion object { fun fromStorage(value: String?) = entries.firstOrNull { it.name == value } ?: SYSTEM }
}
class SettingsStore(
    private val repository: PreferenceRepository,
    private val scope: CoroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate),
) {
    constructor(context: Context) : this(DataStorePreferences.settings(context))
    var themeMode by mutableStateOf(ThemeMode.SYSTEM)
        private set
    var loadState by mutableStateOf(LoadState.LOADING)
        private set
    var saveFailed by mutableStateOf(false)
        private set
    private var observation: Job? = null
    private var pendingTheme: ThemeMode? = null
    private var saving = false
    val selectedLanguage: AppLanguage get() = AppLanguageManager.current()
    init { reload() }
    fun reload() {
        observation?.cancel(); loadState = LoadState.LOADING
        observation = scope.launch {
            try {
                repository.values.collect { values -> themeMode = ThemeMode.fromStorage(values["app_theme"]); loadState = LoadState.READY }
            } catch (cancelled: CancellationException) { throw cancelled }
            catch (_: Exception) { loadState = LoadState.FAILED }
        }
    }
    fun setLanguage(language: AppLanguage) { AppLanguageManager.set(language) }
    fun setTheme(theme: ThemeMode) {
        if (loadState != LoadState.READY || saving) return
        saving = true
        scope.launch {
            try { repository.write(mapOf("app_theme" to theme.name)); themeMode = theme; saveFailed = false; pendingTheme = null }
            catch (cancelled: CancellationException) { throw cancelled }
            catch (_: Exception) { saveFailed = true; pendingTheme = theme }
            finally { saving = false }
        }
    }
    fun retry() { pendingTheme?.let(::setTheme) ?: reload() }
    fun close() { scope.cancel() }
}
