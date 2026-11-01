package com.boogios.template

import androidx.test.platform.app.InstrumentationRegistry
import android.graphics.Bitmap
import java.io.File

fun saveQAScreenshot(name: String) {
    val instrumentation = InstrumentationRegistry.getInstrumentation()
    instrumentation.waitForIdleSync()
    android.os.SystemClock.sleep(500) // Wait for the surface compositor after Compose semantics settle.
    val screenshot = checkNotNull(instrumentation.uiAutomation.takeScreenshot())
    File(instrumentation.targetContext.filesDir, "qa-$name.png").outputStream().use {
        check(screenshot.compress(Bitmap.CompressFormat.PNG, 100, it))
    }
    screenshot.recycle()
}
