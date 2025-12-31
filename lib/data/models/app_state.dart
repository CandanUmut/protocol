import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';
import 'day_entry.dart';
import 'emergency_session.dart';
import 'emergency_timer_state.dart';
import 'todo_item.dart';
import 'trigger_log.dart';

class AppStateModel {
  AppStateModel({
    this.schemaVersion = AppConstants.schemaVersion,
    this.lang = 'tr',
    this.goalDays = AppConstants.defaultGoalDays,
    this.requireWalk = AppConstants.defaultRequireWalk,
    this.soundEnabled = false,
    this.hapticsEnabled = true,
    this.notificationsEnabled = true,
    this.riskWindowStartHour = AppConstants.defaultRiskStart,
    this.riskWindowEndHour = AppConstants.defaultRiskEnd,
    this.ifThenPlan = 'IF I feel negotiation THEN I evacuate.',
    this.activeEmergencySessionId,
    List<TodoItem>? todos,
    Map<String, DayEntry>? days,
    EmergencyTimerState? timer,
    List<EmergencySession>? emergencySessions,
    List<TriggerLog>? triggerLogs,
  })  : todos = todos ?? [],
        days = days ?? {},
        emergencySessions = emergencySessions ?? [],
        triggerLogs = triggerLogs ?? [],
        timer = timer ?? EmergencyTimerState.initial(AppConstants.timerDurationMinutes * 60);

  final int schemaVersion;
  final String lang;
  final int goalDays;
  final bool requireWalk;
  final bool soundEnabled;
  final bool hapticsEnabled;
  final bool notificationsEnabled;
  final int riskWindowStartHour;
  final int riskWindowEndHour;
  final String ifThenPlan;
  final List<TodoItem> todos;
  final Map<String, DayEntry> days;
  final EmergencyTimerState timer;
  final List<EmergencySession> emergencySessions;
  final List<TriggerLog> triggerLogs;
  final String? activeEmergencySessionId;

  AppStateModel copyWith({
    int? schemaVersion,
    String? lang,
    int? goalDays,
    bool? requireWalk,
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? notificationsEnabled,
    int? riskWindowStartHour,
    int? riskWindowEndHour,
    String? ifThenPlan,
    List<TodoItem>? todos,
    Map<String, DayEntry>? days,
    EmergencyTimerState? timer,
    List<EmergencySession>? emergencySessions,
    List<TriggerLog>? triggerLogs,
    String? activeEmergencySessionId,
  }) {
    return AppStateModel(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      lang: lang ?? this.lang,
      goalDays: goalDays ?? this.goalDays,
      requireWalk: requireWalk ?? this.requireWalk,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      riskWindowStartHour: riskWindowStartHour ?? this.riskWindowStartHour,
      riskWindowEndHour: riskWindowEndHour ?? this.riskWindowEndHour,
      ifThenPlan: ifThenPlan ?? this.ifThenPlan,
      todos: todos ?? this.todos,
      days: days ?? this.days,
      timer: timer ?? this.timer,
      emergencySessions: emergencySessions ?? this.emergencySessions,
      triggerLogs: triggerLogs ?? this.triggerLogs,
      activeEmergencySessionId: activeEmergencySessionId ?? this.activeEmergencySessionId,
    );
  }

  factory AppStateModel.fromJson(Map<String, dynamic> json) {
    final todoList = (json['todos'] as List? ?? [])
        .map((e) => TodoItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final dayMap = <String, DayEntry>{};
    (json['days'] as Map? ?? {}).forEach((key, value) {
      dayMap[key as String] = DayEntry.fromJson(Map<String, dynamic>.from(value as Map));
    });
    final sessions = (json['emergencySessions'] as List? ?? [])
        .map((e) => EmergencySession.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final triggers = (json['triggerLogs'] as List? ?? [])
        .map((e) => TriggerLog.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return AppStateModel(
      schemaVersion: json['schemaVersion'] as int? ?? AppConstants.schemaVersion,
      lang: json['lang'] as String? ?? 'tr',
      goalDays: json['goalDays'] as int? ?? AppConstants.defaultGoalDays,
      requireWalk: json['requireWalk'] as bool? ?? AppConstants.defaultRequireWalk,
      soundEnabled: json['soundEnabled'] as bool? ?? false,
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      riskWindowStartHour: json['riskWindowStartHour'] as int? ?? AppConstants.defaultRiskStart,
      riskWindowEndHour: json['riskWindowEndHour'] as int? ?? AppConstants.defaultRiskEnd,
      ifThenPlan: json['ifThenPlan'] as String? ?? 'IF I feel negotiation THEN I evacuate.',
      todos: todoList,
      days: dayMap,
      timer: json['timer'] != null
          ? EmergencyTimerState.fromJson(Map<String, dynamic>.from(json['timer'] as Map))
          : EmergencyTimerState.initial(AppConstants.timerDurationMinutes * 60),
      emergencySessions: sessions,
      triggerLogs: triggers,
      activeEmergencySessionId: json['activeEmergencySessionId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'lang': lang,
        'goalDays': goalDays,
        'requireWalk': requireWalk,
        'soundEnabled': soundEnabled,
        'hapticsEnabled': hapticsEnabled,
        'notificationsEnabled': notificationsEnabled,
        'riskWindowStartHour': riskWindowStartHour,
        'riskWindowEndHour': riskWindowEndHour,
        'ifThenPlan': ifThenPlan,
        'todos': todos.map((e) => e.toJson()).toList(),
        'days': days.map((key, value) => MapEntry(key, value.toJson())),
        'timer': timer.toJson(),
        'emergencySessions': emergencySessions.map((e) => e.toJson()).toList(),
        'triggerLogs': triggerLogs.map((e) => e.toJson()).toList(),
        'activeEmergencySessionId': activeEmergencySessionId,
      };

  DayEntry dayFor(DateTime date) {
    final key = isoDate(date);
    return days[key] ?? DayEntry();
  }

  int streak(DateTime today) {
    int count = 0;
    DateTime cursor = startOfDay(today);
    while (true) {
      final key = isoDate(cursor);
      final entry = days[key];
      if (entry == null || !entry.isSuccess(requireWalk: requireWalk)) break;
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }

  int successThisMonth(DateTime today) {
    final start = DateTime(today.year, today.month, 1);
    final end = DateTime(today.year, today.month + 1, 0);
    int total = 0;
    for (int i = 0; i < end.day; i++) {
      final date = start.add(Duration(days: i));
      final entry = dayFor(date);
      if (entry.isSuccess(requireWalk: requireWalk)) total++;
    }
    return total;
  }

  int emergenciesThisMonth(DateTime today) {
    final start = DateTime(today.year, today.month, 1);
    final end = DateTime(today.year, today.month + 1, 0);
    int total = 0;
    for (int i = 0; i < end.day; i++) {
      final date = start.add(Duration(days: i));
      total += dayFor(date).emergencies;
    }
    return total;
  }

  DayStatus statusFor(DateTime date) {
    final entry = dayFor(date);
    if (entry.isSuccess(requireWalk: requireWalk)) return DayStatus.good;
    if (entry.isPartial(requireWalk: requireWalk)) return DayStatus.partial;
    return DayStatus.empty;
  }

  int protectionScore(DateTime date) {
    final entry = dayFor(date);
    int score = 0;
    if (entry.noNegotiation) score++;
    if (entry.noPhoneBedroom) score++;
    if (entry.dailyWalk || !requireWalk) score++;
    if (entry.emergencies > 0) score++;
    return (score / 4 * 100).round();
  }

  bool get inNightRiskWindow {
    final now = DateTime.now();
    final start = riskWindowStartHour;
    final end = riskWindowEndHour;
    if (start < end) {
      return now.hour >= start && now.hour < end;
    }
    return now.hour >= start || now.hour < end;
  }
}

enum DayStatus { good, partial, empty }
