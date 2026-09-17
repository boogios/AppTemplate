package com.boogios.template.features.settings

import android.widget.Toast
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.background
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material3.AlertDialog
import androidx.compose.material.icons.Icons
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.Alignment
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.boogios.template.core.config.AppConfig
import com.boogios.template.BuildConfig
import com.boogios.template.core.config.openExternalUrl
import com.boogios.template.R
import com.boogios.template.data.settings.AppLanguage
import com.boogios.template.data.settings.SettingsStore
import com.boogios.template.data.settings.ThemeMode
import com.boogios.template.data.premium.PremiumStore
import com.boogios.template.core.ui.components.BoogiosCard
import com.boogios.template.core.ui.components.SettingRow
import com.boogios.template.core.ui.theme.BoogiosSpacing
import com.boogios.template.core.ui.theme.BoogiosThemeTokens

@Composable
fun SettingsScreen(
    modifier: Modifier = Modifier,
    settingsStore: SettingsStore,
    premiumStore: PremiumStore,
    isPrivacyOptionsRequired: Boolean,
    onOpenPrivacyOptions: () -> Unit,
    onReplayOnboarding: () -> Unit,
    onOpenPremium: () -> Unit,
    onRequestReview: () -> Unit,
) {
    val context = LocalContext.current
    var dialog by remember { mutableStateOf<SettingsDialog?>(null) }

    Column(
        modifier = modifier.fillMaxSize(),
    ) {
        Text(
            text = stringResource(R.string.settings_title),
            style = MaterialTheme.typography.headlineMedium,
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 8.dp, bottom = 28.dp),
            textAlign = TextAlign.Center,
        )
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = BoogiosSpacing.screen, vertical = 10.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            PremiumSettingCard(
                isPremium = premiumStore.hasPremiumAccess,
                onClick = onOpenPremium,
            )
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                BoogiosCard {
                    Column(verticalArrangement = Arrangement.spacedBy(28.dp)) {
                        SettingRow(
                            title = stringResource(R.string.settings_language),
                            value = stringResource(settingsStore.selectedLanguage.labelRes),
                            modifier = Modifier.testTag("settings.language"),
                            onClick = { dialog = SettingsDialog.LANGUAGE },
                        )
                        SettingRow(
                            title = stringResource(R.string.settings_theme),
                            value = stringResource(themeModeLabelRes(settingsStore.themeMode)),
                            modifier = Modifier.testTag("settings.theme"),
                            onClick = { dialog = SettingsDialog.THEME },
                        )
                        if (isPrivacyOptionsRequired) {
                            SettingRow(
                                title = stringResource(R.string.settings_privacy_options),
                                modifier = Modifier.testTag("settings.privacy-options"),
                                onClick = onOpenPrivacyOptions,
                            )
                        }
                    }
                }
                BoogiosCard {
                    Column(verticalArrangement = Arrangement.spacedBy(28.dp)) {
                        SettingRow(
                            title = stringResource(R.string.settings_replay_onboarding),
                            modifier = Modifier.testTag("settings.replay-onboarding"),
                            onClick = onReplayOnboarding,
                        )
                        SettingRow(
                            title = stringResource(R.string.settings_developer_apps),
                            modifier = Modifier.testTag("settings.developer-apps"),
                            onClick = {
                                if (!openExternalUrl(context, AppConfig.developerAppsUrl)) showLinkError(context)
                            },
                        )
                        SettingRow(
                            title = stringResource(R.string.settings_review),
                            value = stringResource(R.string.settings_review_value),
                            modifier = Modifier.testTag("settings.review"),
                            onClick = onRequestReview,
                        )
                        SettingRow(
                            title = stringResource(R.string.settings_support),
                            modifier = Modifier.testTag("settings.support"),
                            onClick = {
                                if (!openExternalUrl(context, AppConfig.supportUrl)) showLinkError(context)
                            },
                        )
                        SettingRow(
                            title = stringResource(R.string.settings_terms),
                            modifier = Modifier.testTag("settings.terms"),
                            onClick = {
                                if (!openExternalUrl(context, AppConfig.termsUrl)) showLinkError(context)
                            },
                        )
                        SettingRow(
                            title = stringResource(R.string.settings_privacy),
                            modifier = Modifier.testTag("settings.privacy"),
                            onClick = {
                                if (!openExternalUrl(context, AppConfig.privacyUrl)) showLinkError(context)
                            },
                        )
                    }
                }
                BoogiosCard {
                    SettingRow(
                        title = stringResource(R.string.settings_version),
                        value = "V.${BuildConfig.VERSION_NAME}",
                        showsChevron = false,
                        modifier = Modifier.testTag("settings.version"),
                        onClick = {},
                    )
                }
            }
        }
    }

    when (dialog) {
        SettingsDialog.LANGUAGE -> ChoiceDialog(
            title = stringResource(R.string.settings_language),
            options = AppLanguage.displayCases,
            optionLabel = { language -> stringResource(language.labelRes) },
            onDismiss = { dialog = null },
            onSelected = { language ->
                settingsStore.setLanguage(language)
                dialog = null
                Toast.makeText(context, R.string.toast_updated, Toast.LENGTH_SHORT).show()
            },
        )
        SettingsDialog.THEME -> ChoiceDialog(
            title = stringResource(R.string.settings_theme),
            options = ThemeMode.values().toList(),
            optionLabel = { theme -> stringResource(themeModeLabelRes(theme)) },
            onDismiss = { dialog = null },
            onSelected = { selected ->
                settingsStore.setTheme(selected)
                dialog = null
                Toast.makeText(context, R.string.toast_updated, Toast.LENGTH_SHORT).show()
            },
        )
        null -> Unit
    }
}

@Composable
private fun PremiumSettingCard(isPremium: Boolean, onClick: () -> Unit) {
    Card(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .testTag("settings.premium"),
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(containerColor = BoogiosThemeTokens.colors.main),
    ) {
        androidx.compose.foundation.layout.Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(
                    Brush.linearGradient(
                        colors = listOf(
                            BoogiosThemeTokens.colors.main,
                            BoogiosThemeTokens.colors.main.copy(alpha = 0.72f),
                        ),
                    ),
                )
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Box(
                modifier = Modifier
                    .size(44.dp)
                    .clip(RoundedCornerShape(14.dp))
                    .background(Color.White.copy(alpha = 0.14f)),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    imageVector = if (isPremium) Icons.Default.CheckCircle else Icons.Default.AutoAwesome,
                    contentDescription = null,
                    tint = Color.White,
                    modifier = Modifier.size(18.dp),
                )
            }
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(stringResource(R.string.premium_card_title), style = MaterialTheme.typography.headlineSmall, color = Color.White)
                Text(
                    stringResource(if (isPremium) R.string.premium_card_active else R.string.premium_card_description),
                    style = MaterialTheme.typography.labelSmall,
                    color = Color.White.copy(alpha = 0.82f),
                )
            }
            Icon(
                imageVector = if (isPremium) Icons.Default.CheckCircle else Icons.Default.ChevronRight,
                contentDescription = null,
                tint = Color.White.copy(alpha = 0.88f),
                modifier = Modifier.size(20.dp),
            )
        }
    }
}

private enum class SettingsDialog { LANGUAGE, THEME }

@Composable
private fun <T> ChoiceDialog(
    title: String,
    options: List<T>,
    optionLabel: @Composable (T) -> String,
    onDismiss: () -> Unit,
    onSelected: (T) -> Unit,
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(title) },
        text = {
            Column {
                options.forEach { option ->
                    TextButton(onClick = { onSelected(option) }) {
                        Text(optionLabel(option))
                    }
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text(stringResource(R.string.dialog_close))
            }
        },
    )
}

private fun themeModeLabelRes(themeMode: ThemeMode): Int = when (themeMode) {
    ThemeMode.LIGHT -> R.string.theme_light
    ThemeMode.DARK -> R.string.theme_dark
    ThemeMode.SYSTEM -> R.string.theme_system
}

private fun showLinkError(context: android.content.Context) {
    Toast.makeText(context, R.string.toast_link_unavailable, Toast.LENGTH_SHORT).show()
}
