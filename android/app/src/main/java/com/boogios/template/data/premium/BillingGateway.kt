package com.boogios.template.data.premium

import android.app.Activity
import android.content.Context
import com.android.billingclient.api.*
import com.boogios.template.core.foundation.PurchaseOutcome
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

data class OwnedPurchase(val products: List<String>, val token: String, val acknowledged: Boolean, val pending: Boolean)
data class PremiumPlan(val id: String, val price: String, val details: ProductDetails? = null, val offerToken: String? = null)

interface BillingGateway {
    var onUpdate: (PurchaseOutcome) -> Unit
    suspend fun connect()
    suspend fun products(type: String, ids: List<String>): List<PremiumPlan>
    suspend fun purchases(type: String): List<OwnedPurchase>
    suspend fun acknowledge(token: String)
    fun launch(activity: Activity, plan: PremiumPlan): Boolean
    fun close()
}

class PlayBillingGateway(context: Context) : BillingGateway {
    override var onUpdate: (PurchaseOutcome) -> Unit = {}
    private val connectionMutex = Mutex()
    private val client = BillingClient.newBuilder(context.applicationContext)
        .setListener { result, purchases ->
            onUpdate(when {
                result.responseCode == BillingClient.BillingResponseCode.USER_CANCELED -> PurchaseOutcome.CANCELLED
                result.responseCode != BillingClient.BillingResponseCode.OK -> PurchaseOutcome.FAILED
                purchases?.any { it.purchaseState == Purchase.PurchaseState.PENDING } == true -> PurchaseOutcome.PENDING
                purchases?.any { it.purchaseState == Purchase.PurchaseState.PURCHASED } == true -> PurchaseOutcome.PURCHASED
                else -> PurchaseOutcome.FAILED
            })
        }
        .enablePendingPurchases(PendingPurchasesParams.newBuilder().enableOneTimeProducts().enablePrepaidPlans().build())
        .enableAutoServiceReconnection()
        .build()

    override suspend fun connect() = connectionMutex.withLock {
        if (!client.isReady) suspendCancellableCoroutine<Unit> { continuation ->
            client.startConnection(object : BillingClientStateListener {
                override fun onBillingSetupFinished(result: BillingResult) {
                    if (!continuation.isActive) return
                    if (result.responseCode == BillingClient.BillingResponseCode.OK) continuation.resume(Unit)
                    else continuation.resumeWithException(BillingFailure())
                }
                override fun onBillingServiceDisconnected() {
                    if (continuation.isActive) continuation.resumeWithException(BillingFailure())
                }
            })
        }
    }
    override suspend fun products(type: String, ids: List<String>): List<PremiumPlan> = suspendCancellableCoroutine { continuation ->
        val params = QueryProductDetailsParams.newBuilder().setProductList(ids.map {
            QueryProductDetailsParams.Product.newBuilder().setProductId(it).setProductType(type).build()
        }).build()
        client.queryProductDetailsAsync(params) { result, response ->
            if (!continuation.isActive) return@queryProductDetailsAsync
            if (result.responseCode != BillingClient.BillingResponseCode.OK) continuation.resumeWithException(BillingFailure())
            else continuation.resume(response.productDetailsList.mapNotNull { details ->
                val offer = details.subscriptionOfferDetails?.firstOrNull()
                val price = details.oneTimePurchaseOfferDetails?.formattedPrice
                    ?: offer?.pricingPhases?.pricingPhaseList?.lastOrNull()?.formattedPrice
                price?.let { PremiumPlan(details.productId, it, details, offer?.offerToken) }
            })
        }
    }
    override suspend fun purchases(type: String): List<OwnedPurchase> = suspendCancellableCoroutine { continuation ->
        client.queryPurchasesAsync(QueryPurchasesParams.newBuilder().setProductType(type).build()) { result, purchases ->
            if (!continuation.isActive) return@queryPurchasesAsync
            if (result.responseCode != BillingClient.BillingResponseCode.OK) continuation.resumeWithException(BillingFailure())
            else continuation.resume(purchases.filter { it.purchaseState != Purchase.PurchaseState.UNSPECIFIED_STATE }.map {
                OwnedPurchase(it.products, it.purchaseToken, it.isAcknowledged, it.purchaseState == Purchase.PurchaseState.PENDING)
            })
        }
    }
    override suspend fun acknowledge(token: String): Unit = suspendCancellableCoroutine { continuation ->
        client.acknowledgePurchase(AcknowledgePurchaseParams.newBuilder().setPurchaseToken(token).build()) {
            if (continuation.isActive) {
                if (it.responseCode == BillingClient.BillingResponseCode.OK) continuation.resume(Unit)
                else continuation.resumeWithException(BillingFailure())
            }
        }
    }
    override fun launch(activity: Activity, plan: PremiumPlan): Boolean {
        val details = plan.details ?: return false
        val product = BillingFlowParams.ProductDetailsParams.newBuilder().setProductDetails(details)
            .apply { plan.offerToken?.let(::setOfferToken) }.build()
        return client.launchBillingFlow(activity, BillingFlowParams.newBuilder().setProductDetailsParamsList(listOf(product)).build())
            .responseCode == BillingClient.BillingResponseCode.OK
    }
    override fun close() { client.endConnection() }
    private class BillingFailure : Exception("billing_operation_failed")
}

class PreviewBillingGateway : BillingGateway {
    override var onUpdate: (PurchaseOutcome) -> Unit = {}
    override suspend fun connect() = Unit
    override suspend fun products(type: String, ids: List<String>) = emptyList<PremiumPlan>()
    override suspend fun purchases(type: String) = emptyList<OwnedPurchase>()
    override suspend fun acknowledge(token: String) = Unit
    override fun launch(activity: Activity, plan: PremiumPlan) = false
    override fun close() = Unit
}
