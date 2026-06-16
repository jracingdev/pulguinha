import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Sons de feedback no app (água, aniversário).
class AppSoundService {
  AppSoundService._();
  static final instance = AppSoundService._();

  final AudioPlayer _player = AudioPlayer();
  bool _ready = false;

  Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      _ready = true;
    } catch (e) {
      debugPrint('AppSoundService init: $e');
    }
  }

  Future<void> playAgua() async {
    if (!_ready || kIsWeb) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/agua.mp3'), volume: 0.85);
    } catch (e) {
      debugPrint('Som água: $e');
    }
  }

  /// Fogos de artifício por [duration] (padrão 2s).
  Future<void> playFogos({Duration duration = const Duration(seconds: 2)}) async {
    if (!_ready || kIsWeb) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/fogos.mp3'), volume: 0.9);
      Future.delayed(duration, () async {
        try {
          await _player.stop();
        } catch (_) {}
      });
    } catch (e) {
      debugPrint('Som fogos: $e');
    }
  }

  Future<void> dispose() => _player.dispose();
}
