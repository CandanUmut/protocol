import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/app_localizations.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/date_utils.dart';
import '../../state/app_controller.dart';
import '../../data/models/app_state.dart';
import '../../widgets/animated_toggle_tile.dart';
import '../../widgets/buttons.dart';
import '../../widgets/chips.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/section_header.dart';
import '../emergency/emergency_screen.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _urgeSeconds = 0;
  Timer? _urgeTimer;

  @override
  void dispose() {
    _urgeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appControllerProvider);
    final t = AppLocalizations.of(context);
    final today = DateTime.now();
    final status = appState.statusFor(today);
    final streak = appState.streak(today);
    final successMonth = appState.successThisMonth(today);
    final emergencyMonth = appState.emergenciesThisMonth(today);
    final todayEntry = appState.dayFor(today);

    final streakBadge = StatusChip(
      label: '${t.streak}: $streak',
      color: Colors.tealAccent,
      icon: Icons.local_fire_department,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.appTitle, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(t.todayStatus, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
            ]),
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const SettingsScreen(), fullscreenDialog: true)),
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: t.settings,
                ),
                IconButton(
                  onPressed: () => _toggleLanguage(appState.lang),
                  icon: const Icon(Icons.language),
                  tooltip: t.languageToggle,
                ),
              ],
            )
          ],
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: t.progress),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      duration: DesignTokens.slow,
                      tween: Tween(begin: 0, end: streak.toDouble()),
                      builder: (_, value, __) => Text(value.toStringAsFixed(0),
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      streakBadge,
                      const SizedBox(height: 8),
                      StatusChip(label: '${t.goal}: ${appState.goalDays}', color: Colors.orangeAccent, icon: Icons.flag),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 8),
              TweenAnimationBuilder<double>(
                duration: DesignTokens.medium,
                tween: Tween(begin: 0, end: (streak / appState.goalDays).clamp(0, 1).toDouble()),
                builder: (_, value, __) => LinearProgressIndicator(value: value, minHeight: 10, borderRadius: BorderRadius.circular(12)),
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                StatusChip(label: _statusLabel(status, t), color: _statusColor(status), icon: Icons.check_circle),
                if (todayEntry.emergencies > 0)
                  StatusChip(
                    label: '${t.todayEmergency}: ${todayEntry.emergencies}',
                    color: Colors.amberAccent,
                    icon: Icons.warning_amber_rounded,
                  ),
                StatusChip(
                  label: '${t.protectionScore}: ${appState.protectionScore(today)}%',
                  color: Colors.lightBlueAccent,
                  icon: Icons.shield_moon,
                ),
                if (appState.inNightRiskWindow && !(todayEntry.noPhoneBedroom && todayEntry.noNegotiation))
                  StatusChip(
                    label: t.nightRisk,
                    color: Colors.purpleAccent,
                    icon: Icons.nightlight_round,
                  ),
              ]),
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
                    SectionHeader(title: t.monthSuccess),
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
                    SectionHeader(title: t.monthEmergencies),
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
              SectionHeader(title: t.emergency, action: IconButton(onPressed: _openEmergency, icon: const Icon(Icons.open_in_new))),
              const SizedBox(height: 8),
              Text(t.emergencyMicrocopy, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              PrimaryButton(label: '${t.emergency} — ${t.evacuate}', icon: Icons.warning_amber_rounded, onPressed: _openEmergency),
              const SizedBox(height: 8),
              Text(t.supportiveChip, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.greenAccent)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _coreRulesCard(appState, todayEntry),
        const SizedBox(height: 12),
        _preventionCard(t),
        const SizedBox(height: 12),
        _milestoneBanner(streak, t),
      ],
    );
  }

  Widget _coreRulesCard(AppStateModel appState, DayEntry todayEntry) {
    final t = AppLocalizations.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: t.coreRules),
          const SizedBox(height: 8),
          _ruleRow(t.rule1, todayEntry.noNegotiation),
          _ruleRow(t.rule2, todayEntry.noPhoneBedroom),
          _ruleRow(t.dailyWalk, todayEntry.dailyWalk || !appState.requireWalk, trailing: _walkToggle(appState)),
          const SizedBox(height: 8),
          AnimatedToggleTile(
            title: t.requireWalk,
            subtitle: t.requireWalkNote,
            value: appState.requireWalk,
            onChanged: (v) => ref.read(appControllerProvider.notifier).toggleRequireWalk(v),
          ),
        ],
      ),
    );
  }

  Widget _preventionCard(AppLocalizations t) {
    final surgeValue = _urgeSeconds > 0 ? _urgeSeconds : 90;
    final progress = 1 - (surgeValue / 90);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: t.preventionToolkit),
          const SizedBox(height: 12),
          Text(t.urgeSurfingTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(t.urgeSurfingBody, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress.clamp(0, 1), minHeight: 8, borderRadius: BorderRadius.circular(12)),
          const SizedBox(height: 8),
          PrimaryButton(
            label: _urgeTimer == null ? t.start90s : '${t.remaining}: ${surgeValue.toString().padLeft(2, '0')}s',
            icon: Icons.water_drop,
            onPressed: _startUrgeSurfing,
            expand: false,
          ),
          const SizedBox(height: 12),
          Text(t.ifThenPlan, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: ref.read(appControllerProvider).ifThenPlan,
            onChanged: (v) => ref.read(appControllerProvider.notifier).updateIfThenPlan(v),
            decoration: InputDecoration(hintText: t.ifThenPlaceholder),
          ),
          const SizedBox(height: 12),
          Text(t.triggerLogTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: ['loneliness', 'stress', 'boredom', 'late-night', 'accidental', 'other']
                .map((trigger) => ChoiceChip(
                      label: Text(trigger),
                      selected: false,
                      onSelected: (_) => ref.read(appControllerProvider.notifier).addTriggerLog(trigger),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _milestoneBanner(int streak, AppLocalizations t) {
    const milestones = [3, 7, 14, 30, 60, 90];
    final reached = milestones.firstWhere((m) => streak >= m, orElse: () => 0);
    if (reached == 0) return const SizedBox.shrink();
    return GlassCard(
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: Colors.amberAccent),
          const SizedBox(width: 12),
          Expanded(child: Text('${t.streak} $reached — ${t.milestoneBody}')),
        ],
      ),
    );
  }

  void _toggleLanguage(String current) {
    final next = current == 'tr' ? 'en' : 'tr';
    ref.read(appControllerProvider.notifier).setLanguage(next);
  }

  void _startUrgeSurfing() {
    _urgeTimer?.cancel();
    setState(() {
      _urgeSeconds = 90;
    });
    _urgeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _urgeSeconds = _urgeSeconds - 1);
      if (_urgeSeconds <= 0) {
        timer.cancel();
      }
    });
  }

  void _openEmergency() {
    ref.read(appControllerProvider.notifier).setSelectedDate(DateTime.now());
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmergencyScreen()));
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
      leading: AnimatedSwitcher(
        duration: DesignTokens.fast,
        child: Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
            key: ValueKey(done), color: done ? Colors.greenAccent : Colors.white70),
      ),
      title: Text(text),
      trailing: trailing,
    );
  }

  Widget _walkToggle(AppStateModel appState) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(AppLocalizations.of(context).requireWalk),
        Switch(
          value: appState.requireWalk,
          onChanged: (v) => ref.read(appControllerProvider.notifier).toggleRequireWalk(v),
        )
      ],
    );
  }
}
