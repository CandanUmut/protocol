import 'dart:async';

import '../../core/constants/app_constants.dart';
import '../../core/utils/haptics.dart';
import '../../data/models/emergency_timer_state.dart';
import 'notification_service.dart';

class TimerService {
  TimerService({int? totalSeconds}) : _totalSeconds = totalSeconds ?? AppConstants.timerDurationMinutes * 60;

  final int _totalSeconds;
  Timer? _timer;
  void dispose() => _timer?.cancel();

  EmergencyTimerState tick(EmergencyTimerState state) {
    if (!state.running || state.endAtEpochMillis == null) return state;
    final remaining = state.endAtEpochMillis! - DateTime.now().millisecondsSinceEpoch;
    final seconds = (remaining / 1000).ceil();
    if (seconds <= 0) {
      NotificationService.instance.cancelAll();
      return state.copyWith(
        running: false,
        remainingSeconds: 0,
        endAtEpochMillis: null,
        lastUpdatedEpochMillis: DateTime.now().millisecondsSinceEpoch,
      );
    }
    return state.copyWith(remainingSeconds: seconds, lastUpdatedEpochMillis: DateTime.now().millisecondsSinceEpoch);
  }

  EmergencyTimerState start(EmergencyTimerState state) {
    final endAt = DateTime.now().millisecondsSinceEpoch + state.remainingSeconds * 1000;
    NotificationService.instance.scheduleCompletion(
      DateTime.fromMillisecondsSinceEpoch(endAt),
      title: 'Emergency complete',
      body: '30 minutes passed — breathe and continue.',
    );
    return state.copyWith(running: true, endAtEpochMillis: endAt, lastUpdatedEpochMillis: DateTime.now().millisecondsSinceEpoch);
  }

  EmergencyTimerState pause(EmergencyTimerState state) {
    NotificationService.instance.cancelAll();
    final updated = tick(state).copyWith(running: false, endAtEpochMillis: null);
    lightHaptic();
    return updated;
  }

  EmergencyTimerState reset() {
    NotificationService.instance.cancelAll();
    return EmergencyTimerState.initial(_totalSeconds);
  }
}
