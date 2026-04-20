import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../crypto/key_store.dart';
import '../../auth/providers/auth_provider.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.name,
    required this.email,
    required this.passwordCount,
    required this.wifiCount,
    required this.categoryCount,
    required this.securityScore,
    required this.memberSince,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String name;
  final String email;
  final int passwordCount;
  final int wifiCount;
  final int categoryCount;
  final int securityScore;
  final DateTime memberSince;

  String get displayName {
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '$firstName${lastName.isNotEmpty ? ' $lastName' : ''}'.trim();
    }
    return name;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final firstName = (json['first_name'] as String?)?.trim() ?? '';
    final lastName  = (json['last_name']  as String?)?.trim() ?? '';
    final apiName   = (json['name']     as String?)?.trim() ??
                      (json['username'] as String?)?.trim() ?? '';
    return UserProfile(
      id:            json['id']             as String? ?? '',
      firstName:     firstName,
      lastName:      lastName,
      name:          apiName,
      email:         json['email']          as String? ?? '',
      passwordCount: json['password_count'] as int?    ?? 0,
      wifiCount:     json['wifi_count']     as int?    ?? 0,
      categoryCount: json['category_count'] as int?    ?? 0,
      securityScore: json['security_score'] as int?    ?? 0,
      memberSince:   DateTime.tryParse(json['member_since'] as String? ?? '') ??
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
      return UserProfile.fromJson(data);
    } on DioException catch (_) {
      // Offline or server error — return a minimal profile from local storage.
      if (localEmail.isNotEmpty) {
        final localFirst = await KeyStore.getFirstName() ?? '';
        final localLast  = await KeyStore.getLastName()  ?? '';
        return UserProfile(
          id:            '',
          firstName:     localFirst,
          lastName:      localLast,
          name:          localName,
          email:         localEmail,
          passwordCount: 0,
          wifiCount:     0,
          categoryCount: 0,
          securityScore: 0,
          memberSince:   DateTime.now(),
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
