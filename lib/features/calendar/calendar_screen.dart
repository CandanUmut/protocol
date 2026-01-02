import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/i18n/app_localizations.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/app_state.dart';
import '../../data/models/day_entry.dart';
import '../../state/app_controller.dart';
import '../../widgets/glass_card.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appControllerProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final t = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            IconButton(onPressed: _prevMonth, icon: const Icon(Icons.chevron_left)),
            Expanded(
              child: Center(
                child: Text(DateFormat.yMMM(t.locale.languageCode).format(_focusedMonth), style: Theme.of(context).textTheme.titleLarge),
              ),
            ),
            IconButton(onPressed: _today, icon: const Icon(Icons.today)),
            IconButton(onPressed: _nextMonth, icon: const Icon(Icons.chevron_right)),
          ],
        ),
        const SizedBox(height: 8),
        _buildCalendar(appState, selectedDate),
        const SizedBox(height: 16),
        _DayPanel(appState: appState, selected: selectedDate),
      ],
    );
  }

  Widget _buildCalendar(AppStateModel state, DateTime selectedDate) {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final firstWeekday = (firstDay.weekday + 6) % 7; // Monday start
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final totalCells = firstWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final cells = List<Widget>.generate(rows * 7, (index) {
      final dayNum = index - firstWeekday + 1;
      if (dayNum < 1 || dayNum > daysInMonth) {
        return const SizedBox.shrink();
      }
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
      final status = state.statusFor(date);
      final isSelected = isoDate(date) == isoDate(selectedDate);
      Color dot;
      switch (status) {
        case DayStatus.good:
          dot = Colors.greenAccent;
          break;
        case DayStatus.partial:
          dot = Colors.amberAccent;
          break;
        case DayStatus.empty:
        default:
          dot = Colors.redAccent;
      }
      return GestureDetector(
        onTap: () => ref.read(appControllerProvider.notifier).setSelectedDate(date),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white12 : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? Colors.tealAccent : Colors.white24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$dayNum'),
              const SizedBox(height: 4),
              Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
            ],
          ),
        ),
      );
    });

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cells,
    );
  }

  void _prevMonth() {
    setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1));
  }

  void _nextMonth() {
    setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1));
  }

  void _today() {
    final today = DateTime.now();
    ref.read(appControllerProvider.notifier).setSelectedDate(today);
    setState(() => _focusedMonth = DateTime(today.year, today.month, 1));
  }
}

class _DayPanel extends ConsumerWidget {
  const _DayPanel({required this.appState, required this.selected});

  final AppStateModel appState;
  final DateTime selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final entry = appState.dayFor(selected);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(DateFormat.yMMMMd(t.locale.languageCode).format(selected), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
                label: Text(t.rule1),
                selected: entry.noNegotiation,
                onSelected: (v) => ref.read(appControllerProvider.notifier).toggleCore('noNegotiation', v),
              ),
              FilterChip(
                label: Text(t.rule2),
                selected: entry.noPhoneBedroom,
                onSelected: (v) => ref.read(appControllerProvider.notifier).toggleCore('noPhoneBedroom', v),
              ),
              FilterChip(
                label: Text(t.dailyWalk),
                selected: entry.dailyWalk,
                onSelected: (v) => ref.read(appControllerProvider.notifier).toggleCore('dailyWalk', v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () => ref.read(appControllerProvider.notifier).markAll(),
                icon: const Icon(Icons.done_all),
                label: Text(t.markAll),
              ),
              OutlinedButton.icon(
                onPressed: () => ref.read(appControllerProvider.notifier).clearDay(),
                icon: const Icon(Icons.clear),
                label: Text(t.clearDay),
              ),
              OutlinedButton.icon(
                onPressed: () => ref.read(appControllerProvider.notifier).logEmergency(),
                icon: const Icon(Icons.warning),
                label: Text(t.logEmergency),
              ),
            ],
          ),
        const SizedBox(height: 12),
        Text('${t.notes} — ${DateFormat('y-MM-dd').format(selected)}'),
        TextFormField(
          key: ValueKey(isoDate(selected)),
          initialValue: entry.notes,
          maxLines: 3,
          onChanged: (v) => ref.read(appControllerProvider.notifier).updateNotes(v),
          decoration: const InputDecoration(hintText: '...'),
        ),
          const SizedBox(height: 12),
          _TodoList(entry: entry),
        ],
      ),
    );
  }
}

class _TodoList extends ConsumerStatefulWidget {
  const _TodoList({required this.entry});
  final DayEntry entry;

  @override
  ConsumerState<_TodoList> createState() => _TodoListState();
}

class _TodoListState extends ConsumerState<_TodoList> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appControllerProvider);
    final todos = appState.todos;
    final entry = widget.entry;
    final t = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(hintText: '${t.dailyWalk} - add todo'),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: () {
                if (_controller.text.trim().isEmpty) return;
                ref.read(appControllerProvider.notifier).addTodo(_controller.text.trim());
                _controller.clear();
              },
            )
          ],
        ),
        const SizedBox(height: 8),
        for (final todo in todos)
          CheckboxListTile(
            value: entry.todoStates[todo.id] ?? false,
            onChanged: (v) => ref.read(appControllerProvider.notifier).toggleTodo(todo.id, v ?? false),
            title: Text(todo.title),
            secondary: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => ref.read(appControllerProvider.notifier).deleteTodo(todo.id),
            ),
          ),
      ],
    );
  }
}
