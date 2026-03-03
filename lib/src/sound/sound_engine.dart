import 'package:just_audio/just_audio.dart';

class SoundEngine {
  final Map<String, _SoundChannel> _channels = <String, _SoundChannel>{};

  Future<void> play({
    required String channel,
    required String assetPath,
    String? package,
    bool loop = false,
    double volume = 1.0,
    bool restart = false,
  }) async {
    final entry = _channels.putIfAbsent(channel, _SoundChannel.new);
    final player = entry.player;

    final sourceChanged =
        entry.assetPath != assetPath || entry.packageName != package;
    if (sourceChanged) {
      await player.setAudioSource(
        AudioSource.asset(assetPath, package: package),
        preload: true,
      );
      entry.assetPath = assetPath;
      entry.packageName = package;
    }

    await player.setLoopMode(loop ? LoopMode.one : LoopMode.off);
    await player.setVolume(volume.clamp(0.0, 1.0));
    if (restart) {
      await player.seek(Duration.zero);
    }
    if (!player.playing) {
      await player.play();
    }
  }

  Future<void> pause(String channel) async {
    final entry = _channels[channel];
    if (entry == null) {
      return;
    }
    await entry.player.pause();
  }

  Future<void> stop(String channel) async {
    final entry = _channels[channel];
    if (entry == null) {
      return;
    }
    await entry.player.stop();
  }

  Future<void> setVolume(String channel, double volume) async {
    final entry = _channels[channel];
    if (entry == null) {
      return;
    }
    await entry.player.setVolume(volume.clamp(0.0, 1.0));
  }

  bool isPlaying(String channel) {
    final entry = _channels[channel];
    if (entry == null) {
      return false;
    }
    return entry.player.playing;
  }

  Future<void> disposeChannel(String channel) async {
    final entry = _channels.remove(channel);
    if (entry == null) {
      return;
    }
    await entry.player.dispose();
  }

  Future<void> dispose() async {
    final players = _channels.values.map((entry) => entry.player).toList();
    _channels.clear();
    for (final player in players) {
      await player.dispose();
    }
  }
}

class _SoundChannel {
  final AudioPlayer player = AudioPlayer();
  String? assetPath;
  String? packageName;
}
