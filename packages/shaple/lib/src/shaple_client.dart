import 'dart:core';

import 'package:gotrue/gotrue.dart';
import 'package:http/http.dart';
import 'package:shaple/src/shaple_client_options.dart';

class ShapleClient {
  late final GoTrueClient auth;

  ShapleClient(
    String shapleUrl,
    String shapleKey, {
    AuthClientOptions authOptions = const AuthClientOptions(),
    Map<String, String>? headers,
    Client? httpClient,
  }) {
    this.auth = GoTrueClient(
      url: "${shapleUrl}/auth/v1",
      headers: headers,
      autoRefreshToken: authOptions.autoRefreshToken,
      httpClient: httpClient,
      asyncStorage: authOptions.pkceAsyncStorage,
      flowType: authOptions.authFlowType,
    );
  }

  Future<void> dispose() async {
    return;
  }
}