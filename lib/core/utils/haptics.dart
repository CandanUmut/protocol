import 'dart:io';
import 'package:flutter/services.dart';

Future<void> lightHaptic({bool enabled = true}) async {
  if (!enabled) return;
  if (!Platform.isAndroid && !Platform.isIOS) return;
  await HapticFeedback.selectionClick();
}
