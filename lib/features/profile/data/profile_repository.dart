import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
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
    try {
      final response = await _dio.get(ApiEndpoints.profile);
      return UserProfile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  String _mapError(DioException e) {
    switch (e.response?.statusCode) {
      case 401:
        return 'Session expired. Please log in again.';
      case 404:
        return 'Profile not found.';
      default:
        return 'Failed to load profile.';
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(dioProvider)),
);

final profileProvider = FutureProvider<UserProfile>(
  (ref) => ref.watch(profileRepositoryProvider).fetchProfile(),
);
