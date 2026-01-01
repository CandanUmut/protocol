import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/i18n/app_localizations.dart';
import '../../data/models/challenge.dart';
import '../../data/models/protocol.dart';
import '../../data/models/protocol_step.dart';
import '../../state/app_controller.dart';
import '../templates/template_library_screen.dart';

class CreateChallengeScreen extends ConsumerStatefulWidget {
  const CreateChallengeScreen({super.key});

  @override
  ConsumerState<CreateChallengeScreen> createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends ConsumerState<CreateChallengeScreen> {
  final Map<String, String> _icons = {
    'nicotine': '🚬',
    'lust': '🔥',
    'scrolling': '📱',
    'sugar': '🍭',
    'gambling': '🎲',
    'gaming': '🎮',
    'shopping': '🛍️',
    'custom': '✨',
  };

  String _selectedType = 'nicotine';
  ProtocolTemplate? _selectedTemplate;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final templates = ref.read(appControllerProvider.notifier).recommendedTemplates(_selectedType);
    final lang = ref.watch(appControllerProvider).lang;

    return Scaffold(
      appBar: AppBar(title: Text(t.createChallengeTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.chooseChallengeType, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _icons.keys
                  .map((type) => ChoiceChip(
                        label: Text(_labelFor(type, t)),
                        selected: _selectedType == type,
                        avatar: Text(_icons[type] ?? ''),
                        onSelected: (_) => setState(() {
                          _selectedType = type;
                          _selectedTemplate = null;
                        }),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Text(t.recommendedTemplates, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: templates
                    .map(
                      (tpl) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(tpl.nameFor(lang)),
                          subtitle: Text(tpl.descriptionFor(lang)),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_note),
                            onPressed: () async {
                              final customized = await _openCustomize(context, tpl);
                              if (customized != null) {
                                ref.read(appControllerProvider.notifier).saveTemplate(customized, setAsDefault: true);
                                setState(() => _selectedTemplate = customized);
                              }
                            },
                          ),
                          onTap: () => setState(() => _selectedTemplate = tpl),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.rocket_launch),
              label: Text(t.useTemplate),
              onPressed: () {
                final template = _selectedTemplate ?? templates.first;
                final challenge = Challenge(
                  name: _labelFor(_selectedType, t),
                  icon: _icons[_selectedType] ?? '✨',
                  defaultProtocolTemplateId: template.id,
                );
                ref.read(appControllerProvider.notifier).addChallenge(challenge);
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.library_books),
              label: Text(t.browseTemplates),
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const TemplateLibraryScreen())),
            ),
          ],
        ),
      ),
    );
  }

  String _labelFor(String type, AppLocalizations t) {
    switch (type) {
      case 'nicotine':
        return t.challengeNicotine;
      case 'lust':
        return t.challengeLust;
      case 'scrolling':
        return t.challengeScrolling;
      case 'sugar':
        return t.challengeSugar;
      case 'gambling':
        return t.challengeGambling;
      case 'gaming':
        return t.challengeGaming;
      case 'shopping':
        return t.challengeShopping;
      default:
        return t.challengeCustom;
    }
  }

  Future<ProtocolTemplate?> _openCustomize(BuildContext context, ProtocolTemplate template) async {
    return showModalBottomSheet<ProtocolTemplate>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ChallengeCustomizeSheet(template: template),
    );
  }
}

class _ChallengeCustomizeSheet extends StatefulWidget {
  const _ChallengeCustomizeSheet({required this.template});
  final ProtocolTemplate template;

  @override
  State<_ChallengeCustomizeSheet> createState() => _ChallengeCustomizeSheetState();
}

class _ChallengeCustomizeSheetState extends State<_ChallengeCustomizeSheet> {
  late List<TextEditingController> stepEn;
  late List<TextEditingController> stepTr;

  @override
  void initState() {
    super.initState();
    stepEn = widget.template.steps.map((s) => TextEditingController(text: s.titleEn ?? s.title ?? '')).toList();
    stepTr = widget.template.steps.map((s) => TextEditingController(text: s.titleTr ?? s.title ?? '')).toList();
  }

  @override
  void dispose() {
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
            Text(t.customizeSteps, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...List.generate(widget.template.steps.length, (index) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${t.stepLabel} ${index + 1}'),
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
                onPressed: () {
                  final updatedSteps = <ProtocolStep>[];
                  for (var i = 0; i < widget.template.steps.length; i++) {
                    final step = widget.template.steps[i];
                    updatedSteps.add(step.copyWith(titleEn: stepEn[i].text, titleTr: stepTr[i].text));
                  }
                  final updated = widget.template.copyWith(id: const Uuid().v4(), steps: updatedSteps);
                  Navigator.of(context).pop(updated);
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
