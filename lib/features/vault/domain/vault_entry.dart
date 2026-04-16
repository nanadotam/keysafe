import 'package:freezed_annotation/freezed_annotation.dart';

part 'vault_entry.freezed.dart';
part 'vault_entry.g.dart';

@freezed
class VaultEntry with _$VaultEntry {
  const factory VaultEntry({
    required String id,
    required String name,
    required String username,
    required String encryptedPassword,
    @Default('') String url,
    @Default('') String notes,
    @Default('personal') String category,
    @Default(0) int strengthScore,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _VaultEntry;

  factory VaultEntry.fromJson(Map<String, dynamic> json) =>
      _$VaultEntryFromJson(json);
}
