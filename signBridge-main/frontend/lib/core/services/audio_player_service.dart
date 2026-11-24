import 'audio_player_stub.dart'
    if (dart.library.html) 'audio_player_web.dart';

class AudioPlayerService {
  static void playUrl(String url) {
    PlatformAudioPlayer.playUrl(url);
  }

  static void playBase64(String base64Mp3) {
    PlatformAudioPlayer.playBase64(base64Mp3);
  }

  static void stop() {
    PlatformAudioPlayer.stop();
  }
}
