package com.boogios.template

import android.app.Application
import android.content.Context
import androidx.test.runner.AndroidJUnitRunner

class TemplateTestRunner : AndroidJUnitRunner() {
    override fun newApplication(cl: ClassLoader?, className: String?, context: Context?): Application {
        System.setProperty("boogios.test", "true")
        return super.newApplication(cl, className, context)
    }
}
