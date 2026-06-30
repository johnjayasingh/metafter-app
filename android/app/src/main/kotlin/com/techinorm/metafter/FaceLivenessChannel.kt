package com.techinorm.metafter

import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Bridges the Dart `metafter/face_liveness` channel to the native Amazon
 * Rekognition Face Liveness UI (com.amplifyframework.ui:liveness), which is
 * hosted in [FaceLivenessActivity]. The pass/fail verdict is resolved
 * server-side afterwards via `verify-identity`; this only drives the challenge.
 */
object FaceLivenessChannel {
  const val CHANNEL = "metafter/face_liveness"

  // The liveness UI runs in its own Activity; this holds the in-flight Dart
  // result until that Activity reports completion (same process, main thread).
  @Volatile private var pending: MethodChannel.Result? = null

  fun register(engine: FlutterEngine, context: Context) {
    MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
      when (call.method) {
        "startLiveness" -> {
          if (pending != null) {
            result.error("busy", "A liveness check is already in progress", null)
            return@setMethodCallHandler
          }
          val sessionId = call.argument<String>("sessionId")
          val region = call.argument<String>("region")
          val accessKeyId = call.argument<String>("accessKeyId")
          val secretAccessKey = call.argument<String>("secretAccessKey")
          val sessionToken = call.argument<String>("sessionToken")
          if (sessionId == null || region == null || accessKeyId == null ||
            secretAccessKey == null || sessionToken == null
          ) {
            result.error("bad_args", "Missing liveness arguments", null)
            return@setMethodCallHandler
          }
          pending = result
          val intent = Intent(context, FaceLivenessActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            putExtra("sessionId", sessionId)
            putExtra("region", region)
            putExtra("accessKeyId", accessKeyId)
            putExtra("secretAccessKey", secretAccessKey)
            putExtra("sessionToken", sessionToken)
          }
          context.startActivity(intent)
        }
        else -> result.notImplemented()
      }
    }
  }

  /** Called by [FaceLivenessActivity] when the challenge finishes. */
  fun deliverSuccess() {
    pending?.success(null)
    pending = null
  }

  fun deliverError(code: String, message: String?) {
    pending?.error(code, message, null)
    pending = null
  }
}
