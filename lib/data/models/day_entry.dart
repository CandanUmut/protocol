enum DayStatus { good, partial, empty }

class DayEntry {
  DayEntry({
    this.noNegotiation = false,
    this.noPhoneBedroom = false,
    this.dailyWalk = false,
    this.emergencies = 0,
    this.notes = '',
    Map<String, bool>? todoStates,
  }) : todoStates = todoStates ?? {};

  final bool noNegotiation;
  final bool noPhoneBedroom;
  final bool dailyWalk;
  final int emergencies;
  final String notes;
  final Map<String, bool> todoStates;

  DayEntry copyWith({
    bool? noNegotiation,
    bool? noPhoneBedroom,
    bool? dailyWalk,
    int? emergencies,
    String? notes,
    Map<String, bool>? todoStates,
  }) {
    return DayEntry(
      noNegotiation: noNegotiation ?? this.noNegotiation,
      noPhoneBedroom: noPhoneBedroom ?? this.noPhoneBedroom,
      dailyWalk: dailyWalk ?? this.dailyWalk,
      emergencies: emergencies ?? this.emergencies,
      notes: notes ?? this.notes,
      todoStates: todoStates ?? this.todoStates,
    );
  }

  factory DayEntry.fromJson(Map<String, dynamic> json) => DayEntry(
        noNegotiation: json['noNegotiation'] as bool? ?? false,
        noPhoneBedroom: json['noPhoneBedroom'] as bool? ?? false,
        dailyWalk: json['dailyWalk'] as bool? ?? false,
        emergencies: json['emergencies'] as int? ?? 0,
        notes: json['notes'] as String? ?? '',
        todoStates: Map<String, bool>.from(json['todoStates'] as Map? ?? {}),
      );

  Map<String, dynamic> toJson() => {
        'noNegotiation': noNegotiation,
        'noPhoneBedroom': noPhoneBedroom,
        'dailyWalk': dailyWalk,
        'emergencies': emergencies,
        'notes': notes,
        'todoStates': todoStates,
      };

  bool isSuccess({required bool requireWalk}) {
    final requiredCount = 2 + (requireWalk ? 1 : 0);
    int score = 0;
    if (noNegotiation) score++;
    if (noPhoneBedroom) score++;
    if (!requireWalk || dailyWalk) score++;
    return score >= requiredCount;
  }

  bool isPartial({required bool requireWalk}) {
    if (isSuccess(requireWalk: requireWalk)) return false;
    return noNegotiation || noPhoneBedroom || dailyWalk || emergencies > 0;
  }
}
