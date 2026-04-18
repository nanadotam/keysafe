import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const defaultCategories = [
  'personal',
  'social',
  'finance',
  'email',
  'shopping',
  'apps',
  'wifi',
  'work',
];

final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, List<String>>(
  (ref) => CategoriesNotifier()..load(),
);

class CategoriesNotifier extends StateNotifier<List<String>> {
  CategoriesNotifier() : super(defaultCategories);

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _key = 'custom_categories_v1';

  Future<void> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return;
    final custom = (jsonDecode(raw) as List).cast<String>();
    final merged = {...defaultCategories, ...custom}.toList();
    state = merged;
  }

  Future<void> addCategory(String name) async {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty || state.contains(normalized)) return;
    final updated = [...state, normalized];
    state = updated;
    final custom = updated
        .where((c) => !defaultCategories.contains(c))
        .toList();
    await _storage.write(key: _key, value: jsonEncode(custom));
  }

  Future<void> removeCategory(String name) async {
    if (defaultCategories.contains(name)) return;
    final updated = state.where((c) => c != name).toList();
    state = updated;
    final custom = updated
        .where((c) => !defaultCategories.contains(c))
        .toList();
    await _storage.write(key: _key, value: jsonEncode(custom));
  }
}
