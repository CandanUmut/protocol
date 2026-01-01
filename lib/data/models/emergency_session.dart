import '../../core/utils/date_utils.dart';

class EmergencySession {
  EmergencySession({
    required this.id,
    required this.startedAt,
    this.completedAt,
    Map<String, bool>? steps,
    this.outsideConfirmed = false,
    this.durationSeconds = 0,
    this.trigger,
    this.note,
    this.templateId,
  }) : steps = steps ?? _defaultSteps();

  final String id;
  final DateTime startedAt;
  final DateTime? completedAt;
  final Map<String, bool> steps;
  final bool outsideConfirmed;
  final int durationSeconds;
  final String? trigger;
  final String? note;
  final String? templateId;

  EmergencySession copyWith({
    DateTime? completedAt,
    Map<String, bool>? steps,
    bool? outsideConfirmed,
    int? durationSeconds,
    String? trigger,
    String? note,
    String? templateId,
  }) {
    return EmergencySession(
      id: id,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
      steps: steps ?? this.steps,
      outsideConfirmed: outsideConfirmed ?? this.outsideConfirmed,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      trigger: trigger ?? this.trigger,
      note: note ?? this.note,
      templateId: templateId ?? this.templateId,
    );
  }

  factory EmergencySession.fromJson(Map<String, dynamic> json) => EmergencySession(
        id: json['id'] as String,
        startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ?? DateTime.now(),
        completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt'] as String) : null,
        steps: Map<String, bool>.from(json['steps'] as Map? ?? _defaultSteps()),
        outsideConfirmed: json['outsideConfirmed'] as bool? ?? false,
        durationSeconds: json['durationSeconds'] as int? ?? 0,
        trigger: json['trigger'] as String?,
        note: json['note'] as String?,
        templateId: json['templateId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'steps': steps,
        'outsideConfirmed': outsideConfirmed,
        'durationSeconds': durationSeconds,
        'trigger': trigger,
        'note': note,
        'templateId': templateId,
      };

  static Map<String, bool> _defaultSteps() => {
        'step_out': false,
        'start_timer': false,
        'call_friend': false,
        'short_walk': false,
        'breath': false,
      };

  String get dayKey => isoDate(startedAt);
}
