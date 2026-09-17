package com.boogios.template.data.premium

import android.app.Activity
import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.android.billingclient.api.AcknowledgePurchaseParams
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClientStateListener
import com.android.billingclient.api.BillingFlowParams
import com.android.billingclient.api.BillingResult
import com.android.billingclient.api.PendingPurchasesParams
import com.android.billingclient.api.ProductDetails
import com.android.billingclient.api.Purchase
import com.android.billingclient.api.QueryProductDetailsParams
import com.android.billingclient.api.QueryPurchasesParams
import com.boogios.template.core.config.AppConfig

data class PremiumPlan(
    val productDetails: ProductDetails,
    val offerToken: String? = null,
) {
    val id: String get() = productDetails.productId
    val price: String
        get() = productDetails.oneTimePurchaseOfferDetails?.formattedPrice
            ?: productDetails.subscriptionOfferDetails?.firstOrNull()?.pricingPhases?.pricingPhaseList?.firstOrNull()?.formattedPrice
            ?: "—"
}

class PremiumStore(context: Context) {
    companion object {
        const val monthlyProductId = AppConfig.premiumMonthlyProductId
        const val yearlyProductId = AppConfig.premiumYearlyProductId
        const val lifetimeProductId = AppConfig.premiumLifetimeProductId
        val productIds = listOf(yearlyProductId, monthlyProductId, lifetimeProductId)
    }

    private val billingClient = BillingClient.newBuilder(context.applicationContext)
        .setListener { _, purchases -> purchases?.let(::processPurchases) }
        .enablePendingPurchases(
            PendingPurchasesParams.newBuilder()
                .enableOneTimeProducts()
                .enablePrepaidPlans()
                .build(),
        )
        .build()

    var plans by mutableStateOf(emptyList<PremiumPlan>())
        private set
    var isLoading by mutableStateOf(false)
        private set
    var hasPremiumAccess by mutableStateOf(false)
        private set
    var selectedProductId by mutableStateOf(yearlyProductId)
        private set
    var message by mutableStateOf<String?>(null)
        private set

    init {
        connect()
    }

    fun selectProduct(productId: String) {
        if (productIds.contains(productId)) selectedProductId = productId
    }

    fun purchase(activity: Activity) {
        val plan = plans.firstOrNull { it.id == selectedProductId } ?: return
        val productParams = BillingFlowParams.ProductDetailsParams.newBuilder()
            .setProductDetails(plan.productDetails)
            .apply { plan.offerToken?.let(::setOfferToken) }
            .build()
        billingClient.launchBillingFlow(
            activity,
            BillingFlowParams.newBuilder().setProductDetailsParamsList(listOf(productParams)).build(),
        )
    }

    fun restore() {
        if (!billingClient.isReady) return
        listOf(BillingClient.ProductType.SUBS, BillingClient.ProductType.INAPP).forEach { type ->
            billingClient.queryPurchasesAsync(
                QueryPurchasesParams.newBuilder().setProductType(type).build(),
            ) { _, purchases -> processPurchases(purchases) }
        }
    }

    fun close() {
        if (billingClient.isReady) billingClient.endConnection()
    }

    private fun connect() {
        billingClient.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(result: BillingResult) {
                if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                    queryProducts()
                    restore()
                } else {
                    message = ""
                }
            }

            override fun onBillingServiceDisconnected() = Unit
        })
    }

    private fun queryProducts() {
        isLoading = true
        val products = productIds.map { id ->
            QueryProductDetailsParams.Product.newBuilder()
                .setProductId(id)
                .setProductType(if (id == lifetimeProductId) BillingClient.ProductType.INAPP else BillingClient.ProductType.SUBS)
                .build()
        }
        billingClient.queryProductDetailsAsync(
            QueryProductDetailsParams.newBuilder().setProductList(products).build(),
        ) { result, details ->
            isLoading = false
            if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                plans = details.map { product ->
                    PremiumPlan(product, product.subscriptionOfferDetails?.firstOrNull()?.offerToken)
                }
                if (plans.isEmpty()) message = ""
            } else {
                plans = emptyList()
                message = ""
            }
        }
    }

    private fun processPurchases(purchases: List<Purchase>) {
        val premiumPurchase = purchases.firstOrNull { purchase ->
            purchase.purchaseState == Purchase.PurchaseState.PURCHASED && purchase.products.any(productIds::contains)
        }
        hasPremiumAccess = premiumPurchase != null
        premiumPurchase?.let { purchase ->
            if (!purchase.isAcknowledged) {
                billingClient.acknowledgePurchase(
                    AcknowledgePurchaseParams.newBuilder().setPurchaseToken(purchase.purchaseToken).build(),
                ) { }
            }
        }
    }
}
