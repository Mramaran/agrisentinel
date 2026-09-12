import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class SpeakButton extends StatelessWidget {
  final String english;
  final String tamil;
  const SpeakButton({super.key, required this.english, required this.tamil});

  static final FlutterTts _tts = FlutterTts();

  Future<void> _speak(String text, String lang) async {
    try {
      await _tts.setLanguage(lang);
      await _tts.setSpeechRate(0.45);
      await _tts.speak(text);
    } catch (_) {
      // Demo: ignore missing voices.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: () => _speak(tamil, 'ta-IN'),
          icon: const Icon(Icons.volume_up),
          label: const Text('தமிழ்'),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () => _speak(english, 'en-IN'),
          icon: const Icon(Icons.volume_up),
          label: const Text('English'),
        ),
      ],
    );
  }
}
