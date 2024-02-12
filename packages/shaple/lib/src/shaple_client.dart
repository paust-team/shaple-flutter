import 'dart:async';
import 'dart:core';

import 'package:gotrue/gotrue.dart';
import 'package:http/http.dart';
import 'package:shaple/src/shaple_client_options.dart';
import 'package:storage_client/storage_client.dart';

import 'constants.dart';

class ShapleClient {
  final Client? _httpClient;
  final Map<String, String> _headers;
  final String _shapleKey;
  final String _shapleUrl;

  late final GoTrueClient auth;
  late final SupabaseStorageClient storage;
  late StreamSubscription<AuthState> _authStateSubscription;

  ShapleClient(
    this._shapleUrl,
    this._shapleKey, {
    AuthClientOptions authOptions = const AuthClientOptions(),
    StorageClientOptions storageOptions = const StorageClientOptions(),
    Map<String, String>? headers,
    Client? httpClient,
  })  : _httpClient = httpClient,
        _headers = {...DEFAULT_HEADERS, if (headers != null) ...headers} {
    this.auth = _initAuthClient(
      autoRefreshToken: authOptions.autoRefreshToken,
      gotrueAsyncStorage: authOptions.pkceAsyncStorage,
      authFlowType: authOptions.authFlowType,
    );
    this.storage = _initStorageClient(storageOptions.retryAttempts);
    _listenForAuthEvents();
  }

  Map<String, String> get headers {
    return _headers;
  }

  Future<void> dispose() async {
    await _authStateSubscription.cancel();
  }

  GoTrueClient _initAuthClient({
    bool? autoRefreshToken,
    required GotrueAsyncStorage? gotrueAsyncStorage,
    required AuthFlowType authFlowType,
  }) {
    final authHeaders = {...headers};
    authHeaders['Authorization'] = 'Bearer $_shapleKey';

    return GoTrueClient(
      url: '$_shapleUrl/auth/v1',
      headers: authHeaders,
      autoRefreshToken: autoRefreshToken,
      httpClient: _httpClient,
      asyncStorage: gotrueAsyncStorage,
      flowType: authFlowType,
    );
  }

  SupabaseStorageClient _initStorageClient(int storageRetryAttempts) {
    final storage = SupabaseStorageClient(
      '$_shapleUrl/storage/v1',
      {...headers},
      httpClient: _httpClient,
      retryAttempts: storageRetryAttempts,
    )..setAuth(_shapleKey);

    return storage;
  }

  void _listenForAuthEvents() {
    // ignore: invalid_use_of_internal_member
    _authStateSubscription = auth.onAuthStateChangeSync.listen(
      (data) {
        _handleTokenChanged(data.event, data.session?.accessToken);
      },
      onError: (error, stack) {},
    );
  }

  void _handleTokenChanged(AuthChangeEvent event, String? token) {
    if (event == AuthChangeEvent.initialSession ||
        event == AuthChangeEvent.tokenRefreshed ||
        event == AuthChangeEvent.signedIn) {
      storage.setAuth(token ?? _shapleKey);
    } else if (event == AuthChangeEvent.signedOut ||
        event == AuthChangeEvent.userDeleted) {
      // Token is removed

      storage.setAuth(_shapleKey);
    }
  }
}
