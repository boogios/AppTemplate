package com.boogios.template.features.premium

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.boogios.template.R
import com.boogios.template.core.ui.components.BoogiosPrimaryButton
import com.boogios.template.data.premium.PremiumPlan
import com.boogios.template.data.premium.PremiumStore
import com.boogios.template.core.ui.theme.BoogiosGray2
import com.boogios.template.core.ui.theme.BoogiosGray6
import com.boogios.template.core.ui.theme.BoogiosGray9
import com.boogios.template.core.ui.theme.BoogiosMain

@Composable
fun PremiumPaywallDialog(premiumStore: PremiumStore, onDismiss: () -> Unit) {
    androidx.compose.runtime.LaunchedEffect(premiumStore) { premiumStore.openPaywall() }
    val activity = LocalContext.current.findActivity()
    Dialog(onDismissRequest = onDismiss, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        Card(
            modifier = Modifier.fillMaxWidth().padding(18.dp),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.background),
            shape = androidx.compose.foundation.shape.RoundedCornerShape(24.dp),
        ) {
            Column(
                modifier = Modifier.verticalScroll(rememberScrollState()).padding(20.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Row {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(stringResource(R.string.premium_title), style = MaterialTheme.typography.headlineMedium, color = MaterialTheme.colorScheme.onSurface)
                        Text(stringResource(R.string.premium_description), style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.padding(top = 6.dp))
                    }
                    IconButton(onClick = onDismiss, modifier = Modifier.testTag("premium.close")) {
                        Icon(Icons.Default.Close, contentDescription = stringResource(R.string.dialog_close))
                    }
                }
                PremiumBenefit(stringResource(R.string.premium_feature_unlimited))
                PremiumBenefit(stringResource(R.string.premium_feature_ads))
                PremiumBenefit(stringResource(R.string.premium_feature_updates))
                Text(stringResource(R.string.premium_plans), style = MaterialTheme.typography.titleMedium, modifier = Modifier.padding(top = 8.dp))
                if (premiumStore.isLoading) com.boogios.template.core.ui.components.AsyncStatus(loading = true)
                if (premiumStore.entitlement.state == com.boogios.template.core.foundation.EntitlementState.FAILED || premiumStore.productState == com.boogios.template.core.foundation.LoadState.FAILED || (!premiumStore.hasPremiumAccess && !premiumStore.isLoading && premiumStore.plans.isEmpty())) {
                    Column(Modifier.testTag("premium.unavailable")) {
                        com.boogios.template.core.ui.components.AsyncStatus(messageRes = R.string.premium_unavailable, retry = premiumStore::prepare)
                    }
                }
                premiumStore.plans.forEach { plan ->
                    PremiumPlanRow(plan, plan.id == premiumStore.selectedProductId) { premiumStore.selectProduct(plan.id) }
                }
                BoogiosPrimaryButton(
                    text = if (premiumStore.hasPremiumAccess) stringResource(R.string.premium_active) else stringResource(R.string.premium_purchase),
                    enabled = !premiumStore.isPurchasing && !premiumStore.isLoading && activity != null && premiumStore.plans.isNotEmpty() && !premiumStore.hasPremiumAccess,
                    modifier = Modifier.testTag("premium.purchase"),
                ) { activity?.let(premiumStore::purchase) }
                TextButton(onClick = premiumStore::restore, modifier = Modifier.testTag("premium.restore")) {
                    Text(stringResource(R.string.premium_restore))
                }
                premiumStore.messageRes?.takeUnless { it == R.string.premium_unavailable }?.let {
                    Text(stringResource(it), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }
    }
}

@Composable
private fun PremiumBenefit(text: String) {
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        Icon(Icons.Default.CheckCircle, contentDescription = null, tint = BoogiosMain)
        Text(text, style = MaterialTheme.typography.bodyMedium)
    }
}

@Composable
private fun PremiumPlanRow(plan: PremiumPlan, selected: Boolean, onClick: () -> Unit) {
    Card(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth().testTag("premium.plan.${plan.id}"),
        colors = CardDefaults.cardColors(containerColor = if (selected) BoogiosMain.copy(alpha = 0.14f) else MaterialTheme.colorScheme.surfaceContainer),
    ) {
        Row(modifier = Modifier.padding(14.dp)) {
            Icon(Icons.Default.Star, contentDescription = null, tint = if (selected) BoogiosMain else MaterialTheme.colorScheme.onSurfaceVariant)
            Column(modifier = Modifier.weight(1f).padding(start = 10.dp)) {
                Text(
                    text = when (plan.id) {
                        PremiumStore.yearlyProductId -> stringResource(R.string.premium_yearly)
                        PremiumStore.monthlyProductId -> stringResource(R.string.premium_monthly)
                        else -> stringResource(R.string.premium_lifetime)
                    },
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurface,
                )
                Text(
                    text = if (plan.id == PremiumStore.lifetimeProductId) stringResource(R.string.premium_lifetime_description) else stringResource(R.string.premium_renews),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            Text(plan.price, style = MaterialTheme.typography.titleMedium, color = if (selected) BoogiosMain else BoogiosGray9)
        }
    }
}

private tailrec fun Context.findActivity(): Activity? = when (this) {
    is Activity -> this
    is ContextWrapper -> baseContext.findActivity()
    else -> null
}
