package com.boogios.template.data.premium

import android.app.Activity
import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.android.billingclient.api.BillingClient
import com.boogios.template.R
import com.boogios.template.core.config.AppConfig
import com.boogios.template.core.foundation.*
import kotlinx.coroutines.*
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

class PremiumStore(
    private val gateway: BillingGateway,
    private val analytics: AnalyticsClient = AnalyticsClient.Disabled,
    private val scope: CoroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate),
    private val now: () -> Long = System::currentTimeMillis,
) {
    constructor(context: Context) : this(if (AppRuntime.isIsolated) PreviewBillingGateway() else PlayBillingGateway(context))
    companion object {
        const val monthlyProductId = AppConfig.premiumMonthlyProductId
        const val yearlyProductId = AppConfig.premiumYearlyProductId
        const val lifetimeProductId = AppConfig.premiumLifetimeProductId
        val productIds = listOf(yearlyProductId, monthlyProductId, lifetimeProductId)
    }
    private val operation = Mutex()
    private var confirmedSubscriptions = emptySet<String>()
    private var confirmedOneTime = emptySet<String>()
    private var restoring: Job? = null
    private var preparing: Job? = null
    var productState by mutableStateOf(LoadState.EMPTY)
        private set
    var plans by mutableStateOf(emptyList<PremiumPlan>())
        private set
    var isLoading by mutableStateOf(false)
        private set
    var isPurchasing by mutableStateOf(false)
        private set
    var entitlement by mutableStateOf(EntitlementSnapshot())
        private set
    val hasPremiumAccess: Boolean get() = entitlement.hasPremium
    var selectedProductId by mutableStateOf(yearlyProductId)
        private set
    var messageRes by mutableStateOf<Int?>(null)
        private set

    init {
        gateway.onUpdate = { result ->
            scope.launch {
                isPurchasing = false
                when (result) {
                    PurchaseOutcome.PURCHASED -> {
                        refresh()
                        if (hasPremiumAccess && entitlement.state != EntitlementState.FAILED) analytics.track(AppEvent.PURCHASE_COMPLETED)
                        else { analytics.track(AppEvent.PURCHASE_FAILED); messageRes = R.string.foundation_purchase_failed }
                    }
                    PurchaseOutcome.PENDING -> { analytics.track(AppEvent.PURCHASE_PENDING); messageRes = R.string.foundation_pending }
                    PurchaseOutcome.CANCELLED -> analytics.track(AppEvent.PURCHASE_CANCELLED)
                    PurchaseOutcome.FAILED -> { analytics.track(AppEvent.PURCHASE_FAILED); messageRes = R.string.foundation_purchase_failed }
                }
            }
        }
    }
    fun prepare() {
        if (preparing?.isActive == true) return
        preparing = scope.launch { refresh(); loadProducts() }
    }
    fun openPaywall() { analytics.track(AppEvent.PREMIUM_VIEWED); prepare() }
    fun selectProduct(productId: String) { if (productId in productIds) selectedProductId = productId }
    fun purchase(activity: Activity) {
        if (isPurchasing || isLoading) return
        val plan = plans.firstOrNull { it.id == selectedProductId } ?: return
        isPurchasing = true; messageRes = null; analytics.track(AppEvent.PURCHASE_STARTED)
        if (!gateway.launch(activity, plan)) {
            isPurchasing = false; messageRes = R.string.foundation_purchase_failed; analytics.track(AppEvent.PURCHASE_FAILED)
        }
    }
    fun restore() {
        if (isPurchasing || restoring?.isActive == true) return
        restoring = scope.launch {
            refresh()
            if (entitlement.state == EntitlementState.FAILED) messageRes = R.string.foundation_purchase_failed
            else { messageRes = R.string.foundation_restored; analytics.track(AppEvent.PURCHASE_RESTORED) }
        }
    }
    suspend fun refresh() = operation.withLock {
        entitlement = entitlement.checking()
        try {
            withTimeout(15_000) { gateway.connect() }
            suspend fun query(type: String): Result<List<OwnedPurchase>> = try {
                Result.success(withTimeout(15_000) { gateway.purchases(type) })
            } catch (timeout: TimeoutCancellationException) { Result.failure(timeout) }
            catch (cancelled: CancellationException) { throw cancelled }
            catch (error: Exception) { Result.failure(error) }
            val (subscriptionResult, oneTimeResult) = coroutineScope {
                val a = async { query(BillingClient.ProductType.SUBS) }
                val b = async { query(BillingClient.ProductType.INAPP) }
                a.await() to b.await()
            }
            val subs = subscriptionResult.getOrDefault(emptyList())
            val inapp = oneTimeResult.getOrDefault(emptyList())
            fun active(values: List<OwnedPurchase>) = values.filterNot { it.pending }.flatMap { it.products }.filter { it in productIds }.toSet()
            if (subscriptionResult.isSuccess) confirmedSubscriptions = active(subs)
            if (oneTimeResult.isSuccess) confirmedOneTime = active(inapp)
            val checked = now()
            entitlement = entitlement.copy(
                activeProducts = confirmedSubscriptions + confirmedOneTime,
                subscriptionCheckedAt = if (subscriptionResult.isSuccess) checked else entitlement.subscriptionCheckedAt,
                oneTimeCheckedAt = if (oneTimeResult.isSuccess) checked else entitlement.oneTimeCheckedAt,
            )
            entitlement = if (subscriptionResult.isSuccess && oneTimeResult.isSuccess)
                entitlement.confirmed(confirmedSubscriptions, confirmedOneTime, checked)
            else entitlement.failed()
            (subs + inapp).filter { !it.pending && !it.acknowledged && it.products.any(productIds::contains) }
                .distinctBy { it.token }.forEach { purchase ->
                    var acknowledged = false
                    repeat(3) { attempt ->
                        if (!acknowledged) {
                            try { withTimeout(15_000) { gateway.acknowledge(purchase.token) }; acknowledged = true }
                            catch (_: TimeoutCancellationException) { if (attempt < 2) delay(500L * (attempt + 1)) }
                            catch (cancelled: CancellationException) { throw cancelled }
                            catch (_: Exception) { if (attempt < 2) delay(500L * (attempt + 1)) }
                        }
                    }
                    if (!acknowledged) messageRes = R.string.foundation_purchase_failed
                }
        } catch (_: TimeoutCancellationException) { entitlement = entitlement.failed() }
        catch (cancelled: CancellationException) { throw cancelled }
        catch (_: Exception) { entitlement = entitlement.failed() }
    }
    suspend fun loadProducts() {
        if (isLoading) return
        isLoading = true; productState = LoadState.LOADING; messageRes = null
        try {
            withTimeout(15_000) { gateway.connect() }
            plans = withTimeout(15_000) { gateway.products(BillingClient.ProductType.SUBS, listOf(monthlyProductId, yearlyProductId)) +
                gateway.products(BillingClient.ProductType.INAPP, listOf(lifetimeProductId)) }
            productState = if (plans.isEmpty()) LoadState.EMPTY else LoadState.READY
            if (plans.none { it.id == selectedProductId }) plans.firstOrNull()?.let { selectedProductId = it.id }
            if (plans.isEmpty()) messageRes = R.string.premium_unavailable
        } catch (_: TimeoutCancellationException) { productState = LoadState.FAILED; messageRes = R.string.premium_unavailable }
        catch (cancelled: CancellationException) { throw cancelled }
        catch (_: Exception) { productState = LoadState.FAILED; messageRes = R.string.premium_unavailable }
        finally { isLoading = false }
    }
    fun close() { scope.cancel(); gateway.onUpdate = {}; gateway.close() }
}
