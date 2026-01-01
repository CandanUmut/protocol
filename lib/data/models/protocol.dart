import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

import 'protocol_step.dart';

enum AlarmIntensity { soft, strong, extreme }

class AlarmSettings {
  const AlarmSettings({
    this.enabled = true,
    this.intensity = AlarmIntensity.soft,
    this.volume = 0.6,
    this.autoStopSeconds = 15,
  });

  final bool enabled;
  final AlarmIntensity intensity;
  final double volume;
  final int autoStopSeconds;

  AlarmSettings copyWith({bool? enabled, AlarmIntensity? intensity, double? volume, int? autoStopSeconds}) {
    return AlarmSettings(
      enabled: enabled ?? this.enabled,
      intensity: intensity ?? this.intensity,
      volume: volume ?? this.volume,
      autoStopSeconds: autoStopSeconds ?? this.autoStopSeconds,
    );
  }

  factory AlarmSettings.fromJson(Map<String, dynamic> json) {
    return AlarmSettings(
      enabled: json['enabled'] as bool? ?? true,
      intensity: AlarmIntensity.values.firstWhereOrNull(
            (e) => e.name == (json['intensity'] as String?),
          ) ??
          AlarmIntensity.soft,
      volume: (json['volume'] as num?)?.toDouble() ?? 0.6,
      autoStopSeconds: json['autoStopSeconds'] as int? ?? 15,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'intensity': intensity.name,
        'volume': volume,
        'autoStopSeconds': autoStopSeconds,
      };
}

class ProtocolTemplate {
  ProtocolTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.steps,
  });

  final String id;
  final String name;
  final String description;
  final List<ProtocolStep> steps;

  ProtocolTemplate copyWith({String? id, String? name, String? description, List<ProtocolStep>? steps}) {
    return ProtocolTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      steps: steps ?? this.steps,
    );
  }

  factory ProtocolTemplate.fromJson(Map<String, dynamic> json) {
    final steps = (json['steps'] as List? ?? [])
        .map((e) => ProtocolStep.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return ProtocolTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      steps: steps,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'steps': steps.map((e) => e.toJson()).toList(),
      };

  ProtocolTemplate instantiate({String? newId}) {
    final uid = const Uuid().v4();
    return copyWith(
      id: newId ?? uid,
      steps: steps
          .asMap()
          .entries
          .map((e) => e.value.copyWith(id: '${newId ?? uid}-${e.key}', order: e.key))
          .toList(),
    );
  }
}
