import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState extends Equatable {
  const SettingsState({required this.themeMode, required this.locale});

  final ThemeMode themeMode;

  /// null => follow the device locale.
  final Locale? locale;

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool clearLocale = false,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: clearLocale ? null : (locale ?? this.locale),
    );
  }

  @override
  List<Object?> get props => [themeMode, locale];
}

/// Persists appearance + language choices.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._prefs)
    : super(
        SettingsState(
          themeMode: _readThemeMode(_prefs),
          locale: _readLocale(_prefs),
        ),
      );

  final SharedPreferences _prefs;

  static const _kTheme = 'settings.themeMode';
  static const _kLocale = 'settings.locale';

  static ThemeMode _readThemeMode(SharedPreferences p) =>
      switch (p.getString(_kTheme)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static Locale? _readLocale(SharedPreferences p) {
    final code = p.getString(_kLocale);
    return code == null ? null : Locale(code);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(state.copyWith(themeMode: mode));
    await _prefs.setString(_kTheme, mode.name);
  }

  Future<void> setLocale(Locale? locale) async {
    emit(state.copyWith(locale: locale, clearLocale: locale == null));
    if (locale == null) {
      await _prefs.remove(_kLocale);
    } else {
      await _prefs.setString(_kLocale, locale.languageCode);
    }
  }
}
