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
    this.name,
    this.nameTr,
    this.nameEn,
    this.description,
    this.descriptionTr,
    this.descriptionEn,
    required this.steps,
    this.recommendedFor = const [],
  });

  final String id;
  final String? name;
  final String? nameTr;
  final String? nameEn;
  final String? description;
  final String? descriptionTr;
  final String? descriptionEn;
  final List<ProtocolStep> steps;
  final List<String> recommendedFor;

  ProtocolTemplate copyWith({
    String? id,
    String? name,
    String? nameTr,
    String? nameEn,
    String? description,
    String? descriptionTr,
    String? descriptionEn,
    List<ProtocolStep>? steps,
    List<String>? recommendedFor,
  }) {
    return ProtocolTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      nameTr: nameTr ?? this.nameTr,
      nameEn: nameEn ?? this.nameEn,
      description: description ?? this.description,
      descriptionTr: descriptionTr ?? this.descriptionTr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      steps: steps ?? this.steps,
      recommendedFor: recommendedFor ?? this.recommendedFor,
    );
  }

  factory ProtocolTemplate.fromJson(Map<String, dynamic> json) {
    final steps = (json['steps'] as List? ?? [])
        .map((e) => ProtocolStep.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return ProtocolTemplate(
      id: json['id'] as String,
      name: json['name'] as String?,
      nameTr: json['nameTr'] as String?,
      nameEn: json['nameEn'] as String?,
      description: json['description'] as String?,
      descriptionTr: json['descriptionTr'] as String?,
      descriptionEn: json['descriptionEn'] as String?,
      steps: steps,
      recommendedFor:
          (json['recommendedFor'] as List? ?? []).map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nameTr': nameTr,
        'nameEn': nameEn,
        'description': description,
        'descriptionTr': descriptionTr,
        'descriptionEn': descriptionEn,
        'steps': steps.map((e) => e.toJson()).toList(),
        'recommendedFor': recommendedFor,
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

  String nameFor(String lang) {
    if (lang == 'tr') return nameTr ?? name ?? nameEn ?? '';
    return nameEn ?? name ?? nameTr ?? '';
  }

  String descriptionFor(String lang) {
    if (lang == 'tr') return descriptionTr ?? description ?? descriptionEn ?? '';
    return descriptionEn ?? description ?? descriptionTr ?? '';
  }
}
