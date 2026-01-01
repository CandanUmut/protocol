import 'package:close_the_ramp_protocol/core/default_templates.dart';
import 'package:close_the_ramp_protocol/data/models/app_state.dart';
import 'package:close_the_ramp_protocol/data/models/protocol.dart';
import 'package:close_the_ramp_protocol/state/app_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:close_the_ramp_protocol/data/repositories/app_repository.dart';

class _FakeRepo extends AppRepository {
  AppStateModel? _state;

  @override
  Future<AppStateModel> load() async => _state ?? AppStateModel();

  @override
  Future<void> save(AppStateModel state) async {
    _state = state;
  }

  @override
  Future<void> reset() async {
    _state = null;
  }

  @override
  Future<AppStateModel?> importJson() async => _state;

  @override
  Future<String> exportJson(AppStateModel state) async => '';
}

void main() {
  test('default template pack exposes 7 stable ids', () {
    final ids = DefaultTemplates.pack.map((e) => e.id).toList();
    expect(ids.length, 7);
    expect(ids, containsAll(<String>[
      'emergency_evacuation',
      'warning_interrupt',
      'digital_lockdown',
      'nicotine_shield',
      'food_delay_replace',
      'spiritual_reset',
      'social_rescue',
    ]));
  });

  test('templates are bilingual with critical steps preserved', () {
    final tpl = DefaultTemplates.pack.firstWhere((t) => t.id == 'emergency_evacuation');
    expect(tpl.nameEn?.isNotEmpty, true);
    expect(tpl.nameTr?.isNotEmpty, true);
    expect(tpl.steps.where((s) => s.critical).length, greaterThan(0));
    final step = tpl.steps.first;
    expect(step.titleFor('en').isNotEmpty, true);
    expect(step.titleFor('tr').isNotEmpty, true);
  });

  test('recommended templates honor challenge type', () {
    final container = ProviderContainer(overrides: [appRepositoryProvider.overrideWithValue(_FakeRepo())]);
    final controller = container.read(appControllerProvider.notifier);
    final rec = controller.recommendedTemplates('scrolling');
    expect(rec.length, greaterThanOrEqualTo(1));
    expect(rec.first.recommendedFor.contains('scrolling'), true);
  });

  test('emergency session seeds steps from active template', () async {
    final repo = _FakeRepo();
    final container = ProviderContainer(overrides: [appRepositoryProvider.overrideWithValue(repo)]);
    final controller = container.read(appControllerProvider.notifier);
    await controller.initialized;
    await controller.startEmergencyTimer();
    final state = container.read(appControllerProvider);
    final session = state.emergencySessions.firstWhere((s) => s.id == state.activeEmergencySessionId);
    final template = DefaultTemplates.pack.first;
    expect(session.steps.length, template.steps.length);
  });
}
