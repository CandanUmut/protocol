import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message, this.icon = Icons.hourglass_empty});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white54),
        const SizedBox(height: 8),
        Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
      ],
    );
  }
}
