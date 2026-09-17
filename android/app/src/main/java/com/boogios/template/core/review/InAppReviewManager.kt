package com.boogios.template.core.review

import android.app.Activity
import android.content.Context
import com.google.android.play.core.review.ReviewManagerFactory

class InAppReviewManager(context: Context) {
    private val reviewManager = ReviewManagerFactory.create(context.applicationContext)

    fun requestReview(activity: Activity) {
        reviewManager.requestReviewFlow().addOnCompleteListener { request ->
            if (!request.isSuccessful || activity.isFinishing || activity.isDestroyed) {
                return@addOnCompleteListener
            }

            // Google Play decides whether and when the system review sheet is shown.
            reviewManager.launchReviewFlow(activity, request.result)
        }
    }
}
