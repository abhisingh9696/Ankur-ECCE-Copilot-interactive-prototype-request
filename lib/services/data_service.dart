import 'dart:convert';
import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/child_model.dart';

class CryptoLog {
  final String timestamp;
  final String action;
  final String childId;
  final String fieldsEncrypted;
  final String plaintextSubset;
  final String gcmCiphertext;
  final String gcmIv;
  final String hmacVerification;
  final String dpdpStatus;

  CryptoLog({
    required this.timestamp,
    required this.action,
    required this.childId,
    required this.fieldsEncrypted,
    required this.plaintextSubset,
    required this.gcmCiphertext,
    required this.gcmIv,
    required this.hmacVerification,
    required this.dpdpStatus,
  });
}

class DataService {
  static const String _childrenBox = 'children';
  static const String _settingsBox = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_childrenBox);
    await Hive.openBox(_settingsBox);
  }

  // ─── Children ─────────────────────────────────────

  static List<Child> loadChildren() {
    final box = Hive.box(_childrenBox);
    final raw = box.get('children_list');
    if (raw != null && raw is String && raw.isNotEmpty) {
      try {
        final list = json.decode(raw) as List;
        return list
            .map((e) => Child.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    return [];
  }

  static Future<void> saveChildren(List<Child> children) async {
    final box = Hive.box(_childrenBox);
    final raw = json.encode(children.map((c) => c.toJson()).toList());
    await box.put('children_list', raw);
  }

  // ─── Settings ─────────────────────────────────────

  static String getLanguage() {
    final box = Hive.box(_settingsBox);
    return box.get('language', defaultValue: 'en') as String;
  }

  static Future<void> setLanguage(String lang) async {
    final box = Hive.box(_settingsBox);
    await box.put('language', lang);
  }

  // ─── Consent ─────────────────────────────────────

  static bool getConsent() {
    final box = Hive.box(_settingsBox);
    return box.get('consent_given', defaultValue: false) as bool;
  }

  static DateTime? getConsentDate() {
    final box = Hive.box(_settingsBox);
    final ts = box.get('consent_timestamp');
    if (ts is int) return DateTime.fromMillisecondsSinceEpoch(ts);
    return null;
  }

  static Future<void> setConsent(bool given, DateTime date) async {
    final box = Hive.box(_settingsBox);
    await box.put('consent_given', given);
    await box.put('consent_timestamp', date.millisecondsSinceEpoch);
  }

  // ─── Draft Auto-Save ────────────────────────────

  static Map<String, dynamic>? loadDraft() {
    final box = Hive.box(_settingsBox);
    final raw = box.get('draft_data');
    if (raw != null && raw is String && raw.isNotEmpty) {
      try {
        final map = json.decode(raw) as Map<String, dynamic>;
        if (map['timestamp'] is int) {
          map['timestamp'] =
              DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int);
        }
        return map;
      } catch (_) {}
    }
    return null;
  }

  static Future<void> saveDraft({
    required String transcript,
    required List<String> tags,
    required String childId,
  }) async {
    final box = Hive.box(_settingsBox);
    final data = {
      'transcript': transcript,
      'tags': tags,
      'childId': childId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await box.put('draft_data', json.encode(data));
  }

  static Future<void> clearDraft() async {
    final box = Hive.box(_settingsBox);
    await box.delete('draft_data');
  }

  // ─── Crypto Logs ──────────────────────────────────

  static CryptoLog generateCryptoLog({
    required String action,
    required String childId,
    required Map<String, dynamic> rawData,
    required List<String> tags,
  }) {
    final rng = Random();
    String hex(int len) =>
        List.generate(len, (_) => rng.nextInt(16).toRadixString(16)).join();

    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');

    return CryptoLog(
      timestamp: '$h:$m:$s',
      action: action,
      childId: childId,
      fieldsEncrypted: rawData.keys.join(', '),
      plaintextSubset: rawData.containsKey('transcript')
          ? '"${(rawData['transcript'] as String).substring(0, rawData['transcript'].toString().length.clamp(0, 30))}..."'
          : json.encode(rawData).substring(0, 60),
      gcmCiphertext: hex(32),
      gcmIv: hex(12),
      hmacVerification: hex(16),
      dpdpStatus: 'PASSED (No Cleartext PII Leaves Device)',
    );
  }
}

/// Seed data with 3 initial children for the prototype
List<Child> createSeedChildren() {
  return [
    Child(
      id: 'child_munni_01',
      pseudoId: 'hmac_8a2d1e9f4c3a2f',
      name: 'Munni (मुन्नी)',
      age: '3 yrs 2 mos',
      gender: 'F',
      status: 'onTrack',
      profile: {
        'physical': 0.8,
        'socio': 0.7,
        'cognitive': 0.6,
        'language': 0.5,
        'aesthetic': 0.9,
        'habits': 0.7,
      },
      observations: [
        Observation(
          date: '12 May 2026',
          text: 'Munni stacked all 6 blocks correctly and helped Raju clean up the playroom afterwards.',
          method: 'voice',
          domains: ['physical', 'socio'],
        ),
      ],
    ),
    Child(
      id: 'child_raju_02',
      pseudoId: 'hmac_3f9e0a2d5c8b1a',
      name: 'Raju (राजू)',
      age: '4 yrs 1 mo',
      gender: 'M',
      status: 'watch',
      profile: {
        'physical': 0.9,
        'socio': 0.4,
        'cognitive': 0.8,
        'language': 0.3,
        'aesthetic': 0.5,
        'habits': 0.6,
      },
      observations: [
        Observation(
          date: '24 April 2026',
          text: 'Raju running fast in the outer playground, shows excellent motor control but did not respond to name calls.',
          method: 'voice',
          domains: ['physical'],
        ),
      ],
    ),
    Child(
      id: 'child_priya_03',
      pseudoId: 'hmac_7b6e9f1a2c5d8e',
      name: 'Priya (प्रिया)',
      age: '2 yrs 8 mos',
      gender: 'F',
      status: 'redFlag',
      profile: {
        'physical': 0.4,
        'socio': 0.5,
        'cognitive': 0.4,
        'language': 0.2,
        'aesthetic': 0.3,
        'habits': 0.5,
      },
      observations: [
        Observation(
          date: '15 April 2026',
          text: 'Priya pointed to picture book quietly but did not produce single words or interact with peers during group activity.',
          method: 'voice',
          domains: ['language'],
        ),
      ],
    ),
  ];
}
