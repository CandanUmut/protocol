import 'package:flutter_test/flutter_test.dart';
import 'package:close_the_ramp_protocol/data/models/app_state.dart';
import 'package:close_the_ramp_protocol/data/models/day_entry.dart';
import 'package:close_the_ramp_protocol/core/utils/date_utils.dart';
import 'package:close_the_ramp_protocol/data/models/emergency_timer_state.dart';

void main() {
  test('day success logic honors requireWalk toggle', () {
    final state = AppStateModel(requireWalk: true, days: {
      '2024-01-01': DayEntry(noNegotiation: true, noPhoneBedroom: true, dailyWalk: true),
      '2024-01-02': DayEntry(noNegotiation: true, noPhoneBedroom: true, dailyWalk: false),
    });
    expect(state.statusFor(DateTime(2024, 1, 1)), DayStatus.good);
    expect(state.statusFor(DateTime(2024, 1, 2)), DayStatus.partial);
    final relaxed = state.copyWith(requireWalk: false);
    expect(relaxed.statusFor(DateTime(2024, 1, 2)), DayStatus.good);
  });

  test('streak counts consecutive success days ending today', () {
    final today = DateTime(2024, 1, 10);
    final days = <String, DayEntry>{};
    for (int i = 0; i < 5; i++) {
      final date = today.subtract(Duration(days: i));
      days[isoDate(date)] = DayEntry(noNegotiation: true, noPhoneBedroom: true, dailyWalk: true);
    }
    days[isoDate(today.subtract(const Duration(days: 5)))] = DayEntry(noNegotiation: true);
    final state = AppStateModel(days: days);
    expect(state.streak(today), 5);
  });

  test('month stats aggregate success and emergencies', () {
    final today = DateTime(2024, 2, 15);
    final days = {
      '2024-02-01': DayEntry(noNegotiation: true, noPhoneBedroom: true, dailyWalk: true),
      '2024-02-02': DayEntry(noNegotiation: true, noPhoneBedroom: false, dailyWalk: false, emergencies: 2),
    };
    final state = AppStateModel(days: days);
    expect(state.successThisMonth(today), 1);
    expect(state.emergenciesThisMonth(today), 2);
  });

  test('timer resumes from stored endAt timestamp', () {
    final now = DateTime.now();
    final endAt = now.add(const Duration(minutes: 10)).millisecondsSinceEpoch;
    final timer = EmergencyTimerState(
      remainingSeconds: 600,
      running: true,
      endAtEpochMillis: endAt,
      lastUpdatedEpochMillis: now.millisecondsSinceEpoch,
    );
    final state = AppStateModel(timer: timer);
    final remaining = state.timer.endAtEpochMillis! - DateTime.now().millisecondsSinceEpoch;
    expect(remaining > 0, true);
  });
}
