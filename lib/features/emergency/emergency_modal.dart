import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/app_localizations.dart';
import '../../core/utils/haptics.dart';
import '../../data/models/emergency_timer_state.dart';
import '../../state/app_controller.dart';
import '../../widgets/glass_card.dart';

class EmergencyModal extends ConsumerWidget {
  const EmergencyModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final t = AppLocalizations.of(context);
    final timer = state.timer;

    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(height: 12),
          Text(t.emergencySteps, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const _StepsList(),
          const SizedBox(height: 12),
          GlassCard(child: _TimerControls(timer: timer)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ref.read(appControllerProvider.notifier).markOutside();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t.imOutside)),
                );
              },
              icon: const Icon(Icons.check_circle),
              label: Text(t.imOutside),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepsList extends StatelessWidget {
  const _StepsList();

  @override
  Widget build(BuildContext context) {
    final steps = [
      'Step outside immediately',
      'Start timer, breathe',
      'Call a friend or sponsor',
      'Walk for 5 minutes',
      'Return only when calm',
    ];
    return Column(
      children: [
        for (final step in steps)
          ListTile(
            dense: true,
            leading: const Icon(Icons.check_circle_outline, color: Colors.tealAccent),
            title: Text(step),
          )
      ],
    );
  }
}

class _TimerControls extends ConsumerWidget {
  const _TimerControls({required this.timer});

  final EmergencyTimerState timer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final notifier = ref.read(appControllerProvider.notifier);
    final minutes = (timer.remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (timer.remainingSeconds % 60).toString().padLeft(2, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$minutes:$seconds', style: Theme.of(context).textTheme.displayMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: timer.running ? notifier.pauseEmergencyTimer : () => notifier.startEmergencyTimer(),
              icon: Icon(timer.running ? Icons.pause : Icons.play_arrow),
              label: Text(timer.running ? t.timerPause : t.timerStart),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () {
                notifier.resetEmergencyTimer();
                lightHaptic();
              },
              icon: const Icon(Icons.replay),
              label: Text(t.timerReset),
            ),
          ],
        ),
      ],
    );
  }
}
