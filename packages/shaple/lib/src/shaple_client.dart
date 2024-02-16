import 'dart:async';
import 'dart:core';

import 'package:http/http.dart';
import 'package:shaple/shaple.dart';
import 'package:yet_another_json_isolate/yet_another_json_isolate.dart';

import 'constants.dart';

class ShapleClient {
  final Map<String, String> _headers;
  final String _shapleKey;
  final String _shapleUrl;
  final YAJsonIsolate _isolate;

  late final GoTrueClient _auth;
  late final SupabaseStorageClient _storage;
  late final PostgrestClient _postgrest;
  late final StreamSubscription<AuthState> _authStateSubscription;

  ShapleClient(
    this._shapleUrl,
    this._shapleKey, {
    AuthClientOptions authOptions = const AuthClientOptions(),
    StorageClientOptions storageOptions = const StorageClientOptions(),
    PostgrestClientOptions postgrestOptions = const PostgrestClientOptions(),
    Map<String, String>? headers,
    Client? httpClient,
    YAJsonIsolate? isolate,
  })  : _headers = {...DEFAULT_HEADERS, if (headers != null) ...headers},
        _isolate = isolate ?? (YAJsonIsolate()..initialize()) {
    httpClient ??= Client();
    this._auth = _initAuthClient(
      options: authOptions,
      httpClient: httpClient,
    );
    this._storage = _initStorageClient(
      options: storageOptions,
      httpClient: httpClient,
    );
    this._postgrest = _initPostgrestClient(
      options: postgrestOptions,
      httpClient: httpClient,
    );
    _listenForAuthEvents();
  }

  Map<String, String> get headers {
    return _headers;
  }

  Future<void> dispose() async {
    await _authStateSubscription.cancel();
    await _isolate.dispose();
  }

  /// Perform a table operation.
  PostgrestQueryBuilder<void> from(String table) {
    return postgrest.from(table);
  }

  /// Select a schema to query or perform an function (rpc) call.
  ///
  /// The schema needs to be on the list of exposed schemas inside Shaple.
  PostgrestClient schema(String schema) {
    return postgrest.schema(schema);
  }

  GoTrueClient _initAuthClient({
    required AuthClientOptions options,
    Client? httpClient,
  }) {
    final authHeaders = {...headers};
    authHeaders['Authorization'] = 'Bearer $_shapleKey';

    return GoTrueClient(
      url: '$_shapleUrl/auth/v1',
      headers: authHeaders,
      autoRefreshToken: options.autoRefreshToken,
      httpClient: httpClient,
      asyncStorage: options.asyncStorage,
      flowType: options.authFlowType,
    );
  }

  SupabaseStorageClient _initStorageClient({
    required StorageClientOptions options,
    Client? httpClient,
  }) {
    return SupabaseStorageClient(
      '$_shapleUrl/storage/v1',
      {...headers},
      httpClient: httpClient,
      retryAttempts: options.retryAttempts,
    );
  }

  PostgrestClient _initPostgrestClient({
    required PostgrestClientOptions options,
    Client? httpClient,
  }) {
    return PostgrestClient(
      '$_shapleUrl/postgrest/v1',
      headers: {...headers},
      schema: options.schema,
      httpClient: httpClient,
      isolate: _isolate,
    );
  }

  get auth => _auth;
  get storage =>
      _storage..setAuth(_auth.currentSession?.accessToken ?? _shapleKey);
  get postgrest =>
      _postgrest..setAuth(_auth.currentSession?.accessToken ?? _shapleKey);

  void _listenForAuthEvents() {
    // ignore: invalid_use_of_internal_member
    _authStateSubscription = _auth.onAuthStateChangeSync.listen(
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
      _storage.setAuth(token ?? _shapleKey);
      _postgrest.setAuth(token ?? _shapleKey);
    } else if (event == AuthChangeEvent.signedOut ||
        event == AuthChangeEvent.userDeleted) {
      // Token is removed

      _storage.setAuth(_shapleKey);
      _postgrest.setAuth(_shapleKey);
    }
  }
}
