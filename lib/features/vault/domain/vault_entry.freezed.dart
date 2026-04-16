// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vault_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-model');

VaultEntry _$VaultEntryFromJson(Map<String, dynamic> json) {
  return _VaultEntry.fromJson(json);
}

/// @nodoc
mixin _$VaultEntry {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;
  String get encryptedPassword => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  String get notes => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  int get strengthScore => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $VaultEntryCopyWith<VaultEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

abstract class $VaultEntryCopyWith<$Res> {
  factory $VaultEntryCopyWith(
          VaultEntry value, $Res Function(VaultEntry) then) =
      _$VaultEntryCopyWithImpl<$Res, VaultEntry>;
  @useResult
  $Res call(
      {String id,
      String name,
      String username,
      String encryptedPassword,
      String url,
      String notes,
      String category,
      int strengthScore,
      DateTime createdAt,
      DateTime updatedAt});
}

class _$VaultEntryCopyWithImpl<$Res, $Val extends VaultEntry>
    implements $VaultEntryCopyWith<$Res> {
  _$VaultEntryCopyWithImpl(this._value, this._then);

  final $Val _value;
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? username = null,
    Object? encryptedPassword = null,
    Object? url = null,
    Object? notes = null,
    Object? category = null,
    Object? strengthScore = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id as String,
      name: null == name
          ? _value.name
          : name as String,
      username: null == username
          ? _value.username
          : username as String,
      encryptedPassword: null == encryptedPassword
          ? _value.encryptedPassword
          : encryptedPassword as String,
      url: null == url
          ? _value.url
          : url as String,
      notes: null == notes
          ? _value.notes
          : notes as String,
      category: null == category
          ? _value.category
          : category as String,
      strengthScore: null == strengthScore
          ? _value.strengthScore
          : strengthScore as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt as DateTime,
    ) as $Val);
  }
}

abstract class _$$VaultEntryImplCopyWith<$Res>
    implements $VaultEntryCopyWith<$Res> {
  factory _$$VaultEntryImplCopyWith(
          _$VaultEntryImpl value, $Res Function(_$VaultEntryImpl) then) =
      __$$VaultEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String username,
      String encryptedPassword,
      String url,
      String notes,
      String category,
      int strengthScore,
      DateTime createdAt,
      DateTime updatedAt});
}

class __$$VaultEntryImplCopyWithImpl<$Res>
    extends _$VaultEntryCopyWithImpl<$Res, _$VaultEntryImpl>
    implements _$$VaultEntryImplCopyWith<$Res> {
  __$$VaultEntryImplCopyWithImpl(
      _$VaultEntryImpl _value, $Res Function(_$VaultEntryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? username = null,
    Object? encryptedPassword = null,
    Object? url = null,
    Object? notes = null,
    Object? category = null,
    Object? strengthScore = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$VaultEntryImpl(
      id: null == id ? _value.id : id as String,
      name: null == name ? _value.name : name as String,
      username: null == username ? _value.username : username as String,
      encryptedPassword: null == encryptedPassword
          ? _value.encryptedPassword
          : encryptedPassword as String,
      url: null == url ? _value.url : url as String,
      notes: null == notes ? _value.notes : notes as String,
      category: null == category ? _value.category : category as String,
      strengthScore: null == strengthScore
          ? _value.strengthScore
          : strengthScore as int,
      createdAt:
          null == createdAt ? _value.createdAt : createdAt as DateTime,
      updatedAt:
          null == updatedAt ? _value.updatedAt : updatedAt as DateTime,
    ));
  }
}

@JsonSerializable()
class _$VaultEntryImpl implements _VaultEntry {
  const _$VaultEntryImpl(
      {required this.id,
      required this.name,
      required this.username,
      required this.encryptedPassword,
      this.url = '',
      this.notes = '',
      this.category = 'personal',
      this.strengthScore = 0,
      required this.createdAt,
      required this.updatedAt});

  factory _$VaultEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$VaultEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String username;
  @override
  final String encryptedPassword;
  @override
  @JsonKey()
  final String url;
  @override
  @JsonKey()
  final String notes;
  @override
  @JsonKey()
  final String category;
  @override
  @JsonKey()
  final int strengthScore;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'VaultEntry(id: $id, name: $name, username: $username, encryptedPassword: [REDACTED], url: $url, notes: $notes, category: $category, strengthScore: $strengthScore, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VaultEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.encryptedPassword, encryptedPassword) ||
                other.encryptedPassword == encryptedPassword) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.strengthScore, strengthScore) ||
                other.strengthScore == strengthScore) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, username,
      encryptedPassword, url, notes, category, strengthScore, createdAt, updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$VaultEntryImplCopyWith<_$VaultEntryImpl> get copyWith =>
      __$$VaultEntryImplCopyWithImpl<_$VaultEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VaultEntryImplToJson(
      this,
    );
  }
}

abstract class _VaultEntry implements VaultEntry {
  const factory _VaultEntry(
      {required final String id,
      required final String name,
      required final String username,
      required final String encryptedPassword,
      final String url,
      final String notes,
      final String category,
      final int strengthScore,
      required final DateTime createdAt,
      required final DateTime updatedAt}) = _$VaultEntryImpl;

  factory _VaultEntry.fromJson(Map<String, dynamic> json) =
      _$VaultEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get username;
  @override
  String get encryptedPassword;
  @override
  String get url;
  @override
  String get notes;
  @override
  String get category;
  @override
  int get strengthScore;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$VaultEntryImplCopyWith<_$VaultEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
