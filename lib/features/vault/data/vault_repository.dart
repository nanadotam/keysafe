import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../crypto/crypto_service.dart';
import '../../../crypto/key_store.dart';
import '../domain/vault_entry.dart';
import 'vault_local_db.dart';

class VaultRepository {
  final Dio _dio;
  final _uuid = const Uuid();

  VaultRepository(this._dio);

  Future<List<VaultEntry>> fetchAll() async {
    try {
      final response = await _dio.get(ApiEndpoints.vault);
      final List<dynamic> items = response.data['entries'] ?? [];
      final entries = items
          .map((e) => VaultEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      await VaultLocalDb.replaceAll(entries);
      return entries;
    } on DioException catch (e) {
      _logDioError('fetchAll', e);
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return VaultLocalDb.getAll();
      }
      throw _mapError(e);
    }
  }

  Future<VaultEntry> create({
    required String name,
    required String username,
    required String plainPassword,
    required String url,
    required String notes,
    required String category,
  }) async {
    final key = await KeyStore.getAesKey();
    if (key == null) throw 'Vault key not found. Please log in again.';

    final encrypted = CryptoService.encrypt(plainPassword, key);
    final strength = CryptoService.calculateStrength(plainPassword);
    final now = DateTime.now();
    final id = _uuid.v4();

    final entry = VaultEntry(
      id: id,
      name: name,
      username: username,
      encryptedPassword: encrypted,
      url: url,
      notes: notes,
      category: category,
      strengthScore: strength,
      createdAt: now,
      updatedAt: now,
    );

    await VaultLocalDb.upsert(entry);

    try {
      final payload = <String, dynamic>{
        'name': entry.name,
        'username': entry.username,
        'encryptedPassword': entry.encryptedPassword,
        'url': entry.url,
        'notes': entry.notes,
        'category': entry.category,
        'strengthScore': entry.strengthScore,
      };
      final response = await _dio.post(
        ApiEndpoints.vault,
        data: payload,
      );
      final saved = VaultEntry.fromJson(response.data as Map<String, dynamic>);
      await VaultLocalDb.upsert(saved);
      return saved;
    } on DioException catch (e) {
      _logDioError('create', e);
      if (!_isOfflineError(e)) {
        throw _mapError(e);
      }
      await VaultLocalDb.addPendingOp(
        op: 'create',
        data: entry.toJson(),
      );
      return entry;
    }
  }

  Future<VaultEntry> update({
    required String id,
    required String name,
    required String username,
    String? plainPassword,
    required String url,
    required String notes,
    required String category,
    required String existingEncrypted,
    required int existingStrength,
    required DateTime existingCreatedAt,
  }) async {
    String encrypted = existingEncrypted;
    int strength = existingStrength;

    if (plainPassword != null && plainPassword.isNotEmpty) {
      final key = await KeyStore.getAesKey();
      if (key == null) throw 'Vault key not found. Please log in again.';
      encrypted = CryptoService.encrypt(plainPassword, key);
      strength = CryptoService.calculateStrength(plainPassword);
    }

    final entry = VaultEntry(
      id: id,
      name: name,
      username: username,
      encryptedPassword: encrypted,
      url: url,
      notes: notes,
      category: category,
      strengthScore: strength,
      createdAt: existingCreatedAt,
      updatedAt: DateTime.now(),
    );

    await VaultLocalDb.upsert(entry);

    try {
      final payload = <String, dynamic>{
        'name': entry.name,
        'username': entry.username,
        'encryptedPassword': entry.encryptedPassword,
        'url': entry.url,
        'notes': entry.notes,
        'category': entry.category,
        'strengthScore': entry.strengthScore,
      };
      final response = await _dio.put(
        ApiEndpoints.vaultEntry(id),
        data: payload,
      );
      final saved = VaultEntry.fromJson(response.data as Map<String, dynamic>);
      await VaultLocalDb.upsert(saved);
      return saved;
    } on DioException catch (e) {
      _logDioError('update', e);
      if (!_isOfflineError(e)) {
        throw _mapError(e);
      }
      await VaultLocalDb.addPendingOp(op: 'update', data: entry.toJson());
      return entry;
    }
  }

  Future<void> delete(String id) async {
    await VaultLocalDb.delete(id);
    try {
      await _dio.delete(ApiEndpoints.vaultEntry(id));
    } on DioException catch (e) {
      _logDioError('delete', e);
      if (!_isOfflineError(e)) {
        throw _mapError(e);
      }
      await VaultLocalDb.addPendingOp(op: 'delete', data: {'id': id});
    }
  }

  Future<String> exportCsv() async {
    try {
      final response = await _dio.get<String>(
        ApiEndpoints.vaultExport,
        queryParameters: {'format': 'csv'},
        options: Options(responseType: ResponseType.plain),
      );
      return response.data ?? '';
    } on DioException catch (e) {
      _logDioError('exportCsv', e);
      throw _mapError(e);
    }
  }

  Future<void> flushPendingOps() async {
    final ops = await VaultLocalDb.getPendingOps();
    for (final op in ops) {
      try {
        final opType = op['op'] as String;
        final data = op['data'] as Map<String, dynamic>;
        final opId = op['id'] as int;
        switch (opType) {
          case 'create':
            await _dio.post(ApiEndpoints.vault, data: data);
          case 'update':
            await _dio.put(ApiEndpoints.vaultEntry(data['id'] as String),
                data: data);
          case 'delete':
            await _dio.delete(ApiEndpoints.vaultEntry(data['id'] as String));
        }
        await VaultLocalDb.deletePendingOp(opId);
      } catch (_) {
        break;
      }
    }
  }

  String _mapError(DioException e) {
    switch (e.response?.statusCode) {
      case 400:
        return _extractMessage(e) ?? 'Invalid request.';
      case 401:
        return 'Session expired. Please log in again.';
      case 403:
        return 'Access denied.';
      case 404:
        return 'Entry not found.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return _extractMessage(e) ?? 'Something went wrong. Please try again.';
    }
  }

  bool _isOfflineError(DioException e) {
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout;
  }

  String? _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final error = data['error'] ?? data['message'];
      if (error is String && error.isNotEmpty) {
        return error;
      }
    }
    return null;
  }

  void _logDioError(String action, DioException e) {
    developer.log(
      'Vault $action failed: status=${e.response?.statusCode} '
      'type=${e.type} path=${e.requestOptions.path} body=${e.response?.data}',
      name: 'VaultRepository',
      error: e,
      stackTrace: e.stackTrace,
    );
  }
}
