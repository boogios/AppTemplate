package com.boogios.template.data.settings

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.boogios.template.core.foundation.*
import kotlinx.coroutines.*

class OnboardingStore(
    private val repository: PreferenceRepository,
    private val analytics: AnalyticsClient = AnalyticsClient.Disabled,
    private val scope: CoroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate),
) {
    constructor(context: Context) : this(DataStorePreferences.onboarding(context))
    var hasCompletedOnboarding by mutableStateOf(false)
        private set
    var nickname by mutableStateOf("")
        private set
    var isReplayPresented by mutableStateOf(false)
        private set
    var loadState by mutableStateOf(LoadState.LOADING)
        private set
    var saveFailed by mutableStateOf(false)
        private set
    var isSaving by mutableStateOf(false)
        private set
    private var observation: Job? = null
    init { reload() }
    fun reload() {
        observation?.cancel()
        loadState = LoadState.LOADING
        observation = scope.launch {
            try {
                repository.values.collect { values ->
                    val completed = values["onboarding_completed"]
                    require(completed == null || completed in listOf("true", "false"))
                    hasCompletedOnboarding = completed == "true"
                    nickname = values["onboarding_nickname"].orEmpty()
                    loadState = LoadState.READY
                }
            } catch (cancelled: CancellationException) { throw cancelled }
            catch (_: Exception) { loadState = LoadState.FAILED }
        }
    }
    fun complete(input: String): Boolean {
        val normalized = input.trim()
        if (!isValidNickname(normalized) || isSaving || loadState != LoadState.READY) return false
        isSaving = true
        scope.launch {
            try {
                repository.write(mapOf("onboarding_completed" to "true", "onboarding_nickname" to normalized))
                nickname = normalized; hasCompletedOnboarding = true; saveFailed = false
                analytics.setNickname(normalized); analytics.track(AppEvent.ONBOARDING_COMPLETED)
            } catch (cancelled: CancellationException) { throw cancelled }
            catch (_: Exception) { saveFailed = true }
            finally { isSaving = false }
        }
        return true
    }
    fun presentReplay() { if (hasCompletedOnboarding) { isReplayPresented = true; analytics.track(AppEvent.ONBOARDING_REPLAYED) } }
    fun dismissReplay() { isReplayPresented = false }
    fun resetForTesting() {
        scope.launch {
            repository.write(mapOf("onboarding_completed" to "false", "onboarding_nickname" to ""))
            isReplayPresented = false
        }
    }
    fun close() { scope.cancel() }
    companion object {
        fun isValidNickname(input: String): Boolean {
            // Character boundaries avoid truncating surrogate pairs.
            val text = input.trim()
            val iterator = java.text.BreakIterator.getCharacterInstance(java.util.Locale.ROOT)
            iterator.setText(text)
            var count = 0
            while (iterator.next() != java.text.BreakIterator.DONE) count++
            return count in 1..20
        }
    }
}
