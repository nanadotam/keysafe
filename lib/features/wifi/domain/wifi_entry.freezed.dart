// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wifi_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-model');

WifiEntry _$WifiEntryFromJson(Map<String, dynamic> json) {
  return _WifiEntry.fromJson(json);
}

mixin _$WifiEntry {
  String get id => throw _privateConstructorUsedError;
  String get networkName => throw _privateConstructorUsedError;
  String get encryptedPassword => throw _privateConstructorUsedError;
  String get notes => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WifiEntryCopyWith<WifiEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

abstract class $WifiEntryCopyWith<$Res> {
  factory $WifiEntryCopyWith(WifiEntry value, $Res Function(WifiEntry) then) =
      _$WifiEntryCopyWithImpl<$Res, WifiEntry>;
  @useResult
  $Res call(
      {String id,
      String networkName,
      String encryptedPassword,
      String notes,
      DateTime createdAt,
      DateTime updatedAt});
}

class _$WifiEntryCopyWithImpl<$Res, $Val extends WifiEntry>
    implements $WifiEntryCopyWith<$Res> {
  _$WifiEntryCopyWithImpl(this._value, this._then);
  final $Val _value;
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? networkName = null,
    Object? encryptedPassword = null,
    Object? notes = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id ? _value.id : id as String,
      networkName: null == networkName ? _value.networkName : networkName as String,
      encryptedPassword: null == encryptedPassword ? _value.encryptedPassword : encryptedPassword as String,
      notes: null == notes ? _value.notes : notes as String,
      createdAt: null == createdAt ? _value.createdAt : createdAt as DateTime,
      updatedAt: null == updatedAt ? _value.updatedAt : updatedAt as DateTime,
    ) as $Val);
  }
}

abstract class _$$WifiEntryImplCopyWith<$Res>
    implements $WifiEntryCopyWith<$Res> {
  factory _$$WifiEntryImplCopyWith(
          _$WifiEntryImpl value, $Res Function(_$WifiEntryImpl) then) =
      __$$WifiEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String networkName,
      String encryptedPassword,
      String notes,
      DateTime createdAt,
      DateTime updatedAt});
}

class __$$WifiEntryImplCopyWithImpl<$Res>
    extends _$WifiEntryCopyWithImpl<$Res, _$WifiEntryImpl>
    implements _$$WifiEntryImplCopyWith<$Res> {
  __$$WifiEntryImplCopyWithImpl(
      _$WifiEntryImpl _value, $Res Function(_$WifiEntryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? networkName = null,
    Object? encryptedPassword = null,
    Object? notes = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$WifiEntryImpl(
      id: null == id ? _value.id : id as String,
      networkName: null == networkName ? _value.networkName : networkName as String,
      encryptedPassword: null == encryptedPassword ? _value.encryptedPassword : encryptedPassword as String,
      notes: null == notes ? _value.notes : notes as String,
      createdAt: null == createdAt ? _value.createdAt : createdAt as DateTime,
      updatedAt: null == updatedAt ? _value.updatedAt : updatedAt as DateTime,
    ));
  }
}

@JsonSerializable()
class _$WifiEntryImpl implements _WifiEntry {
  const _$WifiEntryImpl({
    required this.id,
    required this.networkName,
    required this.encryptedPassword,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory _$WifiEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$WifiEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String networkName;
  @override
  final String encryptedPassword;
  @override
  @JsonKey()
  final String notes;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WifiEntryImpl &&
            other.id == id);
  }

  @override
  int get hashCode => Object.hash(runtimeType, id);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WifiEntryImplCopyWith<_$WifiEntryImpl> get copyWith =>
      __$$WifiEntryImplCopyWithImpl<_$WifiEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() => _$$WifiEntryImplToJson(this);
}

abstract class _WifiEntry implements WifiEntry {
  const factory _WifiEntry({
    required final String id,
    required final String networkName,
    required final String encryptedPassword,
    final String notes,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$WifiEntryImpl;

  factory _WifiEntry.fromJson(Map<String, dynamic> json) =
      _$WifiEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get networkName;
  @override
  String get encryptedPassword;
  @override
  String get notes;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$WifiEntryImplCopyWith<_$WifiEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
