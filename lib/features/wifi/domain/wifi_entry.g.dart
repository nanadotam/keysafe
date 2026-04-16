// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wifi_entry.dart';

_$WifiEntryImpl _$$WifiEntryImplFromJson(Map<String, dynamic> json) =>
    _$WifiEntryImpl(
      id: json['id'] as String,
      networkName: json['networkName'] as String,
      encryptedPassword: json['encryptedPassword'] as String,
      notes: json['notes'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$WifiEntryImplToJson(_$WifiEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'networkName': instance.networkName,
      'encryptedPassword': instance.encryptedPassword,
      'notes': instance.notes,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
