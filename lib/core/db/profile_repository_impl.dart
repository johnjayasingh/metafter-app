import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../crypto/crypto_service.dart';
import '../domain/models.dart';
import '../repositories/repositories.dart';

/// sqflite-backed [ProfileRepository]: the single `my_profile` row plus the
/// privacy-filtered [ProfileCard] builder used by every broadcast/handshake.
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._db, this._settings);

  final Database _db;
  final SettingsRepository _settings;

  final _profile = ValueNotifier<MyProfile?>(null);

  /// Thumbnail cache: path it was generated from -> base64 PNG.
  String? _thumbSourcePath;
  String? _thumbB64;

  /// Target width of the broadcast photo thumbnail, in pixels.
  static const int thumbTargetWidth = 128;

  @override
  ValueListenable<MyProfile?> get profile => _profile;

  @override
  Future<void> load() async {
    final rows = await _db.query('my_profile', limit: 1);
    _profile.value = rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<void> save(MyProfile profile) async {
    await _db.insert(
      'my_profile',
      {
        'id': 1,
        'sub': profile.sub,
        'name': profile.name,
        'role': profile.role,
        'designation': profile.designation,
        'company': profile.company,
        'intro': profile.intro,
        'photo_path': profile.photoPath,
        'verified': profile.verified ? 1 : 0,
        'verified_badge_sig': profile.verifiedBadgeSig,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if (profile.photoPath != _thumbSourcePath) {
      _thumbSourcePath = null;
      _thumbB64 = null;
    }
    _profile.value = profile;
  }

  @override
  Future<void> markVerified(String badgeSig) async {
    final current = _profile.value;
    if (current == null) {
      throw StateError('markVerified called before a profile was saved');
    }
    await save(current.copyWith(verified: true, verifiedBadgeSig: badgeSig));
  }

  @override
  Future<ProfileCard> buildCard() async {
    final p = _profile.value;
    if (p == null) {
      throw StateError('buildCard called before a profile was saved');
    }

    // Privacy filtering — the broadcast card goes to strangers, so anything
    // scoped tighter than "visible to all" is withheld (connections already
    // hold the full card from the accept handshake).
    final name = switch (_settings.nameVisibility.value) {
      PrivacyVisibility.visibleToAll => p.name,
      PrivacyVisibility.visibleToConnections => _firstName(p.name),
      PrivacyVisibility.hidden => '',
    };
    final showCompany = _settings.showCompany.value &&
        _settings.companyVisibility.value == PrivacyVisibility.visibleToAll;
    final showDesignation = _settings.showDesignation.value;

    final crypto = CryptoService.instance;
    return ProfileCard(
      sub: p.sub,
      name: name,
      role: p.role,
      designation: showDesignation ? p.designation : '',
      company: showCompany ? p.company : '',
      intro: p.intro,
      verified: p.verified,
      photoBase64: await _thumbnail(p.photoPath),
      ed25519Pub: crypto.isInitialized ? crypto.ed25519PubB64 : null,
      x25519Pub: crypto.isInitialized ? crypto.x25519PubB64 : null,
    );
  }

  @override
  Future<void> clear() async {
    await _db.delete('my_profile');
    _thumbSourcePath = null;
    _thumbB64 = null;
    _profile.value = null;
  }

  /// Downscale the profile photo at [path] to a ~[thumbTargetWidth]px PNG and
  /// return it base64-encoded. Returns null (and the card falls back to
  /// initials) when the file is missing or undecodable. Cached per path.
  Future<String?> _thumbnail(String? path) async {
    if (path == null || path.isEmpty) return null;
    if (path == _thumbSourcePath) return _thumbB64;
    ui.Codec? codec;
    ui.Image? image;
    try {
      final bytes = await File(path).readAsBytes();
      codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: thumbTargetWidth,
      );
      final frame = await codec.getNextFrame();
      image = frame.image;
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return null;
      final b64 = base64Encode(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      _thumbSourcePath = path;
      _thumbB64 = b64;
      return b64;
    } catch (_) {
      // Missing/corrupt file — broadcast without a photo.
      return null;
    } finally {
      image?.dispose();
      codec?.dispose();
    }
  }

  static String _firstName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? '' : parts.first;
  }

  static MyProfile _fromRow(Map<String, Object?> row) => MyProfile(
        sub: row['sub'] as String,
        name: row['name'] as String? ?? '',
        role: row['role'] as String? ?? '',
        designation: row['designation'] as String? ?? '',
        company: row['company'] as String? ?? '',
        intro: row['intro'] as String? ?? '',
        photoPath: row['photo_path'] as String?,
        verified: (row['verified'] as int? ?? 0) != 0,
        verifiedBadgeSig: row['verified_badge_sig'] as String?,
      );
}
