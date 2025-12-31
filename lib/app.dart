import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/i18n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/calendar/calendar_screen.dart';
import 'features/emergency/emergency_screen.dart';
import 'features/insights/insights_screen.dart';
import 'features/settings/settings_screen.dart';
import 'state/app_controller.dart';
import 'widgets/gradient_background.dart';

class CloseTheRampApp extends ConsumerWidget {
  const CloseTheRampApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocale = ref.watch(appLocaleProvider);
    return MaterialApp(
      title: 'Close the Ramp — Protocol',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      locale: appLocale.locale,
      supportedLocales: const [Locale('tr'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const _RootShell(),
    );
  }
}

class _RootShell extends ConsumerStatefulWidget {
  const _RootShell();

  @override
  ConsumerState<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<_RootShell> {
  int _index = 0;
  final _pages = const [DashboardScreen(), CalendarScreen(), InsightsScreen(), SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(child: _pages[_index]),
        floatingActionButton: FloatingActionButton.large(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmergencyScreen())),
          child: const Icon(Icons.sos),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (v) => setState(() => _index = v),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard),
              label: t.dashboardTitle,
            ),
            NavigationDestination(
              icon: const Icon(Icons.calendar_month_outlined),
              selectedIcon: const Icon(Icons.calendar_month),
              label: t.calendarTitle,
            ),
            NavigationDestination(
              icon: const Icon(Icons.insights_outlined),
              selectedIcon: const Icon(Icons.insights),
              label: t.insights,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: t.settings,
            ),
          ],
        ),
      ),
    );
  }
}
