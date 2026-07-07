import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../network/api_exceptions.dart';
import 'envelope.dart';
import 'transport_client.dart';

/// REST half of the relay transport (ARCHITECTURE.md §4.3): the public-key
/// directory and the TTL'd E2E-ciphertext mailbox.
///
/// Every call goes through the shared [ApiClient] Dio singleton, which
/// attaches the Cognito ID token and converts Dio failures into
/// [ApiException]s. Methods here throw those exceptions; the
/// `RelayTransportClient` above translates them into its bool/best-effort
/// contract.
class RelayApi {
  final ApiClient _api = ApiClient();

  /// POST /v1/directory — publish/rotate my public key bundle + push token.
  Future<void> publishDirectory({
    required String edPub,
    required String xPub,
    String? pushToken,
  }) async {
    await _api.post(ApiEndpoints.directory, data: {
      'edPub': edPub,
      'xPub': xPub,
      if (pushToken != null && pushToken.isNotEmpty) 'pushToken': pushToken,
    });
  }

  /// GET /v1/directory/{sub} — fetch a peer's key bundle.
  ///
  /// Returns null when the peer is unknown (404).
  Future<DirectoryEntry?> fetchDirectory(String sub) async {
    try {
      final res = await _api.get<dynamic>(ApiEndpoints.directoryEntry(sub));
      final data = res.data;
      if (data is! Map) return null;
      final json = data.cast<String, dynamic>();
      // Tolerate a response without an echoed `sub` — we asked for it.
      json.putIfAbsent('sub', () => sub);
      return DirectoryEntry.fromJson(json);
    } on NotFoundException {
      return null;
    }
  }

  /// GET /v1/mailbox — drain my pending envelopes.
  ///
  /// Accepts `{"items": [...]}` (the deployed shape), `{"envelopes": [...]}`
  /// or a bare JSON array so a benign backend shape change cannot strand
  /// ciphertext in the mailbox.
  Future<List<Envelope>> mailboxDrain() async {
    final res = await _api.get<dynamic>(ApiEndpoints.mailbox);
    final data = res.data;
    final list = data is Map ? (data['items'] ?? data['envelopes']) : data;
    if (list is! List) return const [];
    return [
      for (final item in list)
        if (item is Map) Envelope.fromJson(item.cast<String, dynamic>()),
    ];
  }

  /// POST /v1/mailbox — deposit an envelope for its recipient. The server
  /// fans it out to the recipient's live inbox topic and stores it (TTL 72 h)
  /// until ACKed.
  Future<void> mailboxDeposit(Envelope envelope) async {
    await _api.post(ApiEndpoints.mailbox, data: envelope.toJson());
  }

  /// DELETE /v1/mailbox/{id} — ACK (delete) a delivered envelope. A 404
  /// (already ACKed or TTL-expired) counts as success.
  Future<void> mailboxAck(String envelopeId) async {
    try {
      await _api.delete(ApiEndpoints.mailboxEnvelope(envelopeId));
    } on NotFoundException {
      // Gone already — the goal (no server copy) is achieved.
    }
  }
}
