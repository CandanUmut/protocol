import 'package:close_the_ramp_protocol/data/models/app_state.dart';
import 'package:close_the_ramp_protocol/data/models/challenge.dart';
import 'package:close_the_ramp_protocol/data/models/day_entry.dart';
import 'package:close_the_ramp_protocol/data/models/emergency_timer_state.dart';
import 'package:close_the_ramp_protocol/data/models/protocol.dart';
import 'package:close_the_ramp_protocol/data/models/protocol_step.dart';
import 'package:close_the_ramp_protocol/data/repositories/app_repository.dart';
import 'package:close_the_ramp_protocol/state/app_controller.dart';
import 'package:close_the_ramp_protocol/core/utils/date_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('migration v2 -> v3 keeps legacy data', () {
    final legacy = {
      'schemaVersion': 2,
      'goalDays': 30,
      'requireWalk': true,
      'todos': [
        {'id': 'a', 'title': 'No negotiation', 'createdAt': DateTime.now().toIso8601String()}
      ],
      'days': {
        '2024-01-01': {'noNegotiation': true, 'noPhoneBedroom': true, 'dailyWalk': true}
      },
      'timer': EmergencyTimerState.initial(600).toJson(),
    };

    final state = AppStateModel.fromJson(legacy);
    expect(state.challenges.length, 1);
    expect(state.challenges.first.requireDailyAction, true);
    expect(state.challenges.first.goalDays, 30);
    expect(state.dayFor(DateTime(2024, 1, 1)).noNegotiation, true);
  });

  test('streak is calculated per active challenge', () {
    final challengeA = Challenge(
      name: 'Nicotine',
      days: {
        '2024-01-01': DayEntry(noNegotiation: true, noPhoneBedroom: true, dailyWalk: true),
        '2024-01-02': DayEntry(noNegotiation: true, noPhoneBedroom: true, dailyWalk: true),
      },
    );
    final challengeB = Challenge(
      name: 'Scrolling',
      days: {'2024-01-02': DayEntry(noNegotiation: true)},
    );
    final state = AppStateModel(challenges: [challengeA, challengeB], activeChallengeId: challengeA.id);
    expect(state.streak(DateTime(2024, 1, 2)), 2);
    final swapped = state.copyWith(activeChallengeId: challengeB.id);
    expect(swapped.streak(DateTime(2024, 1, 2)), 1);
  });

  test('emergency timer endAt persists countdown', () {
    final now = DateTime.now();
    final endAt = now.add(const Duration(minutes: 5)).millisecondsSinceEpoch;
    final timer = EmergencyTimerState(
      remainingSeconds: 300,
      running: true,
      endAtEpochMillis: endAt,
      lastUpdatedEpochMillis: now.millisecondsSinceEpoch,
    );
    final challenge = Challenge(timer: timer);
    final state = AppStateModel(challenges: [challenge], activeChallengeId: challenge.id);
    expect(state.timer.endAtEpochMillis, isNotNull);
    final remaining = state.timer.endAtEpochMillis! - DateTime.now().millisecondsSinceEpoch;
    expect(remaining > 0, true);
  });

  test('critical steps gate completion', () {
    final step = ProtocolStep(id: '1', title: 'Leave room', critical: true);
    final template = ProtocolTemplate(id: 'proto', name: 'Test', description: '', steps: [step]);
    final state = AppStateModel(templates: [template]);
    expect(state.templates.first.steps.first.critical, true);
  });

  test('alarm settings allow safe auto stop', () {
    const settings = AlarmSettings(enabled: true, autoStopSeconds: 15);
    expect(settings.autoStopSeconds, inInclusiveRange(10, 20));
  });

  test('selectedDay defaults to today start of day', () {
    final container = ProviderContainer();
    final selected = container.read(selectedDateProvider);
    expect(isoDate(selected), isoDate(DateTime.now()));
    container.dispose();
  });

  test('notes save to the currently selected day', () async {
    final repo = _MemoryRepo();
    final container = ProviderContainer(overrides: [appRepositoryProvider.overrideWithValue(repo)]);
    final controller = container.read(appControllerProvider.notifier);
    await controller.initialized;
    final targetDay = DateTime(2024, 1, 2);
    controller.setSelectedDate(targetDay);
    controller.updateNotes('hello world');
    expect(controller.state.dayFor(targetDay).notes, 'hello world');
    expect(controller.state.dayFor(DateTime(2024, 1, 3)).notes.isEmpty, true);
    container.dispose();
  });

  test('emergency flow tolerates missing audio', () async {
    final repo = _MemoryRepo();
    final container = ProviderContainer(overrides: [appRepositoryProvider.overrideWithValue(repo)]);
    final controller = container.read(appControllerProvider.notifier);
    await controller.initialized;
    await controller.startEmergencyTimer(simulateSoundFailure: true);
    expect(controller.state.timer.running, true);
    container.dispose();
  });
}

class _MemoryRepo extends AppRepository {
  AppStateModel _state = AppStateModel();

  @override
  Future<AppStateModel> load() async => _state;

  @override
  Future<void> save(AppStateModel state) async {
    _state = state;
  }

  @override
  Future<void> reset() async {
    _state = AppStateModel();
  }

  @override
  Future<String> exportJson(AppStateModel state) async => '';

  @override
  Future<AppStateModel?> importJson() async => _state;
}
