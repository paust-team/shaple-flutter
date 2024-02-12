import 'dart:io';

import 'package:shaple/shaple.dart';
import 'package:test/test.dart';

import 'my_config.dart';


void main() {
  late ShapleClient shaple;
  late ShapleClient adminShaple;
  setUp(() {
    shaple = ShapleClient(
      Config.shapleUrl,
      Config.shapleAnonKey,
      authOptions: const AuthClientOptions(
        autoRefreshToken: true,
        authFlowType: AuthFlowType.implicit,
      ),
    );
    adminShaple = ShapleClient(
      Config.shapleUrl,
      Config.shapleAdminKey,
      authOptions: const AuthClientOptions(
        autoRefreshToken: true,
        authFlowType: AuthFlowType.implicit,
      ),
    );
  });

  tearDown(() async {
    if (shaple.auth.currentSession != null) {
      await shaple.auth.signOut();
    }

    final users = await adminShaple.auth.admin.listUsers();
    for (final user in users) {
      await adminShaple.auth.admin.deleteUser(user.id);
    }

    final buckets = await adminShaple.storage.listBuckets();
    for (final bucket in buckets) {
      await adminShaple.storage.emptyBucket(bucket.id);
      await adminShaple.storage.deleteBucket(bucket.id);
    }

    await shaple.dispose();
    await adminShaple.dispose();
  });

  final signUpAndSignIn = () async {
    await shaple.auth.signUp(
      email: 'dennis.park@paust.io',
      password: 'q2w2e3r4',
    );
    final resp = await shaple.auth.signInWithPassword(
      email: 'dennis.park@paust.io',
      password: 'q2w2e3r4',
    );

    return resp.session;
  };

  test('shaple auth signUp and signIn', () async {
    final session = await signUpAndSignIn();

    expect(session, isNotNull);
    expect(session?.user.email, equals("dennis.park@paust.io"));
  });

  test('create bucket', () async {
    await signUpAndSignIn();

    final bucketId = await shaple.storage.createBucket('test');
    expect(bucketId, equals('test'));
  });

  test('upload file', () async {
    await signUpAndSignIn();

    await shaple.storage.createBucket('test');
    final file = File('./README.md');

    final key = await shaple.storage.from('test').upload(
      'shaple/README.md',
      file,
    );

    expect(key, equals('test/shaple/README.md'));
  });
}