import java.util.Properties
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.plugin.compose")
}

val localProperties = Properties().apply {
    val localPropertiesFile = rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        localPropertiesFile.inputStream().use { input -> load(input) }
    }
}

fun localValue(key: String, fallback: String): String =
    localProperties.getProperty(key, fallback).trim()

fun quotedBuildConfigValue(value: String): String =
    "\"${value.replace("\\", "\\\\").replace("\"", "\\\"")}\""

val admobAppId = localValue("ADMOB_APP_ID", "ca-app-pub-3940256099942544~3347511713")
val admobBannerId = localValue("ADMOB_BANNER_ID", "ca-app-pub-3940256099942544/6300978111")
val admobNativeId = localValue("ADMOB_NATIVE_ID", "ca-app-pub-3940256099942544/2247696110")
val admobRewardId = localValue("ADMOB_REWARD_ID", "ca-app-pub-3940256099942544/5224354917")
val admobTestDevice = localValue("ADMOB_TEST_DEVICE", "")
val mixpanelToken = localValue("MIXPANEL_TOKEN", "")
val supabaseUrl = localValue("SUPABASE_URL", "https://your-project-ref.supabase.co")
val supabasePublishableKey = localValue("SUPABASE_PUBLISHABLE_KEY", "")
val supabaseRedirectUrl = localValue("SUPABASE_REDIRECT_URL", "com.example.app://auth-callback")

android {
    namespace = "com.boogios.template"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.boogios.template"
        minSdk = 24
        targetSdk = 36
        versionCode = 1
        versionName = "1.0.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables.useSupportLibrary = true

        manifestPlaceholders["ADMOB_APP_ID"] = admobAppId
        buildConfigField("String", "ADMOB_APP_ID", quotedBuildConfigValue(admobAppId))
        buildConfigField("String", "ADMOB_BANNER_ID", quotedBuildConfigValue(admobBannerId))
        buildConfigField("String", "ADMOB_NATIVE_ID", quotedBuildConfigValue(admobNativeId))
        buildConfigField("String", "ADMOB_REWARD_ID", quotedBuildConfigValue(admobRewardId))
        buildConfigField("String", "ADMOB_TEST_DEVICE", quotedBuildConfigValue(admobTestDevice))
        buildConfigField("String", "MIXPANEL_TOKEN", quotedBuildConfigValue(mixpanelToken))
        buildConfigField("String", "SUPABASE_URL", quotedBuildConfigValue(supabaseUrl))
        buildConfigField("String", "SUPABASE_PUBLISHABLE_KEY", quotedBuildConfigValue(supabasePublishableKey))
        buildConfigField("String", "SUPABASE_REDIRECT_URL", quotedBuildConfigValue(supabaseRedirectUrl))
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_17)
        }
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    packaging {
        resources.excludes += "/META-INF/{AL2.0,LGPL2.1}"
    }
}

dependencies {
    val composeBom = platform("androidx.compose:compose-bom:2025.01.01")
    implementation(composeBom)
    androidTestImplementation(composeBom)

    implementation("androidx.activity:activity-compose:1.10.1")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("androidx.datastore:datastore-preferences:1.1.7")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material:material-icons-extended:1.7.8")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.8.7")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.7")
    implementation("androidx.core:core-ktx:1.15.0")
    implementation("com.android.billingclient:billing-ktx:7.1.1")
    implementation("com.google.android.play:review:2.0.2")
    implementation("com.google.android.play:review-ktx:2.0.2")
    implementation("com.google.android.gms:play-services-ads:25.4.0")
    implementation("com.google.android.ump:user-messaging-platform:4.0.0")
    implementation("com.mixpanel.android:mixpanel-android:8.9.0")

    debugImplementation("androidx.compose.ui:ui-tooling")
    debugImplementation("androidx.compose.ui:ui-test-manifest")
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.3.0")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.7.0")
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")
}
