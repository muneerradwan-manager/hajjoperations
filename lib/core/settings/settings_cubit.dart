import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/bloc/safe_cubit.dart';
import '../../features/notifications/data/push_service.dart';

class SettingsState extends Equatable {
  const SettingsState({
    required this.themeMode,
    required this.locale,
    this.notificationsEnabled = true,
  });

  final ThemeMode themeMode;

  /// null => follow the device locale.
  final Locale? locale;

  /// Whether this device wants push at all. The in-app inbox is unaffected —
  /// turning it off stops the phone buzzing, it does not stop being told.
  final bool notificationsEnabled;

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool clearLocale = false,
    bool? notificationsEnabled,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: clearLocale ? null : (locale ?? this.locale),
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  @override
  List<Object?> get props => [themeMode, locale, notificationsEnabled];
}

/// Persists appearance + language choices.
class SettingsCubit extends SafeCubit<SettingsState> {
  SettingsCubit(this._prefs)
    : super(
        SettingsState(
          themeMode: _readThemeMode(_prefs),
          locale: _readLocale(_prefs),
          notificationsEnabled: _prefs.getBool(_kNotifications) ?? true,
        ),
      );

  final SharedPreferences _prefs;

  static const _kTheme = 'settings.themeMode';
  static const _kLocale = 'settings.locale';
  static const _kNotifications = 'settings.notifications';

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

  /// Turning push off unsubscribes this device from every topic and forgets its
  /// token, so nothing is delivered to it; turning it back on resubscribes.
  Future<void> setNotificationsEnabled(bool enabled) async {
    emit(state.copyWith(notificationsEnabled: enabled));
    await _prefs.setBool(_kNotifications, enabled);
    if (enabled) {
      await PushService.instance.start();
    } else {
      await PushService.instance.mute();
    }
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
