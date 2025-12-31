import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color, this.icon});
  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: icon != null ? Icon(icon, size: 16, color: Colors.white) : null,
      backgroundColor: color.withOpacity(0.16),
      label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      side: BorderSide(color: color.withOpacity(0.6)),
    );
  }
}
