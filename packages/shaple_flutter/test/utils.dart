import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Registers the mock handler for uni_links
void mockAppLink({String? initialLink}) {
  const channel = MethodChannel('com.llfbandit.app_links/messages');
  const anotherChannel = MethodChannel('com.llfbandit.app_links/events');

  TestWidgetsFlutterBinding.ensureInitialized();

  // ignore: invalid_null_aware_operator
  TestDefaultBinaryMessengerBinding.instance?.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async => initialLink);

  // ignore: invalid_null_aware_operator
  TestDefaultBinaryMessengerBinding.instance?.defaultBinaryMessenger
      .setMockMethodCallHandler(anotherChannel, (message) async => null);
}