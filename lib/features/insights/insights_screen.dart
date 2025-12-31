import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/app_localizations.dart';
import '../../core/utils/date_utils.dart';
import '../../state/app_controller.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/section_header.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final t = AppLocalizations.of(context);
    final today = DateTime.now();
    final days = List<DateTime>.generate(30, (i) => today.subtract(Duration(days: i)));
    final successSeries = days.reversed
        .map((d) => state.dayFor(d).isSuccess(requireWalk: state.requireWalk) ? 1.0 : 0.0)
        .toList();
    final emergencyCounts = _emergenciesPerWeek(state, today);
    final triggerCount = <String, int>{};
    for (final log in state.triggerLogs) {
      triggerCount[log.trigger] = (triggerCount[log.trigger] ?? 0) + 1;
    }
    final topTrigger = triggerCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionHeader(title: t.streakTrend),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    for (int i = 0; i < successSeries.length; i++)
                      BarChartGroupData(x: i, barRods: [BarChartRodData(toY: successSeries[i], width: 6, color: Colors.tealAccent)])
                  ],
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: t.emergenciesPerWeek),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: BarChart(
                  BarChartData(
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      for (int i = 0; i < emergencyCounts.length; i++)
                        BarChartGroupData(x: i, barRods: [BarChartRodData(toY: emergencyCounts[i].toDouble(), width: 12, color: Colors.amberAccent)])
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: t.topTriggers),
              const SizedBox(height: 8),
              if (topTrigger.isEmpty)
                Text(t.noTriggers)
              else
                ...topTrigger.take(3).map((e) => ListTile(
                      title: Text(e.key),
                      trailing: Text('${e.value}'),
                    )),
            ],
          ),
        ),
      ],
    );
  }

  List<int> _emergenciesPerWeek(dynamic state, DateTime today) {
    final weeks = <int>[0, 0, 0, 0];
    for (int i = 0; i < 28; i++) {
      final day = today.subtract(Duration(days: i));
      final weekIndex = (i / 7).floor();
      weeks[weekIndex] += state.dayFor(day).emergencies;
    }
    return weeks.reversed.toList();
  }
}
