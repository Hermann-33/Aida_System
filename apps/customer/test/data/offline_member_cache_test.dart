import 'dart:convert';

import 'package:aida_customer/data/cache/offline_member_cache.dart';
import 'package:aida_customer/domain/model/member.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferencesOfflineMemberCache cache;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    cache = SharedPreferencesOfflineMemberCache();
  });

  test('persists only minimum offline QR identity material', () async {
    await cache.write(
      userId: 'user-a',
      member: const Member(
        id: 'member-a',
        memberCode: 'AIDA-ABC1234567',
        name: 'Verified Person',
        email: 'person@example.test',
        phone: '+60123456789',
        studentStatus: StudentStatus.verified,
        tierName: 'Gold Member',
      ),
    );

    final restored = await cache.read(
      userId: 'user-a',
      email: 'person@example.test',
    );
    final preferences = await SharedPreferences.getInstance();
    final persisted =
        jsonDecode(preferences.getString('aida.offline-member.v1.user-a')!)
            as Map<String, dynamic>;

    expect(
      persisted.keys,
      unorderedEquals(['userId', 'memberId', 'memberCode']),
    );
    expect(restored?.id, 'member-a');
    expect(restored?.memberCode, 'AIDA-ABC1234567');
    expect(restored?.name, 'person');
    expect(restored?.studentStatus, StudentStatus.none);
    expect(restored?.phone, isNull);
    expect(restored?.tierName, isNull);
  });

  test('isolates entries by authenticated user', () async {
    await cache.write(
      userId: 'user-a',
      member: const Member(
        id: 'member-a',
        memberCode: 'AIDA-ABC1234567',
        name: 'Person',
        email: 'person@example.test',
        studentStatus: StudentStatus.none,
      ),
    );

    expect(
      await cache.read(userId: 'user-b', email: 'other@example.test'),
      isNull,
    );
  });

  test('removes the current user entry on cleanup', () async {
    await cache.write(
      userId: 'user-a',
      member: const Member(
        id: 'member-a',
        memberCode: 'AIDA-ABC1234567',
        name: 'Person',
        email: 'person@example.test',
        studentStatus: StudentStatus.none,
      ),
    );

    await cache.remove('user-a');

    expect(
      await cache.read(userId: 'user-a', email: 'person@example.test'),
      isNull,
    );
  });

  test('rejects malformed cached data', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'aida.offline-member.v1.user-a': '{broken',
    });
    cache = SharedPreferencesOfflineMemberCache();

    expect(
      await cache.read(userId: 'user-a', email: 'person@example.test'),
      isNull,
    );
  });
}
