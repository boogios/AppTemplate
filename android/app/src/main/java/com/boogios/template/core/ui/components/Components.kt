package com.boogios.template.core.ui.components

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.boogios.template.core.ui.theme.BoogiosMain
import com.boogios.template.core.ui.theme.BoogiosShapes
import com.boogios.template.core.ui.theme.BoogiosSpacing
import com.boogios.template.core.ui.theme.BoogiosThemeTokens

@Composable
fun BoogiosCard(
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit,
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        shape = BoogiosShapes.card,
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
    ) {
        Column(modifier = Modifier.padding(BoogiosSpacing.card), content = { content() })
    }
}

@Composable
fun BoogiosPrimaryButton(
    text: String,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    onClick: () -> Unit,
) {
    Button(
        modifier = modifier.fillMaxWidth().heightIn(min = 44.dp),
        enabled = enabled,
        onClick = onClick,
        shape = BoogiosShapes.control,
        colors = ButtonDefaults.buttonColors(
            containerColor = BoogiosMain,
            contentColor = MaterialTheme.colorScheme.onPrimary,
        ),
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 15.dp),
    ) {
        Text(
            text = text,
            style = MaterialTheme.typography.titleSmall.copy(
                fontSize = 15.sp,
                fontWeight = FontWeight.SemiBold,
            ),
        )
    }
}

@Composable
fun SettingRow(
    title: String,
    value: String? = null,
    modifier: Modifier = Modifier,
    showsChevron: Boolean = true,
    onClick: () -> Unit,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        verticalAlignment = androidx.compose.ui.Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.bodyMedium,
            color = BoogiosThemeTokens.colors.gray7,
            modifier = Modifier.weight(1f),
        )
        if (value != null || showsChevron) {
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                value?.let {
                    Text(
                        text = it,
                        style = MaterialTheme.typography.labelMedium,
                        color = BoogiosThemeTokens.colors.gray5,
                    )
                }
                if (showsChevron) {
                    Icon(
                        imageVector = Icons.Default.ChevronRight,
                        contentDescription = null,
                        tint = BoogiosThemeTokens.colors.gray5,
                        modifier = Modifier.size(20.dp),
                    )
                }
            }
        }
    }
}

@Composable
fun BoogiosTextField(
    label: String,
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    singleLine: Boolean = true,
) {
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        modifier = modifier.fillMaxWidth().heightIn(min = BoogiosSpacing.touchTarget),
        textStyle = MaterialTheme.typography.bodyLarge,
        placeholder = { Text(label) },
        singleLine = singleLine,
        shape = BoogiosShapes.control,
        colors = OutlinedTextFieldDefaults.colors(
            focusedContainerColor = MaterialTheme.colorScheme.surface,
            unfocusedContainerColor = MaterialTheme.colorScheme.surface,
            focusedTextColor = MaterialTheme.colorScheme.onSurface,
            unfocusedTextColor = MaterialTheme.colorScheme.onSurface,
            focusedPlaceholderColor = BoogiosThemeTokens.colors.gray6,
            unfocusedPlaceholderColor = BoogiosThemeTokens.colors.gray6,
            focusedBorderColor = BoogiosThemeTokens.colors.main,
            unfocusedBorderColor = BoogiosThemeTokens.colors.gray3,
        ),
    )
}
