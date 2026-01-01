import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import '../../data/models/protocol.dart';
import 'haptics.dart';

class SoundPlayer {
  SoundPlayer._();
  static final instance = SoundPlayer._();

  final AudioPlayer _player = AudioPlayer();
  Timer? _alarmStopper;

  Future<void> playClick() async {
    await SystemSound.play(SystemSoundType.click);
  }

  Future<void> playChime() async {
    await SystemSound.play(SystemSoundType.alert);
  }

  Future<void> playAlarm(AlarmSettings settings) async {
    final autoStop = settings.autoStopSeconds.clamp(10, 20);
    final source = switch (settings.intensity) {
      AlarmIntensity.soft => 'assets/sounds/alarm_soft.mp3',
      AlarmIntensity.strong => 'assets/sounds/alarm_strong.mp3',
      AlarmIntensity.extreme => 'assets/sounds/alarm_extreme.mp3',
    };
    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource(source.replaceFirst('assets/', '')),
          volume: settings.volume.clamp(0.0, 1.0));
      _alarmStopper?.cancel();
      _alarmStopper = Timer(Duration(seconds: autoStop), () => _player.stop());
    } catch (_) {
      await SystemSound.play(SystemSoundType.alert);
      lightHaptic();
    }
  }

  Future<void> playTimerDone() async {
    try {
      await _player.play(AssetSource('sounds/timer_done.mp3'));
    } catch (_) {
      await SystemSound.play(SystemSoundType.alert);
    }
  }
}
