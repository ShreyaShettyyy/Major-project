// Web implementation using HTMLAudioElement
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class PlatformAudioPlayer {
  static html.AudioElement? _currentAudio;

  static void playUrl(String url) {
    stop();
    try {
      _currentAudio = html.AudioElement(url)..autoplay = true;
      _currentAudio!.play();
    } catch (_) {}
  }

  static void playBase64(String base64Mp3) {
    playUrl('data:audio/mp3;base64,$base64Mp3');
  }

  static void stop() {
    try {
      _currentAudio?.pause();
      _currentAudio?.currentTime = 0;
      _currentAudio = null;
    } catch (_) {}
  }
}
