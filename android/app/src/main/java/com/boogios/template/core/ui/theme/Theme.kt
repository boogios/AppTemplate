package com.boogios.template.core.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import androidx.compose.ui.unit.dp
import com.boogios.template.R
import com.boogios.template.data.settings.ThemeMode

// Mirrors AppTemplate/AppTemplate/Global/Extension/Color+.swift.
val BoogiosMain = Color(0xFF475CEF)
val BoogiosMainSoft = Color(0xFFCBD1FB)
val BoogiosMainSofter = Color(0xFFE9EBFD)
val BoogiosWhite = Color(0xFFFFFFFF)
val BoogiosGray1 = Color(0xFFF7F8FA)
val BoogiosGray2 = Color(0xFFEEF0F4)
val BoogiosGray3 = Color(0xFFDBDEE5)
val BoogiosGray4 = Color(0xFFC3C8D1)
val BoogiosGray5 = Color(0xFF8C929F)
val BoogiosGray6 = Color(0xFF6C7280)
val BoogiosGray7 = Color(0xFF4D525D)
val BoogiosGray8 = Color(0xFF333844)
val BoogiosGray9 = Color(0xFF1B1F27)
val BoogiosGray10 = Color(0xFF0B0D12)

data class BoogiosThemeColors(
    val main: Color,
    val mainSoft: Color,
    val mainSofter: Color,
    val white: Color,
    val gray1: Color,
    val gray2: Color,
    val gray3: Color,
    val gray4: Color,
    val gray5: Color,
    val gray6: Color,
    val gray7: Color,
    val gray8: Color,
    val gray9: Color,
    val gray10: Color,
)

private val LightBoogiosThemeColors = BoogiosThemeColors(
    main = BoogiosMain,
    mainSoft = BoogiosMainSoft,
    mainSofter = BoogiosMainSofter,
    white = BoogiosWhite,
    gray1 = BoogiosGray1,
    gray2 = BoogiosGray2,
    gray3 = BoogiosGray3,
    gray4 = BoogiosGray4,
    gray5 = BoogiosGray5,
    gray6 = BoogiosGray6,
    gray7 = BoogiosGray7,
    gray8 = BoogiosGray8,
    gray9 = BoogiosGray9,
    gray10 = BoogiosGray10,
)

private val DarkBoogiosThemeColors = BoogiosThemeColors(
    main = BoogiosMain,
    mainSoft = Color(0xFF2E3C9B),
    mainSofter = Color(0xFF202B6B),
    white = Color(0xFF1C1C1E),
    gray1 = Color(0xFF000000),
    gray2 = Color(0xFF2C2C2E),
    gray3 = Color(0xFF3A3A3C),
    gray4 = Color(0xFF48484A),
    gray5 = Color(0xFF636366),
    gray6 = Color(0xFF8E8E93),
    gray7 = Color(0xFFAEAEB2),
    gray8 = Color(0xFFC7C7CC),
    gray9 = Color(0xFFF2F2F7),
    gray10 = Color.White,
)

private val LocalBoogiosThemeColors = staticCompositionLocalOf { LightBoogiosThemeColors }

object BoogiosThemeTokens {
    val colors: BoogiosThemeColors
        @Composable
        @ReadOnlyComposable
        get() = LocalBoogiosThemeColors.current
}

object BoogiosSpacing {
    val screen = 20.dp
    val section = 16.dp
    val card = 20.dp
    val content = 12.dp
    val compact = 8.dp
    val touchTarget = 44.dp
}

object BoogiosShapes {
    val card = RoundedCornerShape(16.dp)
    val control = RoundedCornerShape(14.dp)
}

private val LightColors = lightColorScheme(
    primary = BoogiosMain,
    onPrimary = Color.White,
    primaryContainer = BoogiosMainSoft,
    onPrimaryContainer = BoogiosGray9,
    background = BoogiosGray1,
    surface = BoogiosWhite,
    onBackground = BoogiosGray9,
    onSurface = BoogiosGray9,
    outline = BoogiosGray3,
    surfaceVariant = BoogiosGray2,
    onSurfaceVariant = BoogiosGray6,
    outlineVariant = BoogiosGray2,
)

private val DarkColors = darkColorScheme(
    primary = BoogiosMain,
    onPrimary = BoogiosWhite,
    primaryContainer = Color(0xFF2E3C9B),
    onPrimaryContainer = Color(0xFFE9EBFD),
    background = Color(0xFF000000),
    surface = Color(0xFF1C1C1E),
    onBackground = Color(0xFFF2F2F7),
    onSurface = Color(0xFFF2F2F7),
    outline = Color(0xFF3A3A3C),
    surfaceVariant = Color(0xFF2C2C2E),
    onSurfaceVariant = Color(0xFF8E8E93),
    outlineVariant = Color(0xFF2C2C2E),
)

val PretendardFontFamily = FontFamily(
    Font(R.font.pretendard_light, FontWeight.Light),
    Font(R.font.pretendard_regular, FontWeight.Normal),
    Font(R.font.pretendard_medium, FontWeight.Medium),
    Font(R.font.pretendard_semibold, FontWeight.SemiBold),
    Font(R.font.pretendard_bold, FontWeight.Bold),
)

private fun TextStyle.withPretendard(): TextStyle = copy(fontFamily = PretendardFontFamily)

private val AppTypography = Typography().run {
    copy(
        displayLarge = displayLarge.withPretendard(),
        displayMedium = displayMedium.withPretendard(),
        displaySmall = displaySmall.withPretendard(),
        headlineLarge = headlineLarge.copy(
            fontFamily = PretendardFontFamily,
            fontSize = 22.sp,
            fontWeight = FontWeight.Bold,
        ),
        headlineMedium = headlineMedium.copy(
            fontFamily = PretendardFontFamily,
            fontSize = 20.sp,
            fontWeight = FontWeight.Bold,
        ),
        headlineSmall = headlineSmall.copy(
            fontFamily = PretendardFontFamily,
            fontSize = 18.sp,
            fontWeight = FontWeight.Bold,
        ),
        titleLarge = titleLarge.copy(
            fontFamily = PretendardFontFamily,
            fontSize = 18.sp,
            fontWeight = FontWeight.SemiBold,
        ),
        titleMedium = titleMedium.copy(
            fontFamily = PretendardFontFamily,
            fontSize = 16.sp,
            fontWeight = FontWeight.SemiBold,
        ),
        titleSmall = titleSmall.copy(
            fontFamily = PretendardFontFamily,
            fontSize = 14.sp,
            fontWeight = FontWeight.SemiBold,
        ),
        bodyLarge = bodyLarge.copy(
            fontFamily = PretendardFontFamily,
            fontSize = 16.sp,
            lineHeight = 24.sp,
            fontWeight = FontWeight.Normal,
        ),
        bodyMedium = bodyMedium.copy(
            fontFamily = PretendardFontFamily,
            fontSize = 14.sp,
            lineHeight = 21.sp,
            fontWeight = FontWeight.Normal,
        ),
        bodySmall = bodySmall.copy(
            fontFamily = PretendardFontFamily,
            fontSize = 12.sp,
            lineHeight = 18.sp,
            fontWeight = FontWeight.Normal,
        ),
        labelLarge = labelLarge.copy(
            fontFamily = PretendardFontFamily,
            fontSize = 14.sp,
            fontWeight = FontWeight.SemiBold,
        ),
        labelMedium = labelMedium.copy(
            fontFamily = PretendardFontFamily,
            fontSize = 12.sp,
            fontWeight = FontWeight.Medium,
        ),
        labelSmall = labelSmall.copy(
            fontFamily = PretendardFontFamily,
            fontSize = 12.sp,
            fontWeight = FontWeight.Light,
        ),
    )
}

@Composable
fun AppTemplateTheme(themeMode: ThemeMode, content: @Composable () -> Unit) {
    val isDark = when (themeMode) {
        ThemeMode.SYSTEM -> isSystemInDarkTheme()
        ThemeMode.LIGHT -> false
        ThemeMode.DARK -> true
    }
    MaterialTheme(
        colorScheme = if (isDark) DarkColors else LightColors,
        typography = AppTypography,
    ) {
        CompositionLocalProvider(
            LocalBoogiosThemeColors provides if (isDark) DarkBoogiosThemeColors else LightBoogiosThemeColors,
            content = content,
        )
    }
}
