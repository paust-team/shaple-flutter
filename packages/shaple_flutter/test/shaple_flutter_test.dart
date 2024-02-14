import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shaple_flutter/shaple_flutter.dart';

import 'shaple_flutter_test_stubs.dart';

void main() {
  group("Valid shaple instance", () {
    setUp(() async {
      mockAppLink();
      await Shaple.initialize(
        url: 'https://shaple.io',
        anonKey: 'anonKey',
        headers: {'x-custom-header': 'custom-value'},
        authOptions: FlutterAuthClientOptions(
          localStorage: MockLocalStorage(),
          asyncStorage: MockAsyncStorage(),
        ),
        postgrestOptions: const PostgrestClientOptions(
          schema: 'public',
        ),
        storageOptions: const StorageClientOptions(
          retryAttempts: 3,
        ),
        debug: true,
      );
    });

    tearDown(() async {
      await Shaple.instance.dispose();
    });

    test('Initialize shaple', () async {
      expect(Shaple.instance.initialized, isTrue);
    });
  });
}