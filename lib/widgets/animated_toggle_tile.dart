import 'package:flutter/material.dart';

import '../core/theme/design_tokens.dart';

class AnimatedToggleTile extends StatelessWidget {
  const AnimatedToggleTile({super.key, required this.title, required this.value, required this.onChanged, this.subtitle});

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: DesignTokens.medium,
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacing4, vertical: DesignTokens.spacing3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        color: value ? Colors.teal.withOpacity(0.1) : Colors.white.withOpacity(0.02),
        border: Border.all(color: value ? Colors.teal : Colors.white24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                ]
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
