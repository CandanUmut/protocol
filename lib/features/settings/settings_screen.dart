import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/app_localizations.dart';
import '../../state/app_controller.dart';
import '../../widgets/animated_toggle_tile.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/section_header.dart';
import '../../data/models/protocol.dart';
import '../challenges/create_challenge_screen.dart';
import '../templates/template_library_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final t = AppLocalizations.of(context);
    final notifier = ref.read(appControllerProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionHeader(title: t.language),
            DropdownButton<String>(
              value: state.lang,
              onChanged: (v) => notifier.setLanguage(v ?? 'tr'),
              items: const [
                DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
            ),
          ]),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: t.createChallengeTitle),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const CreateChallengeScreen())),
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text(t.createChallengeTitle),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const TemplateLibraryScreen())),
                    icon: const Icon(Icons.library_books),
                    label: Text(t.templateLibraryTitle),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: t.goalDays),
              Slider(
                min: 30,
                max: 90,
                divisions: 3,
                value: state.goalDays.toDouble(),
                onChanged: (v) => notifier.setGoalDays(v.round()),
                label: '${state.goalDays}',
              ),
              const SizedBox(height: 8),
              AnimatedToggleTile(
                title: t.requireWalk,
                subtitle: t.requireWalkNote,
                value: state.requireWalk,
                onChanged: notifier.toggleRequireWalk,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: t.riskWindow),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      min: 0,
                      max: 23,
                      divisions: 23,
                      value: state.riskWindowStartHour.toDouble(),
                      onChanged: (v) => notifier.updateRiskWindow(v.round(), state.riskWindowEndHour),
                      label: '${state.riskWindowStartHour}:00',
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      min: 0,
                      max: 23,
                      divisions: 23,
                      value: state.riskWindowEndHour.toDouble(),
                      onChanged: (v) => notifier.updateRiskWindow(state.riskWindowStartHour, v.round()),
                      label: '${state.riskWindowEndHour}:00',
                    ),
                  ),
                ],
              ),
              Text(t.riskWindowNote, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: t.notifications),
              AnimatedToggleTile(
                title: t.notifications,
                subtitle: t.notificationsBody,
                value: state.notificationsEnabled,
                onChanged: notifier.toggleNotifications,
              ),
              const SizedBox(height: 8),
              AnimatedToggleTile(
                title: t.sounds,
                subtitle: t.soundsBody,
                value: state.soundEnabled,
                onChanged: notifier.toggleSound,
              ),
              const SizedBox(height: 8),
              AnimatedToggleTile(
                title: t.haptics,
                subtitle: t.hapticsBody,
                value: state.hapticsEnabled,
                onChanged: notifier.toggleHaptics,
              ),
              const SizedBox(height: 8),
              SectionHeader(title: t.alarmIntensity),
              DropdownButton<AlarmIntensity>(
                value: state.alarmSettings.intensity,
                onChanged: (v) {
                  if (v != null) {
                    notifier.updateAlarm(state.alarmSettings.copyWith(intensity: v));
                  }
                },
                items: [
                  DropdownMenuItem(value: AlarmIntensity.soft, child: Text(t.alarmSoft)),
                  DropdownMenuItem(value: AlarmIntensity.strong, child: Text(t.alarmStrong)),
                  DropdownMenuItem(value: AlarmIntensity.extreme, child: Text(t.alarmExtreme)),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      min: 10,
                      max: 20,
                      divisions: 10,
                      value: state.alarmSettings.autoStopSeconds.toDouble().clamp(10, 20),
                      label: '${state.alarmSettings.autoStopSeconds}s',
                      onChanged: (v) => notifier
                          .updateAlarm(state.alarmSettings.copyWith(autoStopSeconds: v.round())),
                    ),
                  ),
                  Text(t.alarmAutoStop),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: t.dataControl),
              Text(t.privacyInfo),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: notifier.exportState,
                    icon: const Icon(Icons.upload_file),
                    label: Text(t.exportLabel),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: notifier.importState,
                    icon: const Icon(Icons.download),
                    label: Text(t.importLabel),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: notifier.reset,
                    icon: const Icon(Icons.delete_forever),
                    label: Text(t.reset),
                  ),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }
}
