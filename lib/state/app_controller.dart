import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/date_utils.dart';
import '../core/utils/haptics.dart';
import '../core/utils/sound.dart';
import '../data/models/app_state.dart';
import '../data/models/day_entry.dart';
import '../data/models/emergency_session.dart';
import '../data/models/todo_item.dart';
import '../data/models/trigger_log.dart';
import '../data/repositories/app_repository.dart';
import '../features/emergency/notification_service.dart';
import '../features/emergency/timer_service.dart';

final appRepositoryProvider = Provider<AppRepository>((_) => AppRepository());
final selectedDateProvider = StateProvider<DateTime>((_) => DateTime.now());

final appControllerProvider = StateNotifierProvider<AppController, AppStateModel>((ref) {
  final repo = ref.watch(appRepositoryProvider);
  final controller = AppController(ref, repo);
  ref.onDispose(controller.dispose);
  return controller;
});

class AppController extends StateNotifier<AppStateModel> {
  AppController(this._ref, this._repository) : super(AppStateModel()) {
    _init();
  }

  final Ref _ref;
  final AppRepository _repository;
  final TimerService _timerService = TimerService();
  Timer? _ticker;

  Future<void> _init() async {
    final loaded = await _repository.load();
    state = loaded;
    _ref.read(appLocaleProvider.notifier).setLocale(Locale(loaded.lang));
    _resumeTimer();
  }

  void dispose() {
    _ticker?.cancel();
    _timerService.dispose();
    super.dispose();
  }

  Future<void> _persist() async => _repository.save(state);

  void setLanguage(String code) {
    state = state.copyWith(lang: code);
    _ref.read(appLocaleProvider.notifier).setLocale(Locale(code));
    _persist();
  }

  void toggleSound(bool value) {
    state = state.copyWith(soundEnabled: value);
    _persist();
  }

  void toggleHaptics(bool value) {
    state = state.copyWith(hapticsEnabled: value);
    _persist();
  }

  void toggleNotifications(bool value) {
    state = state.copyWith(notificationsEnabled: value);
    if (value) NotificationService.instance.requestPermission();
    _persist();
  }

  void updateRiskWindow(int startHour, int endHour) {
    state = state.copyWith(riskWindowStartHour: startHour, riskWindowEndHour: endHour);
    _persist();
  }

  void updateIfThenPlan(String value) {
    state = state.copyWith(ifThenPlan: value);
    _persist();
  }

  void toggleRequireWalk(bool value) {
    state = state.copyWith(requireWalk: value);
    _persist();
  }

  void setGoalDays(int value) {
    state = state.copyWith(goalDays: value);
    _persist();
  }

  void toggleCore(String key, bool value) {
    final date = _ref.read(selectedDateProvider);
    final entry = state.dayFor(date);
    final updated = entry.copyWith(
      noNegotiation: key == 'noNegotiation' ? value : entry.noNegotiation,
      noPhoneBedroom: key == 'noPhoneBedroom' ? value : entry.noPhoneBedroom,
      dailyWalk: key == 'dailyWalk' ? value : entry.dailyWalk,
    );
    _upsertDay(date, updated);
    lightHaptic(enabled: state.hapticsEnabled);
  }

  void toggleTodo(String todoId, bool value) {
    final date = _ref.read(selectedDateProvider);
    final entry = state.dayFor(date);
    final newTodoStates = Map<String, bool>.from(entry.todoStates)..[todoId] = value;
    _upsertDay(date, entry.copyWith(todoStates: newTodoStates));
  }

  void markAll() {
    final date = _ref.read(selectedDateProvider);
    _upsertDay(date, state.dayFor(date).copyWith(noNegotiation: true, noPhoneBedroom: true, dailyWalk: true));
  }

  void clearDay() {
    final date = _ref.read(selectedDateProvider);
    _upsertDay(date, DayEntry());
  }

  void addTodo(String title) {
    final todos = [...state.todos, TodoItem(title: title)];
    state = state.copyWith(todos: todos);
    _persist();
  }

  void deleteTodo(String id) {
    final todos = state.todos.where((t) => t.id != id).toList();
    final days = Map<String, DayEntry>.from(state.days);
    for (final entry in days.entries) {
      final newStates = Map<String, bool>.from(entry.value.todoStates)..remove(id);
      days[entry.key] = entry.value.copyWith(todoStates: newStates);
    }
    state = state.copyWith(todos: todos, days: days);
    _persist();
  }

  void updateNotes(String notes) {
    final date = _ref.read(selectedDateProvider);
    _upsertDay(date, state.dayFor(date).copyWith(notes: notes));
  }

  void logEmergency() {
    final date = _ref.read(selectedDateProvider);
    final entry = state.dayFor(date);
    _upsertDay(date, entry.copyWith(emergencies: entry.emergencies + 1));
  }

  void markOutside() {
    final date = _ref.read(selectedDateProvider);
    final entry = state.dayFor(date);
    _upsertDay(date, entry.copyWith(noNegotiation: true));
    _updateActiveSession((session) => session.copyWith(outsideConfirmed: true));
  }

  void setSelectedDate(DateTime date) {
    _ref.read(selectedDateProvider.notifier).state = date;
  }

  void _upsertDay(DateTime date, DayEntry entry) {
    final key = isoDate(date);
    final newDays = Map<String, DayEntry>.from(state.days)..[key] = entry;
    state = state.copyWith(days: newDays);
    _persist();
  }

  Future<void> reset() async {
    await _repository.reset();
    state = AppStateModel();
    _ref.read(appLocaleProvider.notifier).setLocale(const Locale('tr'));
  }

  Future<void> importState() async {
    final imported = await _repository.importJson();
    if (imported != null) {
      state = imported;
      _ref.read(appLocaleProvider.notifier).setLocale(Locale(imported.lang));
      _resumeTimer();
    }
  }

  Future<String> exportState() async => _repository.exportJson(state);

  void startEmergencyTimer() {
    final next = _timerService.start(state.timer, notificationsEnabled: state.notificationsEnabled);
    state = state.copyWith(timer: next);
    _ensureActiveEmergencySession();
    if (state.soundEnabled) SoundPlayer.instance.playClick();
    _persist();
    _beginTicker();
  }

  void pauseEmergencyTimer() {
    final next = _timerService.pause(state.timer);
    state = state.copyWith(timer: next);
    _persist();
  }

  void resetEmergencyTimer() {
    final next = _timerService.reset();
    state = state.copyWith(timer: next, activeEmergencySessionId: null);
    _persist();
  }

  void _resumeTimer() {
    if (state.timer.running && state.timer.endAtEpochMillis != null) {
      state = state.copyWith(timer: _timerService.tick(state.timer));
      _beginTicker();
    }
  }

  void _beginTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final updated = _timerService.tick(state.timer);
      if (updated.remainingSeconds != state.timer.remainingSeconds || updated.running != state.timer.running) {
        state = state.copyWith(timer: updated);
        _persist();
      }
      if (!updated.running) {
        _ticker?.cancel();
        _completeEmergencySession();
      }
    });
  }

  void _ensureActiveEmergencySession() {
    if (state.activeEmergencySessionId != null) return;
    final session = EmergencySession(id: const Uuid().v4(), startedAt: DateTime.now());
    final sessions = [...state.emergencySessions, session];
    final trimmed = sessions.length > 10 ? sessions.sublist(sessions.length - 10) : sessions;
    state = state.copyWith(emergencySessions: trimmed, activeEmergencySessionId: session.id);
  }

  void _completeEmergencySession() {
    if (state.activeEmergencySessionId == null) return;
    _updateActiveSession((session) => session.copyWith(
          completedAt: DateTime.now(),
          durationSeconds: AppConstants.timerDurationMinutes * 60,
        ));
    state = state.copyWith(activeEmergencySessionId: null);
    _persist();
    if (state.soundEnabled) SoundPlayer.instance.playChime();
  }

  void updateSessionStep(String stepKey, bool value) {
    _updateActiveSession((session) {
      final steps = Map<String, bool>.from(session.steps)..[stepKey] = value;
      return session.copyWith(steps: steps);
    });
    _persist();
    lightHaptic(enabled: state.hapticsEnabled);
  }

  void addTriggerLog(String trigger, {String? note}) {
    final log = TriggerLog(dateKey: isoDate(DateTime.now()), trigger: trigger, note: note, sessionId: state.activeEmergencySessionId);
    final updated = [...state.triggerLogs, log];
    state = state.copyWith(triggerLogs: updated);
    _persist();
  }

  void _updateActiveSession(EmergencySession Function(EmergencySession) transform) {
    final id = state.activeEmergencySessionId;
    if (id == null) return;
    final sessions = [...state.emergencySessions];
    final idx = sessions.indexWhere((s) => s.id == id);
    if (idx == -1) return;
    sessions[idx] = transform(sessions[idx]);
    state = state.copyWith(emergencySessions: sessions);
  }
}
