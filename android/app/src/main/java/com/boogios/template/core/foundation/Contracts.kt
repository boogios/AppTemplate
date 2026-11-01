package com.boogios.template.core.foundation

object AppRuntime { var isIsolated = System.getProperty("boogios.test") == "true" }
enum class LoadState { LOADING, READY, EMPTY, FAILED }
enum class EntitlementState { UNKNOWN, CHECKING, FREE, PREMIUM, FAILED }
enum class PurchaseOutcome { PURCHASED, PENDING, CANCELLED, FAILED }
enum class RewardedAdOutcome { REWARDED, DISMISSED, FAILED }
enum class AppEvent(val wireName: String) {
    ONBOARDING_COMPLETED("onboarding_completed"), ONBOARDING_REPLAYED("onboarding_replayed"),
    PREMIUM_VIEWED("premium_viewed"), PURCHASE_STARTED("purchase_started"),
    PURCHASE_COMPLETED("purchase_completed"), PURCHASE_PENDING("purchase_pending"),
    PURCHASE_CANCELLED("purchase_cancelled"), PURCHASE_FAILED("purchase_failed"), PURCHASE_RESTORED("purchase_restored"),
    REWARDED_AD_REQUESTED("rewarded_ad_requested"), REWARDED_AD_COMPLETED("rewarded_ad_completed"),
    REWARDED_AD_DISMISSED("rewarded_ad_dismissed"), REWARDED_AD_FAILED("rewarded_ad_failed"),
}
interface AnalyticsClient {
    fun track(event: AppEvent)
    fun setNickname(nickname: String)
    object Disabled : AnalyticsClient { override fun track(event: AppEvent) = Unit; override fun setNickname(nickname: String) = Unit }
}
class RewardAttempt(private var completion: ((RewardedAdOutcome) -> Unit)?) {
    private var earned = false
    fun earn() { earned = true }
    fun finish(failed: Boolean = false) {
        val callback = completion
        completion = null
        callback?.invoke(if (failed) RewardedAdOutcome.FAILED else if (earned) RewardedAdOutcome.REWARDED else RewardedAdOutcome.DISMISSED)
    }
}
class RewardGate {
    var current: RewardAttempt? = null
        private set
    fun begin(request: RewardAttempt, available: Boolean): Boolean {
        if (!available || current != null) { request.finish(true); return false }
        current = request; return true
    }
    fun finish(request: RewardAttempt, failed: Boolean = false) {
        if (current !== request) return
        current = null; request.finish(failed)
    }
}
/** Preserve the failed product type; apply confirmed cancellations from successful queries. */
data class EntitlementSnapshot(
    val state: EntitlementState = EntitlementState.UNKNOWN,
    val activeProducts: Set<String> = emptySet(),
    val checkedAt: Long? = null,
    val subscriptionCheckedAt: Long? = null,
    val oneTimeCheckedAt: Long? = null,
) {
    val hasPremium: Boolean get() = activeProducts.isNotEmpty()
    fun checking() = copy(state = EntitlementState.CHECKING)
    fun failed() = copy(state = EntitlementState.FAILED)
    fun confirmed(subscriptions: Set<String>, oneTime: Set<String>, now: Long): EntitlementSnapshot {
        val active = subscriptions + oneTime
        return copy(state = if (active.isEmpty()) EntitlementState.FREE else EntitlementState.PREMIUM, activeProducts = active, checkedAt = now)
    }
}
