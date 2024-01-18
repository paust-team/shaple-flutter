import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:shaple/shaple.dart';
import 'package:shaple_flutter/src/constants.dart';
import 'package:shaple_flutter/src/flutter_go_true_client_options.dart';
import 'package:shaple_flutter/src/local_storage.dart';
import 'package:shaple_flutter/src/shaple_auth.dart';

/// Shaple instance.
///
/// It must be initialized before used, otherwise an error is thrown.
///
/// ```dart
/// await Shaple.initialize(...)
/// ```
///
/// Use it:
///
/// ```dart
/// final instance = Shaple.instance;
/// ```
///
/// See also:
///
///   * [ShapleAuth]
class Shaple {
  /// Gets the current shaple instance.
  ///
  /// An [AssertionError] is thrown if shaple isn't initialized yet.
  /// Call [Shaple.initialize] to initialize it.
  static Shaple get instance {
    assert(
    _instance._initialized,
    'You must initialize the shaple instance before calling Shaple.instance',
    );
    return _instance;
  }

  /// Initialize the current shaple instance
  ///
  /// This must be called only once. If called more than once, an
  /// [AssertionError] is thrown
  ///
  /// [url] and [anonKey] can be found on your Shaple dashboard.
  ///
  /// You can access none public schema by passing different [schema].
  ///
  /// Default headers can be overridden by specifying [headers].
  ///
  /// Pass [localStorage] to override the default local storage option used to
  /// persist auth.
  ///
  /// Custom http client can be used by passing [httpClient] parameter.
  ///
  /// [storageRetryAttempts] specifies how many retry attempts there should be
  /// to upload a file to Shaple storage when failed due to network
  /// interruption.
  ///
  /// Set [authFlowType] to [AuthFlowType.implicit] to use the old implicit flow for authentication
  /// involving deep links.
  ///
  /// PKCE flow uses shared preferences for storing the code verifier by default.
  /// Pass a custom storage to [pkceAsyncStorage] to override the behavior.
  ///
  /// If [debug] is set to `true`, debug logs will be printed in debug console.
  static Future<Shaple> initialize({
    required String url,
    required String anonKey,
    Map<String, String>? headers,
    Client? httpClient,
    FlutterAuthClientOptions authOptions = const FlutterAuthClientOptions(),
    bool? debug,
  }) async {
    assert(
    !_instance._initialized,
    'This instance is already initialized',
    );
    if (authOptions.pkceAsyncStorage == null) {
      authOptions = authOptions.copyWith(
        pkceAsyncStorage: SharedPreferencesGotrueAsyncStorage(),
      );
    }
    if (authOptions.localStorage == null) {
      authOptions = authOptions.copyWith(
        localStorage: MigrationLocalStorage(
          persistSessionKey:
          "sb-${Uri.parse(url).host.split(".").first}-auth-token",
        ),
      );
    }
    _instance._init(
      url,
      anonKey,
      httpClient: httpClient,
      customHeaders: headers,
      authOptions: authOptions,
    );
    _instance._debugEnable = debug ?? kDebugMode;
    _instance.log('***** Shaple init completed $_instance');

    _instance._shapleAuth = ShapleAuth();
    await _instance._shapleAuth.initialize(options: authOptions);

    // Wrap `recoverSession()` in a `CancelableOperation` so that it can be canceled in dispose
    // if still in progress
    _instance._restoreSessionCancellableOperation =
        CancelableOperation.fromFuture(
          _instance._shapleAuth.recoverSession(),
        );

    return _instance;
  }

  Shaple._();
  static final Shaple _instance = Shaple._();

  bool _initialized = false;

  /// The shaple client for this instance
  ///
  /// Throws an error if [Shaple.initialize] was not called.
  late ShapleClient client;

  late ShapleAuth _shapleAuth;

  bool _debugEnable = false;

  /// Wraps the `recoverSession()` call so that it can be terminated when `dispose()` is called
  late CancelableOperation _restoreSessionCancellableOperation;

  /// Dispose the instance to free up resources.
  Future<void> dispose() async {
    await _restoreSessionCancellableOperation.cancel();
    client.dispose();
    _instance._shapleAuth.dispose();
    _initialized = false;
  }

  void _init(
      String shapleUrl,
      String shapleKey, {
        Client? httpClient,
        Map<String, String>? customHeaders,
        required AuthClientOptions authOptions,
      }) {
    final headers = {
      ...Constants.defaultHeaders,
      if (customHeaders != null) ...customHeaders
    };
    client = ShapleClient(
      shapleUrl,
      shapleKey,
      httpClient: httpClient,
      headers: headers,
      authOptions: authOptions,
    );
    _initialized = true;
  }

  void log(String msg, [StackTrace? stackTrace]) {
    if (_debugEnable) {
      debugPrint(msg);
      if (stackTrace != null) {
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }
}
