import 'dart:io';
import 'package:flutter/services.dart';

Future<void> lightHaptic() async {
  if (!Platform.isAndroid && !Platform.isIOS) return;
  await HapticFeedback.selectionClick();
}
