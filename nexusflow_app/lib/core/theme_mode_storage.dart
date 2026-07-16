import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class ThemeModeStorage {
  Future<ThemeMode?> read();
  Future<void> write(ThemeMode mode);
}

class SecureThemeModeStorage implements ThemeModeStorage {
  SecureThemeModeStorage() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'nf_theme_mode';

  @override
  Future<ThemeMode?> read() async {
    switch (await _storage.read(key: _key)) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return null;
    }
  }

  @override
  Future<void> write(ThemeMode mode) =>
      _storage.write(key: _key, value: mode == ThemeMode.dark ? 'dark' : 'light');
}
