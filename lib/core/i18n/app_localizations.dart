import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppLocalizations {
  AppLocalizations(this.locale, this._strings);

  final Locale locale;
  final Map<String, String> _strings;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String get appTitle => _strings['app_title'] ?? '';
  String get dashboardTitle => _strings['dashboard_title'] ?? '';
  String get calendarTitle => _strings['calendar_title'] ?? '';
  String get emergency => _strings['emergency'] ?? '';
  String get evacuate => _strings['evacuate'] ?? '';
  String get streak => _strings['streak'] ?? '';
  String get goal => _strings['goal'] ?? '';
  String get todayStatus => _strings['today_status'] ?? '';
  String get good => _strings['good'] ?? '';
  String get partial => _strings['partial'] ?? '';
  String get empty => _strings['empty'] ?? '';
  String get rule1 => _strings['rule1'] ?? '';
  String get rule2 => _strings['rule2'] ?? '';
  String get dailyWalk => _strings['daily_walk'] ?? '';
  String get markAll => _strings['mark_all'] ?? '';
  String get clearDay => _strings['clear_day'] ?? '';
  String get logEmergency => _strings['log_emergency'] ?? '';
  String get notes => _strings['notes'] ?? '';
  String get languageToggle => _strings['language_toggle'] ?? '';
  String get importLabel => _strings['import'] ?? '';
  String get exportLabel => _strings['export'] ?? '';
  String get reset => _strings['reset'] ?? '';
  String get confirmReset => _strings['confirm_reset'] ?? '';
  String get cancel => _strings['cancel'] ?? '';
  String get confirm => _strings['confirm'] ?? '';
  String get goalDays => _strings['goal_days'] ?? '';
  String get emergencySteps => _strings['emergency_steps'] ?? '';
  String get timerStart => _strings['timer_start'] ?? '';
  String get timerPause => _strings['timer_pause'] ?? '';
  String get timerReset => _strings['timer_reset'] ?? '';
  String get imOutside => _strings['im_outside'] ?? '';
  String get emergencyComplete => _strings['emergency_complete'] ?? '';
  String get emergencyCompleteBody => _strings['emergency_complete_body'] ?? '';
  String get monthSuccess => _strings['month_success'] ?? '';
  String get monthEmergencies => _strings['month_emergencies'] ?? '';
  String get todayEmergency => _strings['today_emergency'] ?? '';
  String get successDay => _strings['success_day'] ?? '';
  String get supportiveChip => _strings['supportive_chip'] ?? '';
  String get gentleReminder => _strings['gentle_reminder'] ?? '';
  String get progress => _strings['progress'] ?? '';
  String get requireWalk => _strings['require_walk'] ?? '';
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'tr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final data = await rootBundle.loadString('assets/i18n/${locale.languageCode}.json');
    final map = Map<String, dynamic>.from(json.decode(data));
    return AppLocalizations(locale, map.map((k, v) => MapEntry(k, v.toString())));
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}

final appLocaleProvider = StateNotifierProvider<LocaleController, LocaleState>((ref) {
  return LocaleController();
});

class LocaleState {
  const LocaleState(this.locale);
  final Locale locale;
}

class LocaleController extends StateNotifier<LocaleState> {
  LocaleController() : super(const LocaleState(Locale('tr')));

  void setLocale(Locale locale) {
    state = LocaleState(locale);
  }

  void toggle() {
    state = LocaleState(state.locale.languageCode == 'tr' ? const Locale('en') : const Locale('tr'));
  }
}
