// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vault_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VaultEntryImpl _$$VaultEntryImplFromJson(Map<String, dynamic> json) =>
    _$VaultEntryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      username: json['username'] as String,
      encryptedPassword: json['encryptedPassword'] as String,
      url: json['url'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      category: json['category'] as String? ?? 'personal',
      strengthScore: json['strengthScore'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$VaultEntryImplToJson(_$VaultEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'username': instance.username,
      'encryptedPassword': instance.encryptedPassword,
      'url': instance.url,
      'notes': instance.notes,
      'category': instance.category,
      'strengthScore': instance.strengthScore,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
