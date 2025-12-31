class TriggerLog {
  TriggerLog({required this.dateKey, required this.trigger, this.note, this.sessionId});

  final String dateKey;
  final String trigger;
  final String? note;
  final String? sessionId;

  TriggerLog copyWith({String? trigger, String? note, String? sessionId}) => TriggerLog(
        dateKey: dateKey,
        trigger: trigger ?? this.trigger,
        note: note ?? this.note,
        sessionId: sessionId ?? this.sessionId,
      );

  factory TriggerLog.fromJson(Map<String, dynamic> json) => TriggerLog(
        dateKey: json['dateKey'] as String,
        trigger: json['trigger'] as String? ?? 'other',
        note: json['note'] as String?,
        sessionId: json['sessionId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'trigger': trigger,
        'note': note,
        'sessionId': sessionId,
      };
}
