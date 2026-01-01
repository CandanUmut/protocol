import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
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

  Future<bool> playAlarm(AlarmSettings settings, {bool simulateFailure = false}) async {
    final autoStop = settings.autoStopSeconds.clamp(10, 20);
    final source = switch (settings.intensity) {
      AlarmIntensity.soft => 'assets/sounds/alarm_soft.mp3',
      AlarmIntensity.strong => 'assets/sounds/alarm_strong.mp3',
      AlarmIntensity.extreme => 'assets/sounds/alarm_extreme.mp3',
    };
    try {
      if (simulateFailure) throw Exception('Simulated alarm failure');
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource(source.replaceFirst('assets/', '')),
          volume: settings.volume.clamp(0.0, 1.0));
      _alarmStopper?.cancel();
      _alarmStopper = Timer(Duration(seconds: autoStop), () => _player.stop());
      return true;
    } catch (e) {
      debugPrint('Alarm playback failed: $e');
      await SystemSound.play(SystemSoundType.alert);
      lightHaptic();
      return false;
    }
  }

  Future<bool> playTimerDone() async {
    try {
      await _player.play(AssetSource('sounds/timer_done.mp3'));
      return true;
    } catch (_) {
      await SystemSound.play(SystemSoundType.alert);
      return false;
    }
  }
}
