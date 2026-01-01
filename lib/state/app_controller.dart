import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/date_utils.dart';
import '../core/utils/haptics.dart';
import '../core/utils/sound.dart';
import '../data/models/app_state.dart';
import '../data/models/challenge.dart';
import '../data/models/day_entry.dart';
import '../data/models/emergency_session.dart';
import '../data/models/emergency_timer_state.dart';
import '../data/models/protocol.dart';
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

  Challenge get _activeChallenge => state.activeChallenge;
  ProtocolTemplate get _activeTemplate =>
      state.templates.firstWhere((t) => t.id == _activeChallenge.defaultProtocolTemplateId, orElse: () => state.templates.first);

  void setLanguage(String code) {
    state = state.copyWith(lang: code);
    _ref.read(appLocaleProvider.notifier).setLocale(Locale(code));
    _persist();
  }

  void setActiveChallenge(String id) {
    if (state.challenges.any((c) => c.id == id)) {
      state = state.copyWith(activeChallengeId: id);
      _persist();
    }
  }

  void saveTemplate(ProtocolTemplate template, {bool setAsDefault = false}) {
    final filtered = state.templates.where((t) => t.id != template.id).toList();
    final next = [...filtered, template];
    state = state.copyWith(templates: next);
    if (setAsDefault) {
      setDefaultTemplate(template.id);
    } else {
      _persist();
    }
  }

  void addChallenge(Challenge challenge) {
    final next = [...state.challenges, challenge];
    state = state.copyWith(challenges: next, activeChallengeId: challenge.id);
    _persist();
  }

  void updateChallenge(Challenge challenge) {
    final list = state.challenges.map((c) => c.id == challenge.id ? challenge : c).toList();
    state = state.copyWith(challenges: list, activeChallengeId: challenge.id);
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

  void updateAlarm(AlarmSettings settings) {
    state = state.copyWith(alarmSettings: settings);
    _persist();
  }

  void completeOnboarding() {
    state = state.copyWith(onboardingDone: true);
    _persist();
  }

  void setDefaultTemplate(String templateId) {
    if (!state.templates.any((t) => t.id == templateId)) return;
    _updateActiveChallenge((challenge) => challenge.copyWith(defaultProtocolTemplateId: templateId));
  }

  List<ProtocolTemplate> recommendedTemplates(String type) {
    final filtered = state.templates.where((t) => t.recommendedFor.contains(type)).toList();
    if (filtered.isNotEmpty) return filtered.take(2).toList();
    return state.templates.take(2).toList();
  }

  void updateRiskWindow(int startHour, int endHour) {
    _updateActiveChallenge((challenge) => challenge.copyWith(
          riskWindowStartHour: startHour,
          riskWindowEndHour: endHour,
        ));
  }

  void updateIfThenPlan(String value) {
    _updateActiveChallenge((challenge) => challenge.copyWith(ifThenPlan: value));
  }

  void toggleRequireWalk(bool value) {
    _updateActiveChallenge((challenge) => challenge.copyWith(requireDailyAction: value));
  }

  void setGoalDays(int value) {
    _updateActiveChallenge((challenge) => challenge.copyWith(goalDays: value));
  }

  void toggleCore(String key, bool value) {
    final date = _ref.read(selectedDateProvider);
    final entry = _activeChallenge.dayFor(date);
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
    final entry = _activeChallenge.dayFor(date);
    final newTodoStates = Map<String, bool>.from(entry.todoStates)..[todoId] = value;
    _upsertDay(date, entry.copyWith(todoStates: newTodoStates));
  }

  void markAll() {
    final date = _ref.read(selectedDateProvider);
    _upsertDay(date, _activeChallenge.dayFor(date).copyWith(noNegotiation: true, noPhoneBedroom: true, dailyWalk: true));
  }

  void clearDay() {
    final date = _ref.read(selectedDateProvider);
    _upsertDay(date, DayEntry());
  }

  void addTodo(String title) {
    final todos = [..._activeChallenge.todos, TodoItem(title: title)];
    _updateActiveChallenge((challenge) => challenge.copyWith(todos: todos));
  }

  void deleteTodo(String id) {
    final todos = _activeChallenge.todos.where((t) => t.id != id).toList();
    final days = Map<String, DayEntry>.from(_activeChallenge.days);
    for (final entry in days.entries) {
      final newStates = Map<String, bool>.from(entry.value.todoStates)..remove(id);
      days[entry.key] = entry.value.copyWith(todoStates: newStates);
    }
    _updateActiveChallenge((challenge) => challenge.copyWith(todos: todos, days: days));
  }

  void updateNotes(String notes) {
    final date = _ref.read(selectedDateProvider);
    _upsertDay(date, _activeChallenge.dayFor(date).copyWith(notes: notes));
  }

  void logEmergency() {
    final date = _ref.read(selectedDateProvider);
    final entry = _activeChallenge.dayFor(date);
    _upsertDay(date, entry.copyWith(emergencies: entry.emergencies + 1));
  }

  void markOutside() {
    final date = _ref.read(selectedDateProvider);
    final entry = _activeChallenge.dayFor(date);
    _upsertDay(date, entry.copyWith(noNegotiation: true));
    _updateActiveSession((session) => session.copyWith(outsideConfirmed: true));
  }

  void setSelectedDate(DateTime date) {
    _ref.read(selectedDateProvider.notifier).state = date;
  }

  void _upsertDay(DateTime date, DayEntry entry) {
    final key = isoDate(date);
    final newDays = Map<String, DayEntry>.from(_activeChallenge.days)..[key] = entry;
    _updateActiveChallenge((challenge) => challenge.copyWith(days: newDays));
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
    final nextTimer = _timerService.start(_activeChallenge.timer, notificationsEnabled: state.notificationsEnabled);
    _updateActiveChallenge((challenge) => challenge.copyWith(timer: nextTimer));
    _ensureActiveEmergencySession();
    if (state.soundEnabled) SoundPlayer.instance.playAlarm(state.alarmSettings);
    _persist();
    _beginTicker();
  }

  void pauseEmergencyTimer() {
    final next = _timerService.pause(_activeChallenge.timer);
    _updateActiveChallenge((challenge) => challenge.copyWith(timer: next));
    _persist();
  }

  void resetEmergencyTimer() {
    final next = _timerService.reset();
    _updateActiveChallenge((challenge) => challenge.copyWith(timer: next, activeEmergencySessionId: null));
    _persist();
  }

  void _resumeTimer() {
    final timer = _activeChallenge.timer;
    if (timer.running && timer.endAtEpochMillis != null) {
      final updatedTimer = _timerService.tick(timer);
      _updateActiveChallenge((challenge) => challenge.copyWith(timer: updatedTimer));
      _beginTicker();
    }
  }

  void _beginTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final updated = _timerService.tick(_activeChallenge.timer);
      if (updated.remainingSeconds != _activeChallenge.timer.remainingSeconds || updated.running != _activeChallenge.timer.running) {
        _updateActiveChallenge((challenge) => challenge.copyWith(timer: updated));
        _persist();
      }
      if (!updated.running) {
        _ticker?.cancel();
        _completeEmergencySession();
      }
    });
  }

  void _ensureActiveEmergencySession() {
    if (_activeChallenge.activeEmergencySessionId != null) return;
    final template = _activeTemplate;
    final sortedSteps = [...template.steps]..sort((a, b) => a.order.compareTo(b.order));
    final stepMap = {for (final step in sortedSteps) step.id: false};
    final session = EmergencySession(
      id: const Uuid().v4(),
      startedAt: DateTime.now(),
      steps: stepMap,
      templateId: template.id,
    );
    final sessions = [..._activeChallenge.emergencySessions, session];
    final trimmed = sessions.length > 20 ? sessions.sublist(sessions.length - 20) : sessions;
    _updateActiveChallenge((challenge) => challenge.copyWith(
          emergencySessions: trimmed,
          activeEmergencySessionId: session.id,
        ));
  }

  void _completeEmergencySession() {
    if (_activeChallenge.activeEmergencySessionId == null) return;
    _updateActiveSession((session) => session.copyWith(
          completedAt: DateTime.now(),
          durationSeconds: AppConstants.timerDurationMinutes * 60,
        ));
    _updateActiveChallenge((challenge) => challenge.copyWith(activeEmergencySessionId: null));
    _persist();
    if (state.soundEnabled) SoundPlayer.instance.playTimerDone();
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
    final log = TriggerLog(dateKey: isoDate(DateTime.now()), trigger: trigger, note: note, sessionId: _activeChallenge.activeEmergencySessionId);
    final updated = [..._activeChallenge.triggerLogs, log];
    _updateActiveChallenge((challenge) => challenge.copyWith(triggerLogs: updated));
    _persist();
  }

  void _updateActiveSession(EmergencySession Function(EmergencySession) transform) {
    final id = _activeChallenge.activeEmergencySessionId;
    if (id == null) return;
    final sessions = [..._activeChallenge.emergencySessions];
    final idx = sessions.indexWhere((s) => s.id == id);
    if (idx == -1) return;
    sessions[idx] = transform(sessions[idx]);
    _updateActiveChallenge((challenge) => challenge.copyWith(emergencySessions: sessions));
  }

  void _updateActiveChallenge(Challenge Function(Challenge) transform) {
    final updated = transform(_activeChallenge);
    final list = state.challenges.map((c) => c.id == _activeChallenge.id ? updated : c).toList();
    state = state.copyWith(challenges: list, activeChallengeId: updated.id);
    _persist();
  }
}
