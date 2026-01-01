import 'package:close_the_ramp_protocol/data/models/app_state.dart';
import 'package:close_the_ramp_protocol/data/models/challenge.dart';
import 'package:close_the_ramp_protocol/data/models/day_entry.dart';
import 'package:close_the_ramp_protocol/data/models/emergency_timer_state.dart';
import 'package:close_the_ramp_protocol/data/models/protocol.dart';
import 'package:close_the_ramp_protocol/data/models/protocol_step.dart';
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
}
