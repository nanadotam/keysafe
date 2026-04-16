import 'package:freezed_annotation/freezed_annotation.dart';

part 'wifi_entry.freezed.dart';
part 'wifi_entry.g.dart';

@freezed
class WifiEntry with _$WifiEntry {
  const factory WifiEntry({
    required String id,
    required String networkName,
    required String encryptedPassword,
    @Default('') String notes,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _WifiEntry;

  factory WifiEntry.fromJson(Map<String, dynamic> json) =>
      _$WifiEntryFromJson(json);
}
