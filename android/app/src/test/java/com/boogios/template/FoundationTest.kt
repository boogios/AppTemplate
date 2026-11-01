package com.boogios.template

import android.app.Activity
import com.boogios.template.core.foundation.*
import com.boogios.template.data.premium.*
import com.boogios.template.data.settings.*
import com.android.billingclient.api.BillingClient
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.test.*
import org.junit.Assert.*
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class FoundationTest {
    class FakeBilling : BillingGateway {
        override var onUpdate: (PurchaseOutcome) -> Unit = {}
        var failType: String? = null
        var subs = emptyList<OwnedPurchase>()
        var oneTime = emptyList<OwnedPurchase>()
        var slowType: String? = null
        var acknowledgements = 0
        var ackFailures = 0
        override suspend fun connect() = Unit
        override suspend fun products(type: String, ids: List<String>) = emptyList<PremiumPlan>()
        override suspend fun purchases(type: String): List<OwnedPurchase> {
            if (type == slowType) delay(10)
            if (type == failType) error("expected")
            return if (type == BillingClient.ProductType.SUBS) subs else oneTime
        }
        override suspend fun acknowledge(token: String) { acknowledgements++; if (acknowledgements <= ackFailures) error("expected") }
        override fun launch(activity: Activity, plan: PremiumPlan) = false
        override fun close() = Unit
    }
    private fun bought(id: String, pending: Boolean = false, acknowledged: Boolean = true) = OwnedPurchase(listOf(id), "test-token", acknowledged, pending)
    @Test fun subscriptionSurvivesEmptyOneTimeResultInEitherOrder() = runTest {
        for (slow in listOf(BillingClient.ProductType.INAPP, BillingClient.ProductType.SUBS)) {
            val gateway = FakeBilling().apply { slowType = slow; subs = listOf(bought(PremiumStore.monthlyProductId)) }
            val store = PremiumStore(gateway, scope = backgroundScope)
            store.refresh()
            assertTrue(store.hasPremiumAccess)
            val checked = store.entitlement.checkedAt
            gateway.failType = BillingClient.ProductType.SUBS; gateway.subs = emptyList()
            store.refresh()
            assertTrue(store.hasPremiumAccess)
            assertEquals(checked, store.entitlement.checkedAt)
            assertEquals(EntitlementState.FAILED, store.entitlement.state)
            gateway.failType = BillingClient.ProductType.INAPP
            store.refresh()
            assertFalse(store.hasPremiumAccess) // confirmed subscription expiration, even if INAPP fails
            assertEquals(EntitlementState.FAILED, store.entitlement.state)
        }
    }
    @Test fun completeSnapshotRemovesExpiredAccessAndPendingGrantsNothing() = runTest {
        val gateway = FakeBilling().apply { oneTime = listOf(bought(PremiumStore.lifetimeProductId)) }
        val store = PremiumStore(gateway, scope = backgroundScope)
        store.refresh(); assertTrue(store.hasPremiumAccess)
        gateway.oneTime = emptyList(); gateway.subs = listOf(bought(PremiumStore.monthlyProductId, pending = true))
        store.refresh(); assertFalse(store.hasPremiumAccess)
    }
    @Test fun pendingCancelledFailedAndEmptyRestoreHaveDistinctResults() = runTest {
        for ((outcome, event) in listOf(PurchaseOutcome.PENDING to AppEvent.PURCHASE_PENDING, PurchaseOutcome.CANCELLED to AppEvent.PURCHASE_CANCELLED, PurchaseOutcome.FAILED to AppEvent.PURCHASE_FAILED)) {
            val gateway = FakeBilling()
            val events = mutableListOf<AppEvent>()
            val analytics = object : AnalyticsClient {
                override fun track(event: AppEvent) { events += event }
                override fun setNickname(nickname: String) = Unit
            }
            val store = PremiumStore(gateway, analytics, backgroundScope)
            gateway.onUpdate(outcome); runCurrent()
            assertEquals(listOf(event), events)
            assertFalse(store.hasPremiumAccess)
            if (outcome == PurchaseOutcome.CANCELLED) assertNull(store.messageRes)
            if (outcome == PurchaseOutcome.PENDING) assertEquals(R.string.foundation_pending, store.messageRes)
            if (outcome == PurchaseOutcome.FAILED) assertEquals(R.string.foundation_purchase_failed, store.messageRes)
            store.restore(); runCurrent()
            assertEquals(EntitlementState.FREE, store.entitlement.state)
            assertEquals(AppEvent.PURCHASE_RESTORED, events.last())
        }
    }
    @Test fun acknowledgementRetriesTransientFailure() = runTest {
        val gateway = FakeBilling().apply { subs = listOf(bought(PremiumStore.monthlyProductId, acknowledged = false)); ackFailures = 2 }
        val store = PremiumStore(gateway, scope = backgroundScope)
        store.refresh()
        assertEquals(3, gateway.acknowledgements)
        assertTrue(store.hasPremiumAccess)
    }
    @Test fun rewardIsDeliveredAfterDismissalExactlyOnce() {
        val values = mutableListOf<RewardedAdOutcome>()
        val attempt = RewardAttempt { values += it }
        attempt.earn(); assertTrue(values.isEmpty())
        attempt.finish(); attempt.finish(true)
        assertEquals(listOf(RewardedAdOutcome.REWARDED), values)
        RewardAttempt { values += it }.finish()
        RewardAttempt { values += it }.finish(true)
        assertEquals(listOf(RewardedAdOutcome.REWARDED, RewardedAdOutcome.DISMISSED, RewardedAdOutcome.FAILED), values)
    }
    @Test fun unavailableDuplicateAndStaleAdsCompleteExactlyOnce() {
        val gate = RewardGate()
        val first = mutableListOf<RewardedAdOutcome>()
        val second = mutableListOf<RewardedAdOutcome>()
        assertFalse(gate.begin(RewardAttempt { first += it }, false))
        val loading = RewardAttempt { first += it }
        assertTrue(gate.begin(loading, true))
        assertFalse(gate.begin(RewardAttempt { second += it }, true))
        gate.finish(loading, true)
        val next = RewardAttempt { second += it }
        assertTrue(gate.begin(next, true))
        gate.finish(loading)
        assertSame(next, gate.current)
        next.earn(); gate.finish(next); gate.finish(next)
        assertEquals(listOf(RewardedAdOutcome.FAILED, RewardedAdOutcome.FAILED), first)
        assertEquals(listOf(RewardedAdOutcome.FAILED, RewardedAdOutcome.REWARDED), second)
    }
    @Test fun readFailurePreservesDataAndDoesNotCompleteOnboarding() = runTest {
        var writes = 0
        val repo = object : PreferenceRepository {
            override val values: Flow<Map<String, String>> = flow { error("expected") }
            override suspend fun write(values: Map<String, String>) { writes++ }
        }
        val store = OnboardingStore(repo, scope = backgroundScope)
        runCurrent()
        assertEquals(LoadState.FAILED, store.loadState)
        assertFalse(store.complete("Name")); assertEquals(0, writes)
    }
    @Test fun delayedReadDoesNotExposeFirstLaunchAndFailedSaveCanRetry() = runTest {
        var fails = true
        val data = MutableSharedFlow<Map<String, String>>(replay = 1)
        val repo = object : PreferenceRepository {
            override val values = data
            override suspend fun write(values: Map<String, String>) { if (fails) error("expected"); data.emit(values) }
        }
        val events = mutableListOf<AppEvent>()
        val analytics = object : AnalyticsClient {
            override fun track(event: AppEvent) { events += event }
            override fun setNickname(nickname: String) = Unit
        }
        val store = OnboardingStore(repo, analytics, backgroundScope)
        runCurrent(); assertEquals(LoadState.LOADING, store.loadState)
        data.emit(emptyMap()); runCurrent()
        store.complete(" Name "); runCurrent()
        assertFalse(store.hasCompletedOnboarding); assertTrue(store.saveFailed); assertTrue(events.isEmpty())
        fails = false; store.complete(" Name "); runCurrent()
        assertTrue(store.hasCompletedOnboarding); assertEquals("Name", store.nickname)
        val reopened = OnboardingStore(repo, scope = backgroundScope); runCurrent()
        assertTrue(reopened.hasCompletedOnboarding)
        assertEquals(listOf(AppEvent.ONBOARDING_COMPLETED), events)
    }
    @Test fun failedSettingsWriteKeepsOldTheme() = runTest {
        var fails = true
        val repo = object : PreferenceRepository {
            override val values = MutableStateFlow<Map<String, String>>(emptyMap())
            override suspend fun write(values: Map<String, String>) { if (fails) error("expected"); this.values.value = values }
        }
        val store = SettingsStore(repo, backgroundScope); runCurrent()
        store.setTheme(ThemeMode.DARK); runCurrent()
        assertEquals(ThemeMode.SYSTEM, store.themeMode); assertTrue(store.saveFailed)
        fails = false; store.retry(); runCurrent()
        assertEquals(ThemeMode.DARK, store.themeMode); assertFalse(store.saveFailed)
    }
}
