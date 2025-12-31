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
  String get requireWalkNote => _strings['require_walk_note'] ?? '';
  String get protectionScore => _strings['protection_score'] ?? '';
  String get nightRisk => _strings['night_risk'] ?? '';
  String get coreRules => _strings['core_rules'] ?? '';
  String get preventionToolkit => _strings['prevention_toolkit'] ?? '';
  String get urgeSurfingTitle => _strings['urge_surfing_title'] ?? '';
  String get urgeSurfingBody => _strings['urge_surfing_body'] ?? '';
  String get start90s => _strings['start_90s'] ?? '';
  String get remaining => _strings['remaining'] ?? '';
  String get ifThenPlan => _strings['if_then_plan'] ?? '';
  String get ifThenPlaceholder => _strings['if_then_placeholder'] ?? '';
  String get triggerLogTitle => _strings['trigger_log_title'] ?? '';
  String get milestoneBody => _strings['milestone_body'] ?? '';
  String get emergencyMicrocopy => _strings['emergency_microcopy'] ?? '';
  String get emergencyModeTitle => _strings['emergency_mode_title'] ?? '';
  String get sessionHistory => _strings['session_history'] ?? '';
  String get emptySessions => _strings['empty_sessions'] ?? '';
  String get stepsCompleted => _strings['steps_completed'] ?? '';
  String get minutes => _strings['minutes'] ?? '';
  String get stepOutside => _strings['step_outside'] ?? '';
  String get stepStartTimer => _strings['step_start_timer'] ?? '';
  String get stepCallFriend => _strings['step_call_friend'] ?? '';
  String get stepWalk => _strings['step_walk'] ?? '';
  String get stepBreath => _strings['step_breath'] ?? '';
  String get insights => _strings['insights'] ?? '';
  String get settings => _strings['settings'] ?? '';
  String get streakTrend => _strings['streak_trend'] ?? '';
  String get emergenciesPerWeek => _strings['emergencies_per_week'] ?? '';
  String get topTriggers => _strings['top_triggers'] ?? '';
  String get noTriggers => _strings['no_triggers'] ?? '';
  String get language => _strings['language'] ?? '';
  String get riskWindow => _strings['risk_window'] ?? '';
  String get riskWindowNote => _strings['risk_window_note'] ?? '';
  String get notifications => _strings['notifications'] ?? '';
  String get notificationsBody => _strings['notifications_body'] ?? '';
  String get sounds => _strings['sounds'] ?? '';
  String get soundsBody => _strings['sounds_body'] ?? '';
  String get haptics => _strings['haptics'] ?? '';
  String get hapticsBody => _strings['haptics_body'] ?? '';
  String get dataControl => _strings['data_control'] ?? '';
  String get privacyInfo => _strings['privacy_info'] ?? '';
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
