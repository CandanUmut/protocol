import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';
import 'day_entry.dart';
import 'emergency_timer_state.dart';
import 'todo_item.dart';

class AppStateModel {
  AppStateModel({
    this.schemaVersion = AppConstants.schemaVersion,
    this.lang = 'tr',
    this.goalDays = AppConstants.defaultGoalDays,
    this.requireWalk = AppConstants.defaultRequireWalk,
    List<TodoItem>? todos,
    Map<String, DayEntry>? days,
    EmergencyTimerState? timer,
  })  : todos = todos ?? [],
        days = days ?? {},
        timer = timer ?? EmergencyTimerState.initial(AppConstants.timerDurationMinutes * 60);

  final int schemaVersion;
  final String lang;
  final int goalDays;
  final bool requireWalk;
  final List<TodoItem> todos;
  final Map<String, DayEntry> days;
  final EmergencyTimerState timer;

  AppStateModel copyWith({
    int? schemaVersion,
    String? lang,
    int? goalDays,
    bool? requireWalk,
    List<TodoItem>? todos,
    Map<String, DayEntry>? days,
    EmergencyTimerState? timer,
  }) {
    return AppStateModel(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      lang: lang ?? this.lang,
      goalDays: goalDays ?? this.goalDays,
      requireWalk: requireWalk ?? this.requireWalk,
      todos: todos ?? this.todos,
      days: days ?? this.days,
      timer: timer ?? this.timer,
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
    return AppStateModel(
      schemaVersion: json['schemaVersion'] as int? ?? AppConstants.schemaVersion,
      lang: json['lang'] as String? ?? 'tr',
      goalDays: json['goalDays'] as int? ?? AppConstants.defaultGoalDays,
      requireWalk: json['requireWalk'] as bool? ?? AppConstants.defaultRequireWalk,
      todos: todoList,
      days: dayMap,
      timer: json['timer'] != null
          ? EmergencyTimerState.fromJson(Map<String, dynamic>.from(json['timer'] as Map))
          : EmergencyTimerState.initial(AppConstants.timerDurationMinutes * 60),
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'lang': lang,
        'goalDays': goalDays,
        'requireWalk': requireWalk,
        'todos': todos.map((e) => e.toJson()).toList(),
        'days': days.map((key, value) => MapEntry(key, value.toJson())),
        'timer': timer.toJson(),
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
}

enum DayStatus { good, partial, empty }
