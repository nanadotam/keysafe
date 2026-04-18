import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../crypto/key_store.dart';
import '../../auth/providers/auth_provider.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordCount,
    required this.wifiCount,
    required this.categoryCount,
    required this.securityScore,
    required this.memberSince,
  });

  final String id;
  final String name;
  final String email;
  final int passwordCount;
  final int wifiCount;
  final int categoryCount;
  final int securityScore;
  final DateTime memberSince;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      passwordCount: json['password_count'] as int? ?? 0,
      wifiCount: json['wifi_count'] as int? ?? 0,
      categoryCount: json['category_count'] as int? ?? 0,
      securityScore: json['security_score'] as int? ?? 0,
      memberSince: DateTime.tryParse(json['member_since'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class ProfileRepository {
  const ProfileRepository(this._dio);

  final Dio _dio;

  Future<UserProfile> fetchProfile() async {
    // Always try to get the locally stored display name as fallback.
    final localName = await KeyStore.getDisplayName() ?? '';
    final localEmail = await KeyStore.getUserEmail() ?? '';

    try {
      final response = await _dio.get(ApiEndpoints.profile);
      final data = response.data as Map<String, dynamic>;
      // Backend may return either 'name' or 'username'
      final apiName = (data['name'] as String?)?.trim() ??
          (data['username'] as String?)?.trim() ??
          localName;
      return UserProfile.fromJson({...data, 'name': apiName});
    } on DioException catch (_) {
      // Offline or server error — return a minimal profile from local storage.
      if (localEmail.isNotEmpty) {
        return UserProfile(
          id: '',
          name: localName,
          email: localEmail,
          passwordCount: 0,
          wifiCount: 0,
          categoryCount: 0,
          securityScore: 0,
          memberSince: DateTime.now(),
        );
      }
      rethrow;
    }
  }

}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(dioProvider)),
);

final profileProvider = FutureProvider<UserProfile>(
  (ref) => ref.watch(profileRepositoryProvider).fetchProfile(),
);
