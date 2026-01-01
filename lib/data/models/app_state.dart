import '../../core/constants/app_constants.dart';
import '../../data/models/day_entry.dart';
import '../../data/models/emergency_session.dart';
import '../../data/models/emergency_timer_state.dart';
import '../../data/models/todo_item.dart';
import '../../data/models/trigger_log.dart';
import '../models/challenge.dart';
import '../models/protocol.dart';
import '../models/protocol_step.dart';

class AppStateModel {
  AppStateModel({
    this.schemaVersion = AppConstants.schemaVersion,
    this.lang = 'tr',
    this.soundEnabled = false,
    this.hapticsEnabled = true,
    this.notificationsEnabled = true,
    List<Challenge>? challenges,
    String? activeChallengeId,
    List<ProtocolTemplate>? templates,
    AlarmSettings? alarmSettings,
  })  : challenges = challenges ?? [defaultChallenge()],
        templates = templates ?? defaultTemplates(),
        activeChallengeId = activeChallengeId ?? (challenges ?? [defaultChallenge()]).first.id,
        alarmSettings = alarmSettings ?? const AlarmSettings();

  final int schemaVersion;
  final String lang;
  final bool soundEnabled;
  final bool hapticsEnabled;
  final bool notificationsEnabled;
  final List<Challenge> challenges;
  final String activeChallengeId;
  final List<ProtocolTemplate> templates;
  final AlarmSettings alarmSettings;

  Challenge get activeChallenge =>
      challenges.firstWhere((c) => c.id == activeChallengeId, orElse: () => challenges.first);

  int get goalDays => activeChallenge.goalDays;
  bool get requireWalk => activeChallenge.requireDailyAction;
  int get riskWindowStartHour => activeChallenge.riskWindowStartHour;
  int get riskWindowEndHour => activeChallenge.riskWindowEndHour;
  String get ifThenPlan => activeChallenge.ifThenPlan;
  List<TodoItem> get todos => activeChallenge.todos;
  Map<String, DayEntry> get days => activeChallenge.days;
  EmergencyTimerState get timer => activeChallenge.timer;
  List<EmergencySession> get emergencySessions => activeChallenge.emergencySessions;
  List<TriggerLog> get triggerLogs => activeChallenge.triggerLogs;
  String? get activeEmergencySessionId => activeChallenge.activeEmergencySessionId;

  DayEntry dayFor(DateTime date) => activeChallenge.dayFor(date);

  int streak(DateTime today) => activeChallenge.streak(today);

  int successThisMonth(DateTime today) => activeChallenge.successThisMonth(today);

  int emergenciesThisMonth(DateTime today) => activeChallenge.emergenciesThisMonth(today);

  DayStatus statusFor(DateTime date) {
    final entry = dayFor(date);
    if (entry.isSuccess(requireWalk: requireWalk)) return DayStatus.good;
    if (entry.isPartial(requireWalk: requireWalk)) return DayStatus.partial;
    return DayStatus.empty;
  }

  int protectionScore(DateTime date) {
    final entry = dayFor(date);
    int score = 0;
    if (entry.noNegotiation) score++;
    if (entry.noPhoneBedroom) score++;
    if (entry.dailyWalk || !requireWalk) score++;
    if (entry.emergencies > 0) score++;
    return (score / 4 * 100).round();
  }

  bool get inNightRiskWindow {
    final now = DateTime.now();
    final start = riskWindowStartHour;
    final end = riskWindowEndHour;
    if (start < end) {
      return now.hour >= start && now.hour < end;
    } else {
      return now.hour >= start || now.hour < end;
    }
  }

  AppStateModel copyWith({
    int? schemaVersion,
    String? lang,
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? notificationsEnabled,
    List<Challenge>? challenges,
    String? activeChallengeId,
    List<ProtocolTemplate>? templates,
    AlarmSettings? alarmSettings,
  }) {
    final resolvedChallenges = challenges ?? this.challenges;
    return AppStateModel(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      lang: lang ?? this.lang,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      challenges: resolvedChallenges,
      activeChallengeId: activeChallengeId ?? this.activeChallengeId,
      templates: templates ?? this.templates,
      alarmSettings: alarmSettings ?? this.alarmSettings,
    );
  }

  factory AppStateModel.fromJson(Map<String, dynamic> json) {
    final version = json['schemaVersion'] as int? ?? 1;
    if (version < 3) {
      return _migrateV2ToV3(json);
    }
    final challengeList = (json['challenges'] as List? ?? [])
        .map((e) => Challenge.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final templates = (json['templates'] as List? ?? [])
        .map((e) => ProtocolTemplate.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return AppStateModel(
      schemaVersion: json['schemaVersion'] as int? ?? AppConstants.schemaVersion,
      lang: json['lang'] as String? ?? 'tr',
      soundEnabled: json['soundEnabled'] as bool? ?? false,
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      challenges: challengeList.isEmpty ? [defaultChallenge()] : challengeList,
      activeChallengeId: json['activeChallengeId'] as String? ?? challengeList.first.id,
      templates: templates.isEmpty ? defaultTemplates() : templates,
      alarmSettings: json['alarmSettings'] != null
          ? AlarmSettings.fromJson(Map<String, dynamic>.from(json['alarmSettings'] as Map))
          : const AlarmSettings(),
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'lang': lang,
        'soundEnabled': soundEnabled,
        'hapticsEnabled': hapticsEnabled,
        'notificationsEnabled': notificationsEnabled,
        'challenges': challenges.map((e) => e.toJson()).toList(),
        'activeChallengeId': activeChallengeId,
        'templates': templates.map((e) => e.toJson()).toList(),
        'alarmSettings': alarmSettings.toJson(),
      };

  static Challenge defaultChallenge() => Challenge();

  static List<ProtocolTemplate> defaultTemplates() => [
        ProtocolTemplate(
          id: 'evacuation',
          name: 'Evacuation Protocol (Outdoor Reset)',
          description: 'Get outside and reset quickly.',
          steps: [
            ProtocolStep(id: 'step1', title: 'Exit the building now', type: ProtocolStepType.action, critical: true, order: 0),
            ProtocolStep(id: 'step2', title: 'Walk for 5 minutes', type: ProtocolStepType.timer, durationSec: 300, order: 1),
            ProtocolStep(id: 'step3', title: 'Text a safe friend', type: ProtocolStepType.checkbox, order: 2),
          ],
        ),
        ProtocolTemplate(
          id: 'urge_surfing',
          name: 'Urge Surfing Protocol (90 seconds)',
          description: 'Ride out the urge without acting.',
          steps: [
            ProtocolStep(id: 'step1', title: 'Notice and name the urge', type: ProtocolStepType.checkbox, critical: true, order: 0),
            ProtocolStep(id: 'step2', title: '90 second timer', type: ProtocolStepType.timer, durationSec: 90, order: 1),
            ProtocolStep(id: 'step3', title: 'Slow breaths', type: ProtocolStepType.breathing, durationSec: 60, order: 2),
          ],
        ),
        ProtocolTemplate(
          id: 'digital_lockdown',
          name: 'Digital Lockdown Protocol (WiFi off + Lockbox)',
          description: 'Cut access and move away.',
          steps: [
            ProtocolStep(id: 'step1', title: 'Turn off WiFi + data', type: ProtocolStepType.action, critical: true, order: 0),
            ProtocolStep(id: 'step2', title: 'Place device in lockbox', type: ProtocolStepType.action, order: 1),
            ProtocolStep(id: 'step3', title: 'Timer: 15 minutes', type: ProtocolStepType.timer, durationSec: 900, order: 2),
          ],
        ),
        ProtocolTemplate(
          id: 'spiritual_reset',
          name: 'Spiritual Reset',
          description: 'Center yourself with water + calm breath.',
          steps: [
            ProtocolStep(id: 'step1', title: 'Wash hands / face', type: ProtocolStepType.action, critical: true, order: 0),
            ProtocolStep(id: 'step2', title: 'Breathe slowly (2 min)', type: ProtocolStepType.breathing, durationSec: 120, order: 1),
            ProtocolStep(id: 'step3', title: 'Grateful thought', type: ProtocolStepType.checkbox, order: 2),
          ],
        ),
      ];

  static AppStateModel _migrateV2ToV3(Map<String, dynamic> json) {
    final legacy = AppStateModel(
      lang: json['lang'] as String? ?? 'tr',
      soundEnabled: json['soundEnabled'] as bool? ?? false,
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
    );
    final challenge = Challenge(
      name: 'Protocol',
      goalDays: json['goalDays'] as int? ?? AppConstants.defaultGoalDays,
      requireDailyAction: json['requireWalk'] as bool? ?? AppConstants.defaultRequireWalk,
      riskWindowStartHour: json['riskWindowStartHour'] as int? ?? AppConstants.defaultRiskStart,
      riskWindowEndHour: json['riskWindowEndHour'] as int? ?? AppConstants.defaultRiskEnd,
      ifThenPlan: json['ifThenPlan'] as String? ?? 'IF I feel negotiation THEN I evacuate.',
      todos: (json['todos'] as List? ?? [])
          .map((e) => TodoItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      days: (json['days'] as Map? ?? {})
          .map((key, value) => MapEntry(key as String, DayEntry.fromJson(Map<String, dynamic>.from(value as Map)))),
      emergencySessions: (json['emergencySessions'] as List? ?? [])
          .map((e) => EmergencySession.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      triggerLogs: (json['triggerLogs'] as List? ?? [])
          .map((e) => TriggerLog.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      timer: json['timer'] != null
          ? EmergencyTimerState.fromJson(Map<String, dynamic>.from(json['timer'] as Map))
          : EmergencyTimerState.initial(AppConstants.timerDurationMinutes * 60),
      activeEmergencySessionId: json['activeEmergencySessionId'] as String?,
    );
    return AppStateModel(
      schemaVersion: AppConstants.schemaVersion,
      lang: legacy.lang,
      soundEnabled: legacy.soundEnabled,
      hapticsEnabled: legacy.hapticsEnabled,
      notificationsEnabled: legacy.notificationsEnabled,
      challenges: [challenge],
      activeChallengeId: challenge.id,
      templates: defaultTemplates(),
    );
  }
}
