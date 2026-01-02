class EmergencyDiagnostic {
  EmergencyDiagnostic({
    required this.timestamp,
    required this.action,
    required this.audioAttempted,
    required this.audioSuccess,
    this.error,
  });

  final DateTime timestamp;
  final String action;
  final bool audioAttempted;
  final bool audioSuccess;
  final String? error;
}
