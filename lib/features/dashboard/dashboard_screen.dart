import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/i18n/app_localizations.dart';
import '../../state/app_controller.dart';
import '../../data/models/app_state.dart';
import '../../widgets/chips.dart';
import '../../widgets/glass_card.dart';
import '../emergency/emergency_modal.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appControllerProvider);
    final t = AppLocalizations.of(context);
    final today = DateTime.now();
    final status = appState.statusFor(today);
    final streak = appState.streak(today);
    final successMonth = appState.successThisMonth(today);
    final emergencyMonth = appState.emergenciesThisMonth(today);
    final todayEntry = appState.dayFor(today);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(t.appTitle, style: Theme.of(context).textTheme.headlineSmall),
            IconButton(
              onPressed: () => _toggleLanguage(ref, appState.lang),
              icon: const Icon(Icons.language),
              tooltip: t.languageToggle,
            )
          ],
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.todayStatus, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  StatusChip(
                    label: _statusLabel(status, t),
                    color: _statusColor(status),
                    icon: Icons.brightness_1,
                  ),
                  StatusChip(label: '${t.streak}: $streak', color: Colors.tealAccent, icon: Icons.local_fire_department),
                  StatusChip(label: '${t.goal}: ${appState.goalDays}', color: Colors.orangeAccent, icon: Icons.flag),
                  if (todayEntry.emergencies > 0)
                    StatusChip(
                      label: '${t.todayEmergency}: ${todayEntry.emergencies}',
                      color: Colors.amberAccent,
                      icon: Icons.warning_amber_rounded,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (appState.streak(today) / appState.goalDays).clamp(0, 1).toDouble(),
                minHeight: 10,
                borderRadius: BorderRadius.circular(12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.monthSuccess, style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 4),
                    Text('$successMonth ${t.successDay}', style: Theme.of(context).textTheme.headlineSmall),
                  ],
                ),
              ).animate().fadeIn(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.monthEmergencies, style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 4),
                    Text('$emergencyMonth', style: Theme.of(context).textTheme.headlineSmall),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Core Rules', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _ruleRow(t.rule1, todayEntry.noNegotiation),
              _ruleRow(t.rule2, todayEntry.noPhoneBedroom),
              _ruleRow(t.dailyWalk, todayEntry.dailyWalk || !appState.requireWalk, trailing: _walkToggle(ref, appState)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(t.goalDays)),
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      initialValue: appState.goalDays.toString(),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        final value = int.tryParse(v) ?? AppConstants.defaultGoalDays;
                        ref.read(appControllerProvider.notifier).setGoalDays(value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: appState.requireWalk,
                title: Text(t.requireWalk),
                onChanged: (v) => ref.read(appControllerProvider.notifier).toggleRequireWalk(v),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => ref.read(appControllerProvider.notifier).exportState(),
                    icon: const Icon(Icons.upload_file),
                    label: Text(t.exportLabel),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => ref.read(appControllerProvider.notifier).importState(),
                    icon: const Icon(Icons.download),
                    label: Text(t.importLabel),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(t.reset),
                              content: Text(t.confirmReset),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(t.cancel)),
                                ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(t.confirm)),
                              ],
                            ),
                          ) ??
                          false;
                      if (confirmed) {
                        await ref.read(appControllerProvider.notifier).reset();
                      }
                    },
                    icon: const Icon(Icons.delete_forever),
                    label: Text(t.reset),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
            backgroundColor: Colors.redAccent,
          ),
          onPressed: () {
            ref.read(appControllerProvider.notifier).setSelectedDate(today);
            ref.read(appControllerProvider.notifier).logEmergency();
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.black87,
              builder: (_) => const EmergencyModal(),
            );
          },
          icon: const Icon(Icons.warning_amber_rounded),
          label: Text('${t.emergency} — ${t.evacuate}'),
        ),
        const SizedBox(height: 8),
        if (todayEntry.emergencies > 0)
          Text(t.supportiveChip, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.greenAccent)),
        const SizedBox(height: 12),
        if (DateTime.now().hour >= 22 && !(todayEntry.noPhoneBedroom && todayEntry.noNegotiation))
          GlassCard(
            child: Row(
              children: [
                const Icon(Icons.nightlight_round, color: Colors.amberAccent),
                const SizedBox(width: 8),
                Expanded(child: Text(t.gentleReminder)),
              ],
            ),
          ),
      ],
    );
  }

  void _toggleLanguage(WidgetRef ref, String current) {
    final next = current == 'tr' ? 'en' : 'tr';
    ref.read(appControllerProvider.notifier).setLanguage(next);
  }

  String _statusLabel(DayStatus status, AppLocalizations t) {
    switch (status) {
      case DayStatus.good:
        return t.good;
      case DayStatus.partial:
        return t.partial;
      case DayStatus.empty:
      default:
        return t.empty;
    }
  }

  Color _statusColor(DayStatus status) {
    switch (status) {
      case DayStatus.good:
        return Colors.greenAccent;
      case DayStatus.partial:
        return Colors.amberAccent;
      case DayStatus.empty:
      default:
        return Colors.redAccent;
    }
  }

  Widget _ruleRow(String text, bool done, {Widget? trailing}) {
    return ListTile(
      dense: true,
      leading: Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: done ? Colors.greenAccent : Colors.white70),
      title: Text(text),
      trailing: trailing,
    );
  }

  Widget _walkToggle(WidgetRef ref, AppStateModel appState) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(AppLocalizations.of(ref.context).requireWalk),
        Switch(
          value: appState.requireWalk,
          onChanged: (v) => ref.read(appControllerProvider.notifier).toggleRequireWalk(v),
        )
      ],
    );
  }
}
