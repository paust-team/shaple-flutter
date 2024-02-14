import 'package:shaple_flutter/shaple_flutter.dart';

class FlutterAuthClientOptions extends AuthClientOptions {
  final LocalStorage? localStorage;

  const FlutterAuthClientOptions({
    super.authFlowType,
    super.autoRefreshToken,
    super.asyncStorage,
    this.localStorage,
  });

  FlutterAuthClientOptions copyWith({
    AuthFlowType? authFlowType,
    bool? autoRefreshToken,
    LocalStorage? localStorage,
    dynamic asyncStorage,
  }) {
    return FlutterAuthClientOptions(
      authFlowType: authFlowType ?? this.authFlowType,
      autoRefreshToken: autoRefreshToken ?? this.autoRefreshToken,
      localStorage: localStorage ?? this.localStorage,
      asyncStorage: asyncStorage ?? this.asyncStorage,
    );
  }
}
