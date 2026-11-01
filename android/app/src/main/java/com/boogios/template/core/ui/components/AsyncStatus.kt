package com.boogios.template.core.ui.components

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.boogios.template.R

@Composable
fun AsyncStatus(loading: Boolean = false, messageRes: Int? = null, retry: (() -> Unit)? = null) {
    Column(Modifier.fillMaxWidth().padding(20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        if (loading) { CircularProgressIndicator(); Text(stringResource(R.string.foundation_loading)) }
        messageRes?.let { Text(stringResource(it)) }
        retry?.let { TextButton(onClick = it, modifier = Modifier.testTag("status.retry")) { Text(stringResource(R.string.foundation_retry)) } }
    }
}
