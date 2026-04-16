import 'dart:async';
import 'package:dio/dio.dart';
import '../crypto/key_store.dart';
import '../core/constants/api_endpoints.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  bool _isRefreshing = false;
  final List<_RetryRequest> _pendingRequests = [];

  AuthInterceptor(this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await KeyStore.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    if (_isRefreshing) {
      final completer = Completer<Response>();
      _pendingRequests.add(_RetryRequest(err.requestOptions, completer));
      try {
        final response = await completer.future;
        handler.resolve(response);
      } catch (e) {
        handler.next(err);
      }
      return;
    }

    _isRefreshing = true;
    try {
      final refreshToken = await KeyStore.getRefreshToken();
      if (refreshToken == null) {
        await _handleAuthFailure();
        handler.next(err);
        return;
      }

      final response = await _dio.post(
        ApiEndpoints.refresh,
        data: {'refresh_token': refreshToken},
        options: Options(headers: {'Authorization': null}),
      );

      final newAccessToken = response.data['access_token'] as String;
      final newRefreshToken =
          response.data['refresh_token'] as String? ?? refreshToken;
      await KeyStore.storeTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );

      // Retry original request
      err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      final retried = await _dio.fetch(err.requestOptions);
      handler.resolve(retried);

      // Flush pending
      for (final pending in _pendingRequests) {
        pending.options.headers['Authorization'] = 'Bearer $newAccessToken';
        _dio.fetch(pending.options).then(pending.completer.complete).catchError(
              (e) => pending.completer.completeError(e),
            );
      }
      _pendingRequests.clear();
    } catch (_) {
      await _handleAuthFailure();
      for (final pending in _pendingRequests) {
        pending.completer.completeError(err);
      }
      _pendingRequests.clear();
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _handleAuthFailure() async {
    await KeyStore.clearSession();
  }
}

class _RetryRequest {
  final RequestOptions options;
  final Completer<Response> completer;
  _RetryRequest(this.options, this.completer);
}
