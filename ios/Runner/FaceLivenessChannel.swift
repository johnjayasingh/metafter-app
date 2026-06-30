import Flutter
import UIKit
import SwiftUI

// Amazon Rekognition Face Liveness — official Amplify UI SwiftUI component.
//
// SETUP (one-time, in Xcode — cannot be expressed in the Podfile because this
// SDK ships via Swift Package Manager only):
//   File ▸ Add Package Dependencies… ▸
//   https://github.com/aws-amplify/amplify-ui-swift-liveness
//   Add these products to the Runner target:
//     • FaceLiveness        (the liveness UI)
//     • Amplify             (transitively from amplify-swift)
//     • AWSPluginsCore      (AWSCredentialsProvider / AWSTemporaryCredentials)
//
// The `#if canImport(FaceLiveness)` guards let the app build & run (returning a
// graceful "unavailable" error to Dart) before the packages are added.
#if canImport(FaceLiveness)
import FaceLiveness
import Amplify
import AWSPluginsCore
#endif

/// Bridges the Dart `metafter/face_liveness` channel to the native Face
/// Liveness UI. The pass/fail verdict is resolved server-side afterwards via
/// `verify-identity`; this only drives the camera challenge.
final class FaceLivenessChannel: NSObject {
  static let channelName = "metafter/face_liveness"

  static func register(with controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: channelName, binaryMessenger: controller.binaryMessenger)
    let instance = FaceLivenessChannel()
    channel.setMethodCallHandler { [weak controller] call, result in
      guard let controller = controller else { return }
      instance.handle(call, result: result, host: controller)
    }
  }

  private func handle(
    _ call: FlutterMethodCall, result: @escaping FlutterResult, host: UIViewController
  ) {
    guard call.method == "startLiveness" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard let args = call.arguments as? [String: Any],
      let sessionId = args["sessionId"] as? String,
      let region = args["region"] as? String,
      let accessKeyId = args["accessKeyId"] as? String,
      let secretKey = args["secretAccessKey"] as? String,
      let sessionToken = args["sessionToken"] as? String
    else {
      result(FlutterError(code: "bad_args", message: "Missing liveness arguments", details: nil))
      return
    }

    #if canImport(FaceLiveness)
    present(
      sessionId: sessionId, region: region, accessKeyId: accessKeyId,
      secretKey: secretKey, sessionToken: sessionToken, host: host, result: result)
    #else
    result(
      FlutterError(
        code: "unavailable",
        message: "FaceLiveness SDK not linked. Add it via Swift Package Manager.",
        details: nil))
    #endif
  }

  #if canImport(FaceLiveness)
  private func present(
    sessionId: String, region: String, accessKeyId: String, secretKey: String,
    sessionToken: String, host: UIViewController, result: @escaping FlutterResult
  ) {
    let credentialsProvider = StaticAWSCredentialsProvider(
      accessKeyId: accessKeyId, secretAccessKey: secretKey, sessionToken: sessionToken)

    // Single idempotent sink: dismiss the UI and resolve the Dart future exactly
    // once, whatever path (success / failure / presentation failure) gets here.
    var didReturn = false
    var hosting: UIViewController?
    func finish(_ value: Any?) {
      guard !didReturn else { return }
      didReturn = true
      DispatchQueue.main.async {
        hosting?.dismiss(animated: true)
        result(value)
      }
    }

    let isPresented = Binding<Bool>(get: { true }, set: { _ in })
    let view = FaceLivenessDetectorView(
      sessionID: sessionId,
      credentialsProvider: credentialsProvider,
      region: region,
      isPresented: isPresented,
      onCompletion: { completion in
        switch completion {
        case .success:
          finish(nil)  // challenge completed; backend decides pass/fail
        case .failure(let error):
          finish(
            FlutterError(
              code: "liveness_failed", message: String(describing: error), details: nil))
        }
      }
    )

    let controller = UIHostingController(rootView: view)
    controller.modalPresentationStyle = .fullScreen
    hosting = controller

    // Presenting on top of an existing modal silently no-ops in UIKit, which
    // would hang the Dart future — dismiss anything in flight first.
    let doPresent = { host.present(controller, animated: true) }
    if let presented = host.presentedViewController {
      presented.dismiss(animated: false, completion: doPresent)
    } else {
      doPresent()
    }
  }
  #endif
}

#if canImport(FaceLiveness)
/// Feeds the Identity-Pool temporary credentials (already minted by the Dart
/// side for IoT) into the liveness SDK, so we don't need full Amplify.Auth.
///
/// NOTE: verify the protocol/return type against the installed
/// `amplify-ui-swift-liveness` version — recent versions expose
/// `AWSCredentialsProvider.fetchAWSCredentials() async throws -> AWSCredentials`.
struct StaticAWSCredentialsProvider: AWSCredentialsProvider {
  let accessKeyId: String
  let secretAccessKey: String
  let sessionToken: String

  func fetchAWSCredentials() async throws -> AWSCredentials {
    AWSTemporaryCredentials(
      accessKeyId: accessKeyId,
      secretAccessKey: secretAccessKey,
      sessionToken: sessionToken,
      expiration: Date().addingTimeInterval(50 * 60))
  }
}

/// Minimal concrete `AWSTemporaryCredentials`. If the SDK already exposes a
/// concrete type, use that instead and delete this.
private struct AWSTemporaryCredentials: AWSPluginsCore.AWSTemporaryCredentials {
  let accessKeyId: String
  let secretAccessKey: String
  let sessionToken: String
  let expiration: Date
}
#endif
