import 'dart:async';
import 'dart:math';

import 'package:amazon_cognito_identity_dart_2/sig_v4.dart';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../auth/cognito_auth_service.dart';
import '../config/environment_config.dart';
import '../network/api_exceptions.dart';
import 'envelope.dart';
import 'relay_api.dart';
import 'transport_client.dart';

/// Production [TransportClient] (ARCHITECTURE.md §4).
///
/// * **Live channel** — MQTT over WSS against AWS IoT Core, authenticated
///   with a SigV4-presigned URL built from Identity Pool credentials, and
///   subscribed to `metafter/<stage>/u/<mySub>/inbox` at QoS 1.
/// * **Durable channel** — the REST mailbox via [RelayApi]. Every inbound
///   envelope (live or drained) is deduped by id and best-effort ACKed after
///   emission so the server copy is deleted.
/// * **No IoT endpoint** (`EnvironmentConfig.iotEndpoint` empty — the local
///   docker-compose flavor, and stages not yet deployed): MQTT is skipped
///   entirely and the mailbox is polled every [_pollInterval] while
///   connected. [isConnected] stays false in that mode by design — it
///   reports the *live* channel only.
///
/// Reconnects with exponential backoff (2 s → 60 s, jittered); AWS
/// credentials are re-fetched on every attempt because they expire.
class RelayTransportClient implements TransportClient {
  /// [api] and [random] are injectable for tests only; production code uses
  /// the defaults.
  RelayTransportClient({RelayApi? api, Random? random})
      : _api = api ?? RelayApi(),
        _random = random ?? Random();

  static const String _sigV4Service = 'iotdevicegateway';
  static const Duration _pollInterval = Duration(seconds: 15);

  final RelayApi _api;
  final Random _random;
  final LruIdSet _seen = LruIdSet();
  final StreamController<Envelope> _inbound =
      StreamController<Envelope>.broadcast();

  MqttServerClient? _mqtt;
  Timer? _pollTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;

  /// True between [connect] and [disconnect] — the reconnect/poll machinery
  /// only runs while set.
  bool _wantConnected = false;

  /// Whether this flavor has a live MQTT channel at all.
  bool get _mailboxPollingOnly => EnvironmentConfig.iotEndpoint.isEmpty;

  @override
  Stream<Envelope> get inbound => _inbound.stream;

  @override
  bool get isConnected =>
      _mqtt?.connectionStatus?.state == MqttConnectionState.connected;

  @override
  Future<void> connect() async {
    if (_wantConnected) return; // idempotent
    _wantConnected = true;

    if (_mailboxPollingOnly) {
      _pollTimer = Timer.periodic(_pollInterval, (_) => drainMailbox());
    } else {
      final ok = await _connectMqtt();
      if (ok) {
        _reconnectAttempt = 0;
      } else {
        _scheduleReconnect();
      }
    }
    await drainMailbox();
  }

  @override
  Future<void> disconnect() async {
    _wantConnected = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _reconnectAttempt = 0;
    _teardownMqtt();
  }

  @override
  Future<bool> send(Envelope envelope) async {
    try {
      await _api.mailboxDeposit(envelope);
      return true;
    } on ApiException {
      return false; // caller queues and retries
    }
  }

  @override
  Future<void> drainMailbox() async {
    List<Envelope> envelopes;
    try {
      envelopes = await _api.mailboxDrain();
    } on ApiException {
      // Best-effort: the next poll/foreground/reconnect drain retries.
      return;
    }
    for (final envelope in envelopes) {
      _emit(envelope);
    }
  }

  @override
  Future<bool> publishDirectory({
    required String ed25519Pub,
    required String x25519Pub,
    String? pushToken,
  }) async {
    try {
      await _api.publishDirectory(
        edPub: ed25519Pub,
        xPub: x25519Pub,
        pushToken: pushToken,
      );
      return true;
    } on ApiException {
      return false;
    }
  }

  @override
  Future<DirectoryEntry?> fetchDirectory(String sub) => _api.fetchDirectory(sub);

  // --- inbound path --------------------------------------------------------

  /// Single funnel for every inbound envelope (MQTT and mailbox drains):
  /// emit once per id, then best-effort ACK. Duplicates are ACKed too —
  /// their earlier ACK may not have reached the server (QoS 1 redelivery,
  /// drain racing a live delivery).
  void _emit(Envelope envelope) {
    if (_seen.add(envelope.id)) {
      _inbound.add(envelope);
    }
    unawaited(_api.mailboxAck(envelope.id).catchError((Object _) {}));
  }

  void _onMqttMessages(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final m in messages) {
      final msg = m.payload;
      if (msg is! MqttPublishMessage) continue;
      final text =
          MqttPublishPayload.bytesToStringAsString(msg.payload.message);
      try {
        _emit(Envelope.decode(text));
      } catch (_) {
        // Malformed payload — drop it; nothing decryptable was lost.
      }
    }
  }

  // --- live channel (MQTT over WSS, SigV4) ---------------------------------

  /// One connection attempt. Fetches *fresh* Identity Pool credentials
  /// (they expire, so a presigned URL cannot be reused across attempts),
  /// builds the SigV4 WSS URL and subscribes my inbox topic at QoS 1.
  Future<bool> _connectMqtt() async {
    final auth = CognitoAuthService.instance;
    final AwsSessionCredentials? creds;
    final String? sub;
    try {
      creds = await auth.awsCredentials();
      sub = await auth.currentSub();
    } catch (e) {
      // A credentials fetch over a flaky network throws (SocketException via
      // CognitoClientException) rather than returning null. Left uncaught it
      // escaped the reconnect timer as an unhandled async exception and KILLED
      // the backoff loop — the relay then stayed down for the rest of the
      // session. Treat it like any other failed attempt.
      debugPrint('RelayTransport: credentials fetch failed: $e');
      return false;
    }
    if (creds == null || sub == null) return false;

    final url = _signedWssUrl(creds);
    final clientId = '$sub-${_random.nextInt(1 << 32)}';
    final client = MqttServerClient.withPort(url, clientId, 443)
      ..useWebSocket = true
      ..secure = false // TLS is carried by the wss:// scheme in the URL
      ..websocketProtocols = ['mqtt']
      ..keepAlivePeriod = 30
      ..setProtocolV311()
      ..connectionMessage =
          (MqttConnectMessage().withClientIdentifier(clientId).startClean())
      ..onDisconnected = _onMqttDisconnected;

    _mqtt = client;
    try {
      await client.connect();
    } catch (_) {
      client.disconnect();
      if (identical(_mqtt, client)) _mqtt = null;
      return false;
    }
    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      if (identical(_mqtt, client)) _mqtt = null;
      return false;
    }

    client.updates?.listen(_onMqttMessages);
    final stage = EnvironmentConfig.backendStage;
    client.subscribe('metafter/$stage/u/$sub/inbox', MqttQos.atLeastOnce);
    return true;
  }

  void _onMqttDisconnected() {
    if (!_wantConnected) return; // deliberate disconnect()
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (!_wantConnected || _reconnectTimer != null) return;
    final delay = reconnectDelay(_reconnectAttempt++, _random.nextDouble());
    _reconnectTimer = Timer(delay, () async {
      _reconnectTimer = null;
      if (!_wantConnected) return;
      // Nothing thrown here may escape: an unhandled exception ends the timer
      // chain and the relay never reconnects for the rest of the session.
      bool ok;
      try {
        ok = await _connectMqtt();
      } catch (e) {
        debugPrint('RelayTransport: reconnect attempt failed: $e');
        ok = false;
      }
      if (!_wantConnected) {
        _teardownMqtt();
        return;
      }
      if (ok) {
        _reconnectAttempt = 0;
        // Catch up on envelopes deposited while the live channel was down.
        try {
          await drainMailbox();
        } catch (e) {
          debugPrint('RelayTransport: mailbox drain failed: $e');
        }
      } else {
        _scheduleReconnect();
      }
    });
  }

  void _teardownMqtt() {
    final client = _mqtt;
    _mqtt = null;
    client?.disconnect();
  }

  /// Delay before reconnect attempt [attempt] (0-based).
  ///
  /// Exponential base `2s * 2^attempt` capped at 60 s, scaled by a jitter
  /// factor in `[0.5, 1.0]` ([jitter] ∈ [0, 1]) and clamped back into the
  /// 2 s … 60 s window, so concurrent clients don't reconnect in lockstep.
  static Duration reconnectDelay(int attempt, double jitter) {
    assert(attempt >= 0 && jitter >= 0 && jitter <= 1);
    final baseMs = min(2000 * (1 << min(attempt, 10)), 60000);
    final jitteredMs = (baseMs * (0.5 + 0.5 * jitter)).round();
    return Duration(milliseconds: jitteredMs.clamp(2000, 60000));
  }

  /// Builds the SigV4-presigned `wss://<endpoint>/mqtt?...` URL that AWS IoT
  /// requires for WebSocket connections authenticated with temporary creds.
  String _signedWssUrl(AwsSessionCredentials creds) {
    final host = EnvironmentConfig.iotEndpoint;
    final region = EnvironmentConfig.region;
    final datetime = SigV4.generateDatetime();
    final credentialScope =
        SigV4.buildCredentialScope(datetime, region, _sigV4Service);

    final queryParams = <String, String>{
      'X-Amz-Algorithm': 'AWS4-HMAC-SHA256',
      'X-Amz-Credential': '${creds.accessKeyId}/$credentialScope',
      'X-Amz-Date': datetime,
      'X-Amz-SignedHeaders': 'host',
    };

    final canonicalRequest = SigV4.buildCanonicalRequest(
      'GET',
      '/mqtt',
      queryParams,
      {'host': host},
      '',
    );
    final stringToSign = SigV4.buildStringToSign(
      datetime,
      credentialScope,
      SigV4.hashCanonicalRequest(canonicalRequest),
    );
    final signingKey = SigV4.calculateSigningKey(
        creds.secretAccessKey, datetime, region, _sigV4Service);
    final signature = SigV4.calculateSignature(signingKey, stringToSign);

    final canonicalQuery = SigV4.buildCanonicalQueryString(queryParams);
    final securityToken = Uri.encodeQueryComponent(creds.sessionToken);
    return 'wss://$host/mqtt?$canonicalQuery'
        '&X-Amz-Signature=$signature'
        '&X-Amz-Security-Token=$securityToken';
  }
}

/// Fixed-capacity set of recently-seen envelope ids, used to emit each
/// envelope exactly once when the live channel and a mailbox drain deliver
/// the same copy (or QoS 1 redelivers).
///
/// Backed by a [LinkedHashSet] in insertion order; a re-seen id is refreshed
/// to most-recent, and the least-recently-seen id is evicted past [capacity].
class LruIdSet {
  LruIdSet({this.capacity = 500}) : assert(capacity > 0);

  /// Maximum number of ids retained.
  final int capacity;

  // Dart's default Set literal is a LinkedHashSet (insertion-ordered).
  final Set<String> _ids = <String>{};

  /// Records [id]. Returns true if it was NOT seen before (i.e. the caller
  /// should emit), false for a duplicate.
  bool add(String id) {
    if (_ids.remove(id)) {
      _ids.add(id); // refresh recency
      return false;
    }
    _ids.add(id);
    if (_ids.length > capacity) {
      _ids.remove(_ids.first);
    }
    return true;
  }

  /// Whether [id] is currently tracked (does not refresh recency).
  bool contains(String id) => _ids.contains(id);

  int get length => _ids.length;
}
