package com.boogios.template.data.settings

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.SharedPreferencesMigration
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.map

private val Context.settingsDataStore by preferencesDataStore(name = "app_settings", produceMigrations = {
    listOf(SharedPreferencesMigration(it, "app_settings"))
})
private val Context.onboardingDataStore by preferencesDataStore(name = "onboarding_state")

interface PreferenceRepository {
    val values: Flow<Map<String, String>>
    suspend fun write(values: Map<String, String>)
}
class DataStorePreferences(private val store: DataStore<Preferences>) : PreferenceRepository {
    override val values = store.data.map { preferences ->
        preferences.asMap().map { (key, value) ->
            require(value is String) { "invalid_preference_type" }
            key.name to value
        }.toMap()
    }
    override suspend fun write(values: Map<String, String>) {
        store.edit { preferences -> values.forEach { (key, value) -> preferences[stringPreferencesKey(key)] = value } }
    }
    companion object {
        fun settings(context: Context) = DataStorePreferences(context.applicationContext.settingsDataStore)
        fun onboarding(context: Context) = DataStorePreferences(context.applicationContext.onboardingDataStore)
    }
}
class MemoryPreferences : PreferenceRepository {
    override val values = MutableStateFlow<Map<String, String>>(emptyMap())
    override suspend fun write(values: Map<String, String>) { this.values.value = this.values.value + values }
}
