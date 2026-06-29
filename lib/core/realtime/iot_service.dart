import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:amazon_cognito_identity_dart_2/sig_v4.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../auth/cognito_auth_service.dart';
import '../config/environment_config.dart';

/// A realtime event pushed from the backend over IoT Core.
class IotEvent {
  IotEvent(this.topic, this.type, this.data);
  final String topic;
  final String type; // 'request.new' | 'request.accepted' | 'message.new'
  final Map<String, dynamic> data;
}

/// Connects to AWS IoT Core over MQTT-WSS (SigV4-signed with Identity Pool
/// credentials) and surfaces inbox + thread events as a broadcast stream.
class IotService {
  IotService._();
  static final IotService instance = IotService._();

  static const String _service = 'iotdevicegateway';

  MqttServerClient? _client;
  final _controller = StreamController<IotEvent>.broadcast();

  Stream<IotEvent> get events => _controller.stream;

  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  /// Establishes the connection and subscribes the signed-in user's inbox.
  /// Returns false if there's no valid session / credentials.
  Future<bool> connect() async {
    if (isConnected) return true;

    final creds = await CognitoAuthService.instance.awsCredentials();
    final sub = await CognitoAuthService.instance.currentSub();
    if (creds == null || sub == null) return false;

    final url = _signedWssUrl(creds);
    final clientId = '$sub-${Random().nextInt(1 << 32)}';

    final client = MqttServerClient.withPort(url, clientId, 443)
      ..useWebSocket = true
      ..secure = false // TLS is carried by the wss:// scheme in the URL
      ..websocketProtocols = ['mqtt']
      ..keepAlivePeriod = 30
      ..setProtocolV311()
      ..connectionMessage =
          (MqttConnectMessage().withClientIdentifier(clientId).startClean());

    _client = client;
    try {
      await client.connect();
    } catch (_) {
      client.disconnect();
      _client = null;
      return false;
    }

    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      _client = null;
      return false;
    }

    client.updates?.listen(_onMessages);

    final stage = EnvironmentConfig.backendStage;
    client.subscribe('metafter/$stage/u/$sub/inbox', MqttQos.atLeastOnce);
    return true;
  }

  /// Subscribe to a chat thread's fanout topic for an active connection.
  void subscribeThread(String threadId) {
    final stage = EnvironmentConfig.backendStage;
    _client?.subscribe('metafter/$stage/threads/$threadId', MqttQos.atLeastOnce);
  }

  void disconnect() {
    _client?.disconnect();
    _client = null;
  }

  void _onMessages(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final m in messages) {
      final recv = m.payload as MqttPublishMessage;
      final text =
          MqttPublishPayload.bytesToStringAsString(recv.payload.message);
      try {
        final json = jsonDecode(text) as Map<String, dynamic>;
        _controller.add(IotEvent(m.topic, json['type'] as String? ?? '', json));
      } catch (_) {
        // ignore malformed payloads
      }
    }
  }

  /// Builds the SigV4-presigned `wss://<endpoint>/mqtt?...` URL that AWS IoT
  /// requires for WebSocket connections authenticated with temporary creds.
  String _signedWssUrl(AwsSessionCredentials creds) {
    final host = EnvironmentConfig.iotEndpoint;
    final region = EnvironmentConfig.region;
    final datetime = SigV4.generateDatetime();
    final credentialScope = SigV4.buildCredentialScope(datetime, region, _service);

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
    final signingKey =
        SigV4.calculateSigningKey(creds.secretAccessKey, datetime, region, _service);
    final signature = SigV4.calculateSignature(signingKey, stringToSign);

    final canonicalQuery = SigV4.buildCanonicalQueryString(queryParams);
    final securityToken = Uri.encodeQueryComponent(creds.sessionToken);
    return 'wss://$host/mqtt?$canonicalQuery'
        '&X-Amz-Signature=$signature'
        '&X-Amz-Security-Token=$securityToken';
  }
}
