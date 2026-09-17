package com.boogios.template.features.onboarding

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.PrivacyTip
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.boogios.template.core.config.AppConfig
import com.boogios.template.R
import com.boogios.template.data.settings.OnboardingStore
import com.boogios.template.core.ui.components.BoogiosPrimaryButton
import com.boogios.template.core.ui.components.BoogiosTextField
import com.boogios.template.core.ui.theme.BoogiosGray2
import com.boogios.template.core.ui.theme.BoogiosGray3
import com.boogios.template.core.ui.theme.BoogiosMain

enum class OnboardingMode { INITIAL, REPLAY }

private enum class OnboardingStep {
    INTRO_ONE,
    INTRO_TWO,
    NICKNAME,
    NOTIFICATIONS,
    ADVERTISING,
}

@Composable
fun OnboardingScreen(
    mode: OnboardingMode,
    initialNickname: String = "",
    onComplete: (String) -> Unit,
    onReplayDismiss: () -> Unit,
    onRequestNotifications: (onFinished: () -> Unit) -> Unit,
    onRequestAdPrivacy: (onFinished: () -> Unit) -> Unit,
) {
    val steps = remember(mode) {
        if (mode == OnboardingMode.REPLAY) {
            listOf(OnboardingStep.INTRO_ONE, OnboardingStep.INTRO_TWO)
        } else {
            OnboardingStep.values().toList()
        }
    }
    var currentIndex by remember(mode) { mutableStateOf(0) }
    var nickname by remember(initialNickname, mode) { mutableStateOf(initialNickname) }
    var showNicknameError by remember { mutableStateOf(false) }
    val step = steps[currentIndex]

    fun advance() {
        when {
            mode == OnboardingMode.REPLAY && currentIndex == steps.lastIndex -> onReplayDismiss()
            currentIndex < steps.lastIndex -> currentIndex += 1
            else -> onComplete(nickname.trim())
        }
    }

    fun handleNext() {
        when (step) {
            OnboardingStep.NICKNAME -> {
                if (OnboardingStore.isValidNickname(nickname)) {
                    showNicknameError = false
                    advance()
                } else {
                    showNicknameError = true
                }
            }
            OnboardingStep.NOTIFICATIONS -> onRequestNotifications(::advance)
            OnboardingStep.ADVERTISING -> onRequestAdPrivacy { onComplete(nickname.trim()) }
            else -> advance()
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .padding(horizontal = 24.dp, vertical = 20.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text = stringResource(R.string.onboarding_progress, currentIndex + 1, steps.size),
            modifier = Modifier.testTag("onboarding.progress"),
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            style = MaterialTheme.typography.labelLarge,
        )
        Spacer(modifier = Modifier.height(32.dp))
        OnboardingArtwork(step = step)
        Spacer(modifier = Modifier.height(28.dp))
        Text(
            text = step.title(),
            style = MaterialTheme.typography.headlineMedium.copy(fontWeight = FontWeight.Bold),
        )
        Spacer(modifier = Modifier.height(12.dp))
        Text(
            text = step.description(),
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            style = MaterialTheme.typography.bodyLarge,
            modifier = Modifier.fillMaxWidth(),
        )
        if (step == OnboardingStep.NICKNAME) {
            Spacer(modifier = Modifier.height(24.dp))
            BoogiosTextField(
                label = stringResource(R.string.onboarding_nickname_placeholder),
                value = nickname,
                onValueChange = {
                    nickname = it.take(20)
                    showNicknameError = false
                },
                modifier = Modifier.testTag("onboarding.nickname"),
            )
            if (showNicknameError) {
                Text(
                    text = stringResource(R.string.onboarding_nickname_validation),
                    color = MaterialTheme.colorScheme.error,
                    style = MaterialTheme.typography.bodySmall,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = 8.dp),
                )
            }
        }
        Spacer(modifier = Modifier.weight(1f))
        BoogiosPrimaryButton(
            text = if (mode == OnboardingMode.REPLAY && currentIndex == steps.lastIndex) {
                stringResource(R.string.onboarding_start)
            } else if (step == OnboardingStep.NOTIFICATIONS) {
                stringResource(R.string.onboarding_allow_notifications)
            } else {
                stringResource(R.string.onboarding_next)
            },
            modifier = Modifier.testTag(
                if ((mode == OnboardingMode.REPLAY && currentIndex == steps.lastIndex) ||
                    (mode == OnboardingMode.INITIAL && step == OnboardingStep.ADVERTISING)
                ) {
                    "onboarding.start"
                } else {
                    "onboarding.next"
                },
            ),
            onClick = ::handleNext,
        )
    }
}

@Composable
private fun OnboardingArtwork(step: OnboardingStep) {
    Box(
        modifier = Modifier.size(180.dp),
        contentAlignment = Alignment.Center,
    ) {
        Box(
            modifier = Modifier
                .size(150.dp)
                .clip(CircleShape)
                .background(BoogiosMain.copy(alpha = 0.14f)),
        )
        when (step) {
            OnboardingStep.NOTIFICATIONS -> Icon(
                Icons.Default.NotificationsActive,
                contentDescription = null,
                tint = BoogiosMain,
                modifier = Modifier.size(64.dp),
            )
            OnboardingStep.ADVERTISING -> Icon(
                Icons.Default.PrivacyTip,
                contentDescription = null,
                tint = BoogiosMain,
                modifier = Modifier.size(64.dp),
            )
            else -> Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                Box(
                    modifier = Modifier
                        .size(56.dp)
                        .clip(RoundedCornerShape(18.dp))
                        .background(BoogiosMain),
                )
                Box(
                    modifier = Modifier
                        .size(34.dp)
                        .clip(CircleShape)
                        .background(BoogiosGray3),
                )
            }
        }
    }
}

@Composable
private fun OnboardingStep.title(): String = when (this) {
    OnboardingStep.INTRO_ONE -> stringResource(R.string.onboarding_intro_one_title)
    OnboardingStep.INTRO_TWO -> stringResource(R.string.onboarding_intro_two_title)
    OnboardingStep.NICKNAME -> stringResource(R.string.onboarding_nickname_title)
    OnboardingStep.NOTIFICATIONS -> stringResource(R.string.onboarding_notifications_title)
    OnboardingStep.ADVERTISING -> stringResource(R.string.onboarding_advertising_title)
}

@Composable
private fun OnboardingStep.description(): String = when (this) {
    OnboardingStep.INTRO_ONE -> stringResource(R.string.onboarding_intro_one_description, AppConfig.appName)
    OnboardingStep.INTRO_TWO -> stringResource(R.string.onboarding_intro_two_description)
    OnboardingStep.NICKNAME -> stringResource(R.string.onboarding_nickname_description)
    OnboardingStep.NOTIFICATIONS -> stringResource(R.string.onboarding_notifications_description)
    OnboardingStep.ADVERTISING -> stringResource(R.string.onboarding_advertising_description)
}
