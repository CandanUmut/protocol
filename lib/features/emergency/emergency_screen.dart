import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/app_localizations.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/date_utils.dart';
import '../../state/app_controller.dart';
import '../../data/models/emergency_session.dart';
import '../../widgets/buttons.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/section_header.dart';

class EmergencyScreen extends ConsumerWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final t = AppLocalizations.of(context);
    final timer = state.timer;
    final minutes = (timer.remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (timer.remainingSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(title: Text(t.emergencyModeTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: t.emergencySteps),
                const SizedBox(height: 12),
                Text(t.emergencyMicrocopy, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),
                _StepChecklist(),
                const SizedBox(height: 12),
                Center(
                  child: AnimatedContainer(
                    duration: DesignTokens.medium,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
                      color: Colors.black.withOpacity(0.2),
                    ),
                    child: Column(
                      children: [
                        Text('$minutes:$seconds', style: Theme.of(context).textTheme.displaySmall),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                label: timer.running ? t.timerPause : t.timerStart,
                                icon: timer.running ? Icons.pause : Icons.play_arrow,
                                onPressed: timer.running
                                    ? ref.read(appControllerProvider.notifier).pauseEmergencyTimer
                                    : ref.read(appControllerProvider.notifier).startEmergencyTimer,
                              ),
                            ),
                            const SizedBox(width: 12),
                            SecondaryButton(
                              label: t.timerReset,
                              icon: Icons.replay,
                              onPressed: () => ref.read(appControllerProvider.notifier).resetEmergencyTimer(),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: t.imOutside,
                  icon: Icons.check_circle,
                  onPressed: () {
                    ref.read(appControllerProvider.notifier).markOutside();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.imOutside)));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: t.sessionHistory),
                const SizedBox(height: 8),
                if (state.emergencySessions.isEmpty)
                  Text(t.emptySessions)
                else
                  ...state.emergencySessions.reversed.take(10).map((s) => _SessionTile(session: s)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.shield),
        onPressed: ref.read(appControllerProvider.notifier).startEmergencyTimer,
        label: Text(t.emergency),
      ),
    );
  }
}

class _StepChecklist extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);
    final session = state.emergencySessions.cast<EmergencySession?>().lastWhere(
          (s) => s?.id == state.activeEmergencySessionId,
          orElse: () => null,
        );
    final steps = session?.steps ?? {
      'step_out': false,
      'start_timer': false,
      'call_friend': false,
      'short_walk': false,
      'breath': false,
    };

    return Column(
      children: steps.entries
          .map(
            (e) => CheckboxListTile(
              value: e.value,
              onChanged: (v) => ref.read(appControllerProvider.notifier).updateSessionStep(e.key, v ?? false),
              title: Text(_labelFor(e.key, t)),
            ),
          )
          .toList(),
    );
  }

  String _labelFor(String key, AppLocalizations t) {
    switch (key) {
      case 'step_out':
        return t.stepOutside;
      case 'start_timer':
        return t.stepStartTimer;
      case 'call_friend':
        return t.stepCallFriend;
      case 'short_walk':
        return t.stepWalk;
      case 'breath':
        return t.stepBreath;
      default:
        return key;
    }
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});
  final EmergencySession session;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final date = DateTime.tryParse(session.startedAt.toIso8601String()) ?? DateTime.now();
    return ListTile(
      leading: const Icon(Icons.history, color: Colors.tealAccent),
      title: Text(isoDate(date)),
      subtitle: Text('${t.stepsCompleted}: ${session.steps.values.where((e) => e).length}/5'),
      trailing: Text('${(session.durationSeconds / 60).round()} ${t.minutes}'),
    );
  }
}
