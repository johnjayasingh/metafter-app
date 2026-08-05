package com.techinorm.metafter

import android.Manifest
import android.content.pm.PackageManager
import android.content.res.AssetManager
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Typography
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.core.content.ContextCompat
import com.amplifyframework.auth.AWSCredentials
import com.amplifyframework.auth.AWSCredentialsProvider
import com.amplifyframework.auth.AuthException
import com.amplifyframework.core.Consumer
import com.amplifyframework.ui.liveness.ui.FaceLivenessDetector
import com.amplifyframework.ui.liveness.ui.LivenessColorScheme
import java.time.Instant
import java.time.temporal.ChronoUnit

/**
 * Hosts the Amplify Face Liveness Compose UI for a single session, feeding it
 * the Identity-Pool temporary credentials passed from Dart (so we don't need a
 * full Amplify.Auth setup). Results are routed back through [FaceLivenessChannel].
 *
 * NOTE: confirm the [FaceLivenessDetector] parameters and
 * AWSCredentials.createAWSCredentials signature against the installed
 * com.amplifyframework.ui:liveness version — these are version-sensitive.
 */
private val BrandRed = Color(0xFFE32227)
private val Ink = Color(0xFF1A1A1A)

/**
 * MetAfter's palette for the liveness UI.
 *
 * Built by copying the brand roles ONTO Amplify's own scheme rather than
 * hand-rolling a `lightColorScheme(...)`: the liveness screens paint from a
 * dozen-odd roles (containers, outlines, inverse surfaces), and any role left
 * unset falls back to the Material baseline — which is where the stray purple
 * came from.
 */
private val livenessColors = LivenessColorScheme.Defaults.lightColorScheme.copy(
  primary = BrandRed,
  onPrimary = Color.White,
  primaryContainer = BrandRed,
  onPrimaryContainer = Color.White,
  secondary = BrandRed,
  onSecondary = Color.White,
  secondaryContainer = Color(0xFFFCE4E1),
  onSecondaryContainer = Ink,
  tertiary = BrandRed,
  onTertiary = Color.White,
  background = Color.White,
  onBackground = Ink,
  surface = Color.White,
  onSurface = Ink,
  surfaceVariant = Color(0xFFF1F1F1),
  onSurfaceVariant = Color(0xFF5A5A5A),
  outline = Color(0xFFB0B0B0),
  error = BrandRed,
  onError = Color.White,
)

/**
 * The app's typeface, loaded straight out of the Flutter asset bundle so the
 * liveness screens read in Instrument Sans like every other screen instead of
 * the system default.
 */
private fun livenessTypography(assets: AssetManager): Typography {
  fun font(weight: Int, w: FontWeight) = Font(
    path = "flutter_assets/assets/fonts/InstrumentSans-$weight.ttf",
    assetManager = assets,
    weight = w,
  )
  val family = FontFamily(
    font(400, FontWeight.Normal),
    font(500, FontWeight.Medium),
    font(600, FontWeight.SemiBold),
    font(700, FontWeight.Bold),
  )
  val base = Typography()
  return Typography(
    displayLarge = base.displayLarge.copy(fontFamily = family),
    displayMedium = base.displayMedium.copy(fontFamily = family),
    displaySmall = base.displaySmall.copy(fontFamily = family),
    headlineLarge = base.headlineLarge.copy(fontFamily = family),
    headlineMedium = base.headlineMedium.copy(fontFamily = family),
    headlineSmall = base.headlineSmall.copy(fontFamily = family),
    titleLarge = base.titleLarge.copy(fontFamily = family, fontWeight = FontWeight.SemiBold),
    titleMedium = base.titleMedium.copy(fontFamily = family, fontWeight = FontWeight.SemiBold),
    titleSmall = base.titleSmall.copy(fontFamily = family, fontWeight = FontWeight.SemiBold),
    bodyLarge = base.bodyLarge.copy(fontFamily = family),
    bodyMedium = base.bodyMedium.copy(fontFamily = family),
    bodySmall = base.bodySmall.copy(fontFamily = family),
    labelLarge = base.labelLarge.copy(fontFamily = family, fontWeight = FontWeight.SemiBold),
    labelMedium = base.labelMedium.copy(fontFamily = family),
    labelSmall = base.labelSmall.copy(fontFamily = family),
  )
}

class FaceLivenessActivity : ComponentActivity() {
  private var delivered = false

  private lateinit var sessionId: String
  private lateinit var region: String
  private lateinit var accessKeyId: String
  private lateinit var secretAccessKey: String
  private lateinit var sessionToken: String

  // CAMERA is a runtime (dangerous) permission on API 23+; the liveness UI
  // hangs on a blank screen if shown without it, so gate on the grant.
  private val cameraPermission =
    registerForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
      if (granted) {
        showLiveness()
      } else {
        deliverError("camera_denied", "Camera permission denied")
        finish()
      }
    }

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)

    sessionId = intent.getStringExtra("sessionId") ?: return failArgs()
    region = intent.getStringExtra("region") ?: return failArgs()
    accessKeyId = intent.getStringExtra("accessKeyId") ?: return failArgs()
    secretAccessKey = intent.getStringExtra("secretAccessKey") ?: return failArgs()
    sessionToken = intent.getStringExtra("sessionToken") ?: return failArgs()

    if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) ==
      PackageManager.PERMISSION_GRANTED
    ) {
      showLiveness()
    } else {
      cameraPermission.launch(Manifest.permission.CAMERA)
    }
  }

  private fun failArgs() {
    deliverError("bad_args", "Missing liveness arguments")
    finish()
  }

  private fun showLiveness() {
    val credentialsProvider = object : AWSCredentialsProvider<AWSCredentials> {
      override fun fetchAWSCredentials(
        onSuccess: Consumer<AWSCredentials>,
        onError: Consumer<AuthException>,
      ) {
        val creds = AWSCredentials.createAWSCredentials(
          accessKeyId,
          secretAccessKey,
          sessionToken,
          Instant.now().plus(50, ChronoUnit.MINUTES).epochSecond,
        )
        if (creds != null) {
          onSuccess.accept(creds)
        } else {
          onError.accept(
            AuthException("No credentials", "Static liveness credentials were null"))
        }
      }
    }

    setContent {
      // Two things the bare setContent {} got wrong on this screen:
      //
      //  1. No theme. Amplify's liveness UI draws its countdown/scan bar and
      //     controls from MaterialTheme.colorScheme, so with no theme it fell
      //     back to Compose's baseline palette — hence the purple bar.
      //  2. No insets. targetSdk 36 means Android 15+ lays this window out
      //     edge-to-edge, and nothing here consumed the system bars, so the
      //     photosensitivity banner ran under the status bar, the scan bar ran
      //     under the navigation bar, and the face oval was sized against a
      //     viewport taller than the one actually drawable.
      MaterialTheme(
        colorScheme = livenessColors,
        typography = livenessTypography(assets),
      ) {
        Surface(modifier = Modifier.fillMaxSize()) {
          Box(modifier = Modifier.fillMaxSize().safeDrawingPadding()) {
            FaceLivenessDetector(
              sessionId = sessionId,
              region = region,
              credentialsProvider = credentialsProvider,
              // The app presents its own intro on the preceding Flutter
              // screen, so the SDK's start view would be a second, off-brand
              // one. Safe to drop only because the session now asks for the
              // movement-only challenge (see the backend's
              // ChallengePreferences) — that start view carries the
              // photosensitivity warning for the colour-flashing challenge.
              disableStartView = true,
              onComplete = {
                deliverSuccess()
                finish()
              },
              onError = { error ->
                deliverError("liveness_failed", error.message ?: error.toString())
                finish()
              },
            )
          }
        }
      }
    }
  }

  private fun deliverSuccess() {
    if (delivered) return
    delivered = true
    FaceLivenessChannel.deliverSuccess()
  }

  private fun deliverError(code: String, message: String?) {
    if (delivered) return
    delivered = true
    FaceLivenessChannel.deliverError(code, message)
  }

  override fun onDestroy() {
    // Only treat as a cancel if the user left before any terminal callback.
    if (!delivered && isFinishing) {
      deliverError("cancelled", "Liveness cancelled")
    }
    super.onDestroy()
  }
}
