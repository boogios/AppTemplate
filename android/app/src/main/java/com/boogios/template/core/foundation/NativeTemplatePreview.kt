package com.boogios.template.core.foundation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalContext
import com.boogios.template.core.ui.theme.AppTemplateTheme
import com.boogios.template.data.settings.ThemeMode

/** Preview and screen-test owner: memory-only preferences and no external SDK requests. */
@Composable
fun NativeTemplatePreview(theme: ThemeMode = ThemeMode.SYSTEM, content: @Composable (AppDependencies) -> Unit) {
    val context = LocalContext.current
    val dependencies = remember { AppDependencies(context, isolated = true) }
    DisposableEffect(dependencies) {
        onDispose { dependencies.settings.close(); dependencies.onboarding.close(); dependencies.premium.close() }
    }
    CompositionLocalProvider(LocalAdvertisingClient provides dependencies.advertising) {
        AppTemplateTheme(themeMode = theme) { content(dependencies) }
    }
}
