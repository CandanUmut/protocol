import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';
import 'day_entry.dart';
import 'emergency_session.dart';
import 'emergency_timer_state.dart';
import 'protocol.dart';
import 'todo_item.dart';
import 'trigger_log.dart';

class Challenge {
  Challenge({
    String? id,
    this.name = 'Protocol',
    this.icon = '🌿',
    this.themeColorKey = 'emerald',
    this.goalDays = AppConstants.defaultGoalDays,
    this.requireDailyAction = AppConstants.defaultRequireWalk,
    this.riskWindowStartHour = AppConstants.defaultRiskStart,
    this.riskWindowEndHour = AppConstants.defaultRiskEnd,
    this.defaultProtocolTemplateId,
    this.ifThenPlan = 'IF I feel negotiation THEN I evacuate.',
    List<TodoItem>? todos,
    Map<String, DayEntry>? days,
    List<EmergencySession>? emergencySessions,
    List<TriggerLog>? triggerLogs,
    EmergencyTimerState? timer,
    this.activeEmergencySessionId,
    List<String>? dismissedBadges,
  })  : id = id ?? const Uuid().v4(),
        todos = todos ?? [],
        days = days ?? {},
        emergencySessions = emergencySessions ?? [],
        triggerLogs = triggerLogs ?? [],
        timer = timer ?? EmergencyTimerState.initial(AppConstants.timerDurationMinutes * 60),
        dismissedBadges = dismissedBadges ?? [];

  final String id;
  final String name;
  final String icon;
  final String themeColorKey;
  final int goalDays;
  final bool requireDailyAction;
  final int riskWindowStartHour;
  final int riskWindowEndHour;
  final String? defaultProtocolTemplateId;
  final String ifThenPlan;
  final List<TodoItem> todos;
  final Map<String, DayEntry> days;
  final List<EmergencySession> emergencySessions;
  final List<TriggerLog> triggerLogs;
  final EmergencyTimerState timer;
  final String? activeEmergencySessionId;
  final List<String> dismissedBadges;

  Challenge copyWith({
    String? id,
    String? name,
    String? icon,
    String? themeColorKey,
    int? goalDays,
    bool? requireDailyAction,
    int? riskWindowStartHour,
    int? riskWindowEndHour,
    String? defaultProtocolTemplateId,
    String? ifThenPlan,
    List<TodoItem>? todos,
    Map<String, DayEntry>? days,
    List<EmergencySession>? emergencySessions,
    List<TriggerLog>? triggerLogs,
    EmergencyTimerState? timer,
    String? activeEmergencySessionId,
    List<String>? dismissedBadges,
  }) {
    return Challenge(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      themeColorKey: themeColorKey ?? this.themeColorKey,
      goalDays: goalDays ?? this.goalDays,
      requireDailyAction: requireDailyAction ?? this.requireDailyAction,
      riskWindowStartHour: riskWindowStartHour ?? this.riskWindowStartHour,
      riskWindowEndHour: riskWindowEndHour ?? this.riskWindowEndHour,
      defaultProtocolTemplateId: defaultProtocolTemplateId ?? this.defaultProtocolTemplateId,
      ifThenPlan: ifThenPlan ?? this.ifThenPlan,
      todos: todos ?? this.todos,
      days: days ?? this.days,
      emergencySessions: emergencySessions ?? this.emergencySessions,
      triggerLogs: triggerLogs ?? this.triggerLogs,
      timer: timer ?? this.timer,
      activeEmergencySessionId: activeEmergencySessionId ?? this.activeEmergencySessionId,
      dismissedBadges: dismissedBadges ?? this.dismissedBadges,
    );
  }

  factory Challenge.fromJson(Map<String, dynamic> json) {
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
    return Challenge(
      id: json['id'] as String?,
      name: json['name'] as String? ?? 'Protocol',
      icon: json['icon'] as String? ?? '🌿',
      themeColorKey: json['themeColorKey'] as String? ?? 'emerald',
      goalDays: json['goalDays'] as int? ?? AppConstants.defaultGoalDays,
      requireDailyAction: json['requireDailyAction'] as bool? ?? true,
      riskWindowStartHour: json['riskWindowStartHour'] as int? ?? AppConstants.defaultRiskStart,
      riskWindowEndHour: json['riskWindowEndHour'] as int? ?? AppConstants.defaultRiskEnd,
      defaultProtocolTemplateId: json['defaultProtocolTemplateId'] as String?,
      ifThenPlan: json['ifThenPlan'] as String? ?? 'IF I feel negotiation THEN I evacuate.',
      todos: todoList,
      days: dayMap,
      emergencySessions: sessions,
      triggerLogs: triggers,
      timer: json['timer'] != null
          ? EmergencyTimerState.fromJson(Map<String, dynamic>.from(json['timer'] as Map))
          : EmergencyTimerState.initial(AppConstants.timerDurationMinutes * 60),
      activeEmergencySessionId: json['activeEmergencySessionId'] as String?,
      dismissedBadges: (json['dismissedBadges'] as List? ?? []).map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'themeColorKey': themeColorKey,
        'goalDays': goalDays,
        'requireDailyAction': requireDailyAction,
        'riskWindowStartHour': riskWindowStartHour,
        'riskWindowEndHour': riskWindowEndHour,
        'defaultProtocolTemplateId': defaultProtocolTemplateId,
        'ifThenPlan': ifThenPlan,
        'todos': todos.map((e) => e.toJson()).toList(),
        'days': days.map((key, value) => MapEntry(key, value.toJson())),
        'emergencySessions': emergencySessions.map((e) => e.toJson()).toList(),
        'triggerLogs': triggerLogs.map((e) => e.toJson()).toList(),
        'timer': timer.toJson(),
        'activeEmergencySessionId': activeEmergencySessionId,
        'dismissedBadges': dismissedBadges,
      };

  DayEntry dayFor(DateTime date) => days[isoDate(date)] ?? DayEntry();

  int streak(DateTime today) {
    int count = 0;
    DateTime cursor = startOfDay(today);
    while (true) {
      final key = isoDate(cursor);
      final entry = days[key];
      if (entry == null || !entry.isSuccess(requireWalk: requireDailyAction)) break;
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
      if (entry.isSuccess(requireWalk: requireDailyAction)) total++;
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

  bool badgeUnlocked(String badge) => !dismissedBadges.contains(badge) && streak(DateTime.now()) >= int.parse(badge);
}
