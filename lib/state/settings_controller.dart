import 'package:flutter/material.dart';
import 'package:subbies/data/settings_repository.dart';


class SettingsController extends ChangeNotifier {
  SettingsController(this._repository);

  final SettingsRepository _repository;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    try {
      _themeMode = await _repository.loadThemeMode();
    } catch (error) {
      debugPrint('Could not load settings: $error');
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      await _repository.saveThemeMode(mode);
    } catch (error) {
      debugPrint('Could not save theme: $error');
    }
  }
}


