import 'package:flutter/foundation.dart';

import '../utils/sound.dart';
import '../../data/models/protocol.dart';

/// A thin wrapper around [SoundPlayer] that never throws and reports success.
class SafeAudioService {
  SafeAudioService({SoundPlayer? player}) : _player = player ?? SoundPlayer.instance;

  final SoundPlayer _player;

  Future<bool> playAlarm(AlarmSettings settings, {bool simulateFailure = false}) async {
    try {
      return await _player.playAlarm(settings, simulateFailure: simulateFailure);
    } catch (err, stack) {
      debugPrint('SafeAudioService.playAlarm failed: $err\n$stack');
      return false;
    }
  }

  Future<bool> stopAlarm() async {
    try {
      return await _player.stop();
    } catch (err, stack) {
      debugPrint('SafeAudioService.stopAlarm failed: $err\n$stack');
      return false;
    }
  }

  Future<bool> playDone() async {
    try {
      await _player.playTimerDone();
      return true;
    } catch (err, stack) {
      debugPrint('SafeAudioService.playDone failed: $err\n$stack');
      return false;
    }
  }
}
