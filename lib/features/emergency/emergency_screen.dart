import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/app_localizations.dart';
import '../../core/theme/design_tokens.dart';
import '../../state/app_controller.dart';
import '../../data/models/emergency_session.dart';
import '../../data/models/protocol.dart';
import '../../data/models/protocol_step.dart';
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

    final template = state.templates
        .firstWhere((tpl) => tpl.id == state.activeChallenge.defaultProtocolTemplateId, orElse: () => state.templates.first);
    final session = state.emergencySessions.cast<EmergencySession?>().lastWhere(
          (s) => s?.id == state.activeEmergencySessionId,
          orElse: () => null,
        );
    final steps = [...template.steps]..sort((a, b) => a.order.compareTo(b.order));
    final completed = session?.steps ?? {};
    final lang = state.lang;

    final completedCount = completed.values.where((v) => v).length;
    final progress = steps.isEmpty ? 0.0 : completedCount / steps.length;

    return Scaffold(
      appBar: AppBar(title: Text(t.emergencyModeTitle)),
      body: Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: template.nameFor(lang), subtitle: template.descriptionFor(lang)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${t.emergency}: Step ${completedCount + 1}/${steps.length}',
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: progress.clamp(0, 1),
                              minHeight: 10,
                              borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('$minutes:$seconds',
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              SecondaryButton(
                                label: timer.running ? t.timerPause : t.timerStart,
                                icon: timer.running ? Icons.pause_circle : Icons.play_arrow,
                                onPressed: timer.running
                                    ? ref.read(appControllerProvider.notifier).pauseEmergencyTimer
                                    : ref.read(appControllerProvider.notifier).startEmergencyTimer,
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.replay),
                                tooltip: t.timerReset,
                                onPressed: () => ref.read(appControllerProvider.notifier).resetEmergencyTimer(),
                              )
                            ],
                          )
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  final step = steps[index];
                  final done = completed[step.id] ?? false;
                  return _EmergencyStepTile(
                    step: step,
                    lang: lang,
                    done: done,
                    index: index,
                    total: steps.length,
                    onToggle: () => ref.read(appControllerProvider.notifier).updateSessionStep(step.id, !done),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: t.imOutside,
                    icon: Icons.check_circle,
                    onPressed: () {
                      ref.read(appControllerProvider.notifier).markOutside();
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(t.imOutside), behavior: SnackBarBehavior.floating));
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SecondaryButton(
                  label: t.sessionHistory,
                  icon: Icons.history,
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    showDragHandle: true,
                    isScrollControlled: true,
                    builder: (_) => _HistorySheet(lang: lang),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _EmergencyStepTile extends StatelessWidget {
  const _EmergencyStepTile({
    required this.step,
    required this.lang,
    required this.done,
    required this.index,
    required this.total,
    required this.onToggle,
  });

  final ProtocolStep step;
  final String lang;
  final bool done;
  final int index;
  final int total;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isCritical = step.critical;
    final color = isCritical ? Colors.redAccent.withOpacity(0.15) : Colors.white10;
    return GestureDetector(
      onLongPress: onToggle,
      child: AnimatedContainer(
        duration: DesignTokens.medium,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: done ? Colors.green.withOpacity(0.2) : color,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
          border: Border.all(color: isCritical ? Colors.redAccent : Colors.white24, width: isCritical ? 2 : 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: done ? Colors.greenAccent : Colors.white12,
              child: Icon(done ? Icons.check : Icons.circle_outlined, color: done ? Colors.black : Colors.white70),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('${AppLocalizations.of(context).stepLabel} ${index + 1} / $total',
                          style: Theme.of(context).textTheme.labelMedium),
                      if (isCritical)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Chip(
                            label: Text(AppLocalizations.of(context).criticalLabel),
                            backgroundColor: Colors.redAccent.withOpacity(0.2),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(step.titleFor(lang),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontSize: 20, fontWeight: FontWeight.bold)),
                  if (step.detailsFor(lang) != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(step.detailsFor(lang)!, style: Theme.of(context).textTheme.bodySmall),
                    ),
                  if (step.type == ProtocolStepType.timer && step.durationSec != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text('${(step.durationSec! / 60).round()} min',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.orangeAccent)),
                    ),
                  if (step.type == ProtocolStepType.breathing && step.durationSec != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text('${step.durationSec} sec • breathing',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.lightBlueAccent)),
                    ),
                ],
              ),
            ),
            IconButton(onPressed: onToggle, icon: Icon(done ? Icons.check_box : Icons.check_box_outline_blank))
          ],
        ),
      ),
    );
  }
}

class _HistorySheet extends ConsumerWidget {
  const _HistorySheet({required this.lang});
  final String lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);
    final sessions = state.emergencySessions.reversed.take(10).toList();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SectionHeader(title: t.sessionHistory),
          const SizedBox(height: 8),
          if (sessions.isEmpty) Text(t.emptySessions) else ...sessions.map((s) => _SessionTile(session: s, lang: lang)),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _SessionTile extends ConsumerWidget {
  const _SessionTile({required this.session, required this.lang});
  final EmergencySession session;
  final String lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final template = ref
        .read(appControllerProvider)
        .templates
        .firstWhere((tpl) => tpl.id == session.templateId, orElse: () => ref.read(appControllerProvider).templates.first);
    return ListTile(
      leading: const Icon(Icons.history, color: Colors.tealAccent),
      title: Text(template.nameFor(lang)),
      subtitle: Text('${t.stepsCompleted}: ${session.steps.values.where((e) => e).length}/${session.steps.length}'),
      trailing: Text('${(session.durationSeconds / 60).round()} ${t.minutes}'),
      dense: true,
    );
  }
}
