import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/i18n/app_localizations.dart';
import '../../data/models/protocol.dart';
import '../../data/models/protocol_step.dart';
import '../../state/app_controller.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/section_header.dart';

class TemplateLibraryScreen extends ConsumerWidget {
  const TemplateLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);
    final lang = state.lang;
    final templates = [...state.templates];
    templates.sort((a, b) => a.nameFor(lang).compareTo(b.nameFor(lang)));

    return Scaffold(
      appBar: AppBar(title: Text(t.templateLibraryTitle)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: templates.length,
        itemBuilder: (context, index) {
          final template = templates[index];
          return _TemplateCard(template: template, lang: lang);
        },
      ),
    );
  }
}

class _TemplateCard extends ConsumerWidget {
  const _TemplateCard({required this.template, required this.lang});
  final ProtocolTemplate template;
  final String lang;

  String _durationSummary() {
    final timers = template.steps.where((s) => s.type == ProtocolStepType.timer && s.durationSec != null).toList();
    if (timers.isEmpty) return '•';
    final parts = timers.map((s) {
      final minutes = (s.durationSec! / 60).round();
      return '$minutes min';
    }).toList();
    return parts.join(' + ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: template.nameFor(lang), subtitle: template.descriptionFor(lang)),
          const SizedBox(height: 8),
          Text(_durationSummary(), style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          ...template.steps.map((s) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(_iconFor(s.type), color: s.critical ? Colors.redAccent : Colors.white60),
                title: Text(s.titleFor(lang)),
                subtitle: s.detailsFor(lang) != null ? Text(s.detailsFor(lang)!) : null,
                trailing: s.durationSec != null ? Text('${(s.durationSec! / 60).round()}m') : null,
              )),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle),
                label: Text(t.useTemplate),
                onPressed: () => ref.read(appControllerProvider.notifier).setDefaultTemplate(template.id),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit),
                label: Text(t.customizeSteps),
                onPressed: () => _openCustomize(context, ref),
              ),
            ],
          )
        ],
      ),
    );
  }

  IconData _iconFor(ProtocolStepType type) {
    switch (type) {
      case ProtocolStepType.timer:
        return Icons.timer;
      case ProtocolStepType.breathing:
        return Icons.air;
      case ProtocolStepType.action:
        return Icons.bolt;
      case ProtocolStepType.checkbox:
      default:
        return Icons.check_box_outlined;
    }
  }

  void _openCustomize(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _CustomizeSheet(template: template, lang: lang),
    );
  }
}

class _CustomizeSheet extends ConsumerStatefulWidget {
  const _CustomizeSheet({required this.template, required this.lang});
  final ProtocolTemplate template;
  final String lang;

  @override
  ConsumerState<_CustomizeSheet> createState() => _CustomizeSheetState();
}

class _CustomizeSheetState extends ConsumerState<_CustomizeSheet> {
  late TextEditingController nameEn;
  late TextEditingController nameTr;
  late TextEditingController descEn;
  late TextEditingController descTr;
  late List<TextEditingController> stepEn;
  late List<TextEditingController> stepTr;

  @override
  void initState() {
    super.initState();
    nameEn = TextEditingController(text: widget.template.nameEn ?? widget.template.name ?? '');
    nameTr = TextEditingController(text: widget.template.nameTr ?? widget.template.name ?? '');
    descEn = TextEditingController(text: widget.template.descriptionEn ?? widget.template.description ?? '');
    descTr = TextEditingController(text: widget.template.descriptionTr ?? widget.template.description ?? '');
    stepEn = widget.template.steps.map((s) => TextEditingController(text: s.titleEn ?? s.title ?? '')).toList();
    stepTr = widget.template.steps.map((s) => TextEditingController(text: s.titleTr ?? s.title ?? '')).toList();
  }

  @override
  void dispose() {
    nameEn.dispose();
    nameTr.dispose();
    descEn.dispose();
    descTr.dispose();
    for (final c in [...stepEn, ...stepTr]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: t.customizeSteps),
            TextField(controller: nameEn, decoration: const InputDecoration(labelText: 'Name (EN)')),
            TextField(controller: nameTr, decoration: const InputDecoration(labelText: 'Ad (TR)')),
            TextField(controller: descEn, decoration: const InputDecoration(labelText: 'Description (EN)')),
            TextField(controller: descTr, decoration: const InputDecoration(labelText: 'Açıklama (TR)')),
            const SizedBox(height: 8),
            ...List.generate(widget.template.steps.length, (index) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${t.stepLabel} ${index + 1}', style: Theme.of(context).textTheme.titleSmall),
                  TextField(controller: stepEn[index], decoration: const InputDecoration(labelText: 'Title (EN)')),
                  TextField(controller: stepTr[index], decoration: const InputDecoration(labelText: 'Başlık (TR)')),
                  const SizedBox(height: 8),
                ],
              );
            }),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: Text(t.saveTemplate),
                onPressed: _save,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _save() {
    final updatedSteps = <ProtocolStep>[];
    for (var i = 0; i < widget.template.steps.length; i++) {
      final step = widget.template.steps[i];
      updatedSteps.add(step.copyWith(titleEn: stepEn[i].text, titleTr: stepTr[i].text));
    }
    final updatedTemplate = widget.template.copyWith(
      id: const Uuid().v4(),
      nameEn: nameEn.text,
      nameTr: nameTr.text,
      descriptionEn: descEn.text,
      descriptionTr: descTr.text,
      steps: updatedSteps,
    );
    ref.read(appControllerProvider.notifier).saveTemplate(updatedTemplate, setAsDefault: true);
    Navigator.of(context).pop();
  }
}
