import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/login_event.dart';
import 'login_history_db.dart';

class LoginHistoryRepository {
  const LoginHistoryRepository(this._dio);

  final Dio _dio;

  Future<List<LoginEvent>> fetchAll({int limit = 50}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.loginHistory,
        queryParameters: {'limit': limit},
      );
      final data  = response.data as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>? ?? []);
      return items
          .map((e) => LoginEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (_) {
      // Offline fallback: return locally cached events.
      return LoginHistoryDb.instance.getAll(limit: limit);
    }
  }

  Future<void> setTrusted(String id, {required bool trusted}) async {
    await _dio.patch(
      ApiEndpoints.loginHistoryEntry(id),
      data: {'trusted': trusted},
    );
  }

  Future<void> deleteEntry(String id) async {
    await _dio.delete(ApiEndpoints.loginHistoryEntry(id));
  }

  Future<void> clearAll() async {
    await _dio.delete(ApiEndpoints.loginHistory);
  }
}

final loginHistoryRepositoryProvider = Provider<LoginHistoryRepository>(
  (ref) => LoginHistoryRepository(ref.watch(dioProvider)),
);

final loginHistoryProvider = FutureProvider<List<LoginEvent>>(
  (ref) => ref.watch(loginHistoryRepositoryProvider).fetchAll(),
);
