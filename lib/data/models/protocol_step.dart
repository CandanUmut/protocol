import 'package:collection/collection.dart';

enum ProtocolStepType { checkbox, timer, breathing, action }

class ProtocolStep {
  ProtocolStep({
    required this.id,
    this.title,
    this.titleTr,
    this.titleEn,
    this.details,
    this.detailsTr,
    this.detailsEn,
    this.type = ProtocolStepType.checkbox,
    this.durationSec,
    this.critical = false,
    this.order = 0,
  });

  final String id;
  final String? title;
  final String? titleTr;
  final String? titleEn;
  final String? details;
  final String? detailsTr;
  final String? detailsEn;
  final ProtocolStepType type;
  final int? durationSec;
  final bool critical;
  final int order;

  ProtocolStep copyWith({
    String? id,
    String? title,
    String? titleTr,
    String? titleEn,
    String? details,
    String? detailsTr,
    String? detailsEn,
    ProtocolStepType? type,
    int? durationSec,
    bool? critical,
    int? order,
  }) {
    return ProtocolStep(
      id: id ?? this.id,
      title: title ?? this.title,
      titleTr: titleTr ?? this.titleTr,
      titleEn: titleEn ?? this.titleEn,
      details: details ?? this.details,
      detailsTr: detailsTr ?? this.detailsTr,
      detailsEn: detailsEn ?? this.detailsEn,
      type: type ?? this.type,
      durationSec: durationSec ?? this.durationSec,
      critical: critical ?? this.critical,
      order: order ?? this.order,
    );
  }

  factory ProtocolStep.fromJson(Map<String, dynamic> json) {
    return ProtocolStep(
      id: json['id'] as String,
      title: json['title'] as String?,
      titleTr: json['titleTr'] as String?,
      titleEn: json['titleEn'] as String?,
      details: json['details'] as String?,
      detailsTr: json['detailsTr'] as String?,
      detailsEn: json['detailsEn'] as String?,
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
        'titleTr': titleTr,
        'titleEn': titleEn,
        'details': details,
        'detailsTr': detailsTr,
        'detailsEn': detailsEn,
        'type': type.name,
        'durationSec': durationSec,
        'critical': critical,
        'order': order,
      };

  String titleFor(String lang) {
    if (lang == 'tr') return titleTr ?? title ?? titleEn ?? '';
    return titleEn ?? title ?? titleTr ?? '';
  }

  String? detailsFor(String lang) {
    if (lang == 'tr') return detailsTr ?? details ?? detailsEn;
    return detailsEn ?? details ?? detailsTr;
  }
}
