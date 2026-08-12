import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/bloc/safe_cubit.dart';
import '../../features/notifications/data/push_service.dart';
import '../../features/prayer_times/application/prayer_scheduler.dart';

/// Which shape the home page takes.
///
/// Two arrangements of the same doors, and deliberately not two different sets
/// of them: whatever a person may open, they may open in either. The choice is
/// about how they would rather FIND it.
enum HomeLayout {
  /// The original: every door on the page at once, in colour-coded shelves.
  ///
  /// It is the default and stays the default. It is the arrangement that
  /// answers "what is there?" without being asked — a man who opened this app
  /// for the first time this morning can see the whole of his authority in one
  /// scroll, and he does not yet know there is a menu to open.
  grid,

  /// A standing rail of the same doors, with the app's guide in their place.
  ///
  /// For the reader who already knows where everything is and wants it one tap
  /// away from wherever he happens to be — and for a monitor, where a page of
  /// tiles spends a metre of glass saying what a 280-pixel column says.
  sidebar;

  static HomeLayout fromName(String? name) =>
      values.firstWhere((v) => v.name == name, orElse: () => grid);
}

class SettingsState extends Equatable {
  const SettingsState({
    required this.themeMode,
    required this.locale,
    this.notificationsEnabled = true,
    this.solidSurfaces = false,
    this.homeLayout = HomeLayout.grid,
    this.sidebarExpanded = true,
    this.showPrayerCard = true,
  });

  final ThemeMode themeMode;

  /// null => follow the device locale.
  final Locale? locale;

  /// Whether this device wants push at all. The in-app inbox is unaffected —
  /// turning it off stops the phone buzzing, it does not stop being told.
  final bool notificationsEnabled;

  /// Take the glass out: opaque panes, no blur, heavier hairlines.
  ///
  /// One switch answering two complaints that share a fix. Outdoors in ذو
  /// الحجة a translucent pane spends contrast the eye has already lost to
  /// glare; and every blur is a save-layer the compositor re-reads each frame,
  /// which on the handsets field staff actually carry is where the frame
  /// budget goes.
  ///
  /// Per DEVICE rather than per account, like the theme and the language beside
  /// it: it is about the screen in this man's hand and the sun on it, not about
  /// who he is. The same person on a desk indoors wants it off.
  final bool solidSurfaces;

  /// Which arrangement the home page takes — see [HomeLayout].
  ///
  /// Per DEVICE, like everything else on this object. It is about the screen in
  /// front of this man: the same account wants the rail on the monitor on his
  /// desk and the page of tiles on the phone in his pocket, and a preference
  /// stored against the account would make him choose once for both.
  final HomeLayout homeLayout;

  /// Whether the rail stands open with its labels showing, or folded to a
  /// column of icons. Meaningless under [HomeLayout.grid], and kept anyway:
  /// somebody who folds it, switches away for a week and comes back should find
  /// it folded, not reset.
  final bool sidebarExpanded;

  /// Whether مواقيت الصلاة stands at the top of the home page.
  ///
  /// On rather than off, and it takes an act to turn off: the times are the one
  /// thing on this screen a man looks at without having decided to look at
  /// anything. What it costs when it is unwanted is the top third of the page,
  /// which is exactly why the switch exists.
  final bool showPrayerCard;

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool clearLocale = false,
    bool? notificationsEnabled,
    bool? solidSurfaces,
    HomeLayout? homeLayout,
    bool? sidebarExpanded,
    bool? showPrayerCard,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: clearLocale ? null : (locale ?? this.locale),
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      solidSurfaces: solidSurfaces ?? this.solidSurfaces,
      homeLayout: homeLayout ?? this.homeLayout,
      sidebarExpanded: sidebarExpanded ?? this.sidebarExpanded,
      showPrayerCard: showPrayerCard ?? this.showPrayerCard,
    );
  }

  @override
  List<Object?> get props => [
    themeMode,
    locale,
    notificationsEnabled,
    solidSurfaces,
    homeLayout,
    sidebarExpanded,
    showPrayerCard,
  ];
}

/// Persists appearance + language choices.
class SettingsCubit extends SafeCubit<SettingsState> {
  SettingsCubit(this._prefs)
    : super(
        SettingsState(
          themeMode: _readThemeMode(_prefs),
          locale: _readLocale(_prefs),
          notificationsEnabled: _prefs.getBool(_kNotifications) ?? true,
          solidSurfaces: _prefs.getBool(_kSolidSurfaces) ?? false,
          homeLayout: HomeLayout.fromName(_prefs.getString(_kHomeLayout)),
          sidebarExpanded: _prefs.getBool(_kSidebarExpanded) ?? true,
          showPrayerCard: _prefs.getBool(_kPrayerCard) ?? true,
        ),
      );

  final SharedPreferences _prefs;

  static const _kTheme = 'settings.themeMode';
  static const _kSolidSurfaces = 'settings.solidSurfaces';
  static const _kHomeLayout = 'settings.homeLayout';
  static const _kSidebarExpanded = 'settings.sidebarExpanded';
  static const _kPrayerCard = 'settings.showPrayerCard';

  /// Public because the prayer scheduler reads it too: a notification raised
  /// while the app is closed has no cubit to ask what language to speak, and
  /// the choice made here is the one it must honour.
  static const localeKey = 'settings.locale';

  static const _kNotifications = 'settings.notifications';

  /// Written when somebody chooses "follow the system", so that choosing it is
  /// distinguishable from never having chosen at all.
  ///
  /// It used to be stored by REMOVING the key, which was fine while "nothing
  /// stored" and "follow the system" meant the same thing. They no longer do:
  /// nothing stored is now Arabic, and without this sentinel a person who
  /// deliberately asked for the device's language would get Arabic back on the
  /// next launch, with no way to make the choice stick.
  static const followSystem = 'system';

  /// Dark unless somebody said otherwise.
  ///
  /// This app is read at three in the morning in Mina and on a coach before
  /// Fajr, far more often than it is read at a desk. Following the device
  /// would hand a white screen to whoever never opened the settings, which is
  /// most people.
  static ThemeMode _readThemeMode(SharedPreferences p) =>
      switch (p.getString(_kTheme)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        followSystem => ThemeMode.system,
        // Unset, or a value written by a build that spelled it differently.
        _ => ThemeMode.dark,
      };

  /// Arabic unless somebody said otherwise.
  ///
  /// Arabic is not a fallback here, it is the language the mission works in:
  /// the master data is Arabic, half the English column in the catalog was
  /// never filled in, and every notification the database composes is written
  /// in it. A phone set to English is a phone, not a decision.
  ///
  /// Null still means "follow the device", and is still reachable — it is
  /// simply no longer what you get by saying nothing.
  static Locale? _readLocale(SharedPreferences p) {
    final code = p.getString(localeKey);
    if (code == followSystem) return null;
    return code == null ? const Locale('ar') : Locale(code);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(state.copyWith(themeMode: mode));
    await _prefs.setString(_kTheme, mode.name);
  }

  Future<void> setSolidSurfaces(bool solid) async {
    emit(state.copyWith(solidSurfaces: solid));
    await _prefs.setBool(_kSolidSurfaces, solid);
  }

  /// Which shape the home page takes. Written by name rather than by index, so
  /// that reordering the enum one day does not silently move everybody who
  /// chose the rail back onto the grid.
  Future<void> setHomeLayout(HomeLayout layout) async {
    emit(state.copyWith(homeLayout: layout));
    await _prefs.setString(_kHomeLayout, layout.name);
  }

  /// What stands at the top of the home page.
  ///
  /// One switch, for the one card that is there. It is on by default and takes
  /// an act to turn off: the times are the thing a man looks at without having
  /// decided to look at anything, and what it costs when it is unwanted is the
  /// top third of the page — which is exactly why the switch exists.
  Future<void> setShowPrayerCard(bool show) async {
    emit(state.copyWith(showPrayerCard: show));
    await _prefs.setBool(_kPrayerCard, show);
  }

  /// Folding and unfolding the rail. Persisted rather than held in the screen's
  /// own state: it is a habit, not a moment — a man who works folded wants it
  /// folded tomorrow, and re-folding it on every cold start is the sort of
  /// small insult an app is never forgiven for.
  Future<void> setSidebarExpanded(bool expanded) async {
    emit(state.copyWith(sidebarExpanded: expanded));
    await _prefs.setBool(_kSidebarExpanded, expanded);
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
    // The sentinel rather than removing the key — see [followSystem].
    await _prefs.setString(localeKey, locale?.languageCode ?? followSystem);
    // The screen re-renders itself; the two things OUTSIDE it do not. A week of
    // prayer alarms and the home-screen widget both carry finished sentences,
    // written in whichever language was chosen when they were laid down, and
    // they would go on saying "Fajr is now due" in an app that had been Arabic
    // for a month. So they are written again, in the new language.
    await PrayerScheduler.instance.refresh();
  }
}
