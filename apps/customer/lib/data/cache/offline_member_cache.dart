import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/model/member.dart';

/// Durable, user-scoped storage for the minimum material needed to render a
/// membership QR without a network connection.
///
/// Verification, roles, loyalty, and other server-owned state are
/// intentionally never cached here. A cached entry is a display identifier,
/// not proof of identity or authorization.
abstract interface class OfflineMemberCache {
  Future<void> write({required String userId, required Member member});

  Future<Member?> read({required String userId, required String email});

  Future<void> remove(String userId);
}

class SharedPreferencesOfflineMemberCache implements OfflineMemberCache {
  SharedPreferencesOfflineMemberCache({
    Future<SharedPreferences> Function()? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance;

  static const _keyPrefix = 'aida.offline-member.v1.';

  final Future<SharedPreferences> Function() _preferences;

  @override
  Future<void> write({required String userId, required Member member}) async {
    final preferences = await _preferences();
    await preferences.setString(
      _key(userId),
      jsonEncode(<String, Object>{
        'userId': userId,
        'memberId': member.id,
        'memberCode': member.memberCode,
      }),
    );
  }

  @override
  Future<Member?> read({required String userId, required String email}) async {
    final preferences = await _preferences();
    final raw = preferences.getString(_key(userId));
    if (raw == null) return null;

    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic> || json['userId'] != userId) {
        await preferences.remove(_key(userId));
        return null;
      }

      final memberId = json['memberId'];
      final memberCode = json['memberCode'];
      if (memberId is! String ||
          memberId.isEmpty ||
          memberCode is! String ||
          memberCode.isEmpty) {
        await preferences.remove(_key(userId));
        return null;
      }

      return Member(
        id: memberId,
        memberCode: memberCode,
        name: _offlineDisplayName(email),
        email: email,
        studentStatus: StudentStatus.none,
      );
    } on FormatException {
      await preferences.remove(_key(userId));
      return null;
    }
  }

  @override
  Future<void> remove(String userId) async {
    final preferences = await _preferences();
    await preferences.remove(_key(userId));
  }

  static String _key(String userId) => '$_keyPrefix$userId';

  static String _offlineDisplayName(String email) {
    final localPart = email.split('@').first.trim();
    return localPart.isEmpty ? 'Aida Member' : localPart;
  }
}
