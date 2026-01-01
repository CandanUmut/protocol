import 'package:collection/collection.dart';

enum ProtocolStepType { checkbox, timer, breathing, action }

class ProtocolStep {
  ProtocolStep({
    required this.id,
    required this.title,
    this.details,
    this.type = ProtocolStepType.checkbox,
    this.durationSec,
    this.critical = false,
    this.order = 0,
  });

  final String id;
  final String title;
  final String? details;
  final ProtocolStepType type;
  final int? durationSec;
  final bool critical;
  final int order;

  ProtocolStep copyWith({
    String? id,
    String? title,
    String? details,
    ProtocolStepType? type,
    int? durationSec,
    bool? critical,
    int? order,
  }) {
    return ProtocolStep(
      id: id ?? this.id,
      title: title ?? this.title,
      details: details ?? this.details,
      type: type ?? this.type,
      durationSec: durationSec ?? this.durationSec,
      critical: critical ?? this.critical,
      order: order ?? this.order,
    );
  }

  factory ProtocolStep.fromJson(Map<String, dynamic> json) {
    return ProtocolStep(
      id: json['id'] as String,
      title: json['title'] as String,
      details: json['details'] as String?,
      type: ProtocolStepType.values.firstWhereOrNull(
            (e) => e.name == (json['type'] as String?),
          ) ??
          ProtocolStepType.checkbox,
      durationSec: json['durationSec'] as int?,
      critical: json['critical'] as bool? ?? false,
      order: json['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'details': details,
        'type': type.name,
        'durationSec': durationSec,
        'critical': critical,
        'order': order,
      };
}
