import 'package:flutter/services.dart';

class SoundPlayer {
  SoundPlayer._();
  static final instance = SoundPlayer._();

  Future<void> playClick() async {
    await SystemSound.play(SystemSoundType.click);
  }

  Future<void> playChime() async {
    await SystemSound.play(SystemSoundType.alert);
  }
}
