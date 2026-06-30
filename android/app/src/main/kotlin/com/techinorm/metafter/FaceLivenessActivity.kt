package com.techinorm.metafter

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import com.amplifyframework.auth.AWSCredentials
import com.amplifyframework.auth.AWSCredentialsProvider
import com.amplifyframework.auth.AuthException
import com.amplifyframework.core.Consumer
import com.amplifyframework.ui.liveness.ui.FaceLivenessDetector
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
      FaceLivenessDetector(
        sessionId = sessionId,
        region = region,
        credentialsProvider = credentialsProvider,
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
