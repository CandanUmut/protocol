class EmergencyTimerState {
  const EmergencyTimerState({
    required this.remainingSeconds,
    required this.running,
    required this.endAtEpochMillis,
    required this.lastUpdatedEpochMillis,
  });

  final int remainingSeconds;
  final bool running;
  final int? endAtEpochMillis;
  final int lastUpdatedEpochMillis;

  factory EmergencyTimerState.initial(int totalSeconds) => EmergencyTimerState(
        remainingSeconds: totalSeconds,
        running: false,
        endAtEpochMillis: null,
        lastUpdatedEpochMillis: DateTime.now().millisecondsSinceEpoch,
      );

  EmergencyTimerState copyWith({
    int? remainingSeconds,
    bool? running,
    int? endAtEpochMillis,
    int? lastUpdatedEpochMillis,
  }) {
    return EmergencyTimerState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      running: running ?? this.running,
      endAtEpochMillis: endAtEpochMillis ?? this.endAtEpochMillis,
      lastUpdatedEpochMillis: lastUpdatedEpochMillis ?? this.lastUpdatedEpochMillis,
    );
  }

  Map<String, dynamic> toJson() => {
        'remainingSeconds': remainingSeconds,
        'running': running,
        'endAtEpochMillis': endAtEpochMillis,
        'lastUpdatedEpochMillis': lastUpdatedEpochMillis,
      };

  factory EmergencyTimerState.fromJson(Map<String, dynamic> json) => EmergencyTimerState(
        remainingSeconds: json['remainingSeconds'] as int? ?? 0,
        running: json['running'] as bool? ?? false,
        endAtEpochMillis: json['endAtEpochMillis'] as int?,
        lastUpdatedEpochMillis: json['lastUpdatedEpochMillis'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      );
}
