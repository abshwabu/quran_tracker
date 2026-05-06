import 'package:flutter_test/flutter_test.dart';
import 'package:quran_tracker/utils/comparison_logic.dart';

void main() {
  group('ComparisonLogic - Accuracy Tests', () {
    test('Handles repeated words correctly', () {
      const original = "فَبِأَيِّ آلَاءِ رَبِّكُمَا تُكَذِّبَانِ";
      // User says it correctly but transcription might have small errors
      const transcribed = "فباي الا ربكما تكذبان";
      
      final results = ComparisonLogic.compare(original, transcribed);
      
      // All words should be correct given our threshold
      for (var result in results) {
        expect(result.isCorrect, true, reason: "Word '${result.word}' should be correct");
      }
    });

    test('Handles skipped words', () {
      const original = "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ";
      const transcribed = "بسم الله الرحيم"; // Skipped "الرحمن"
      
      final results = ComparisonLogic.compare(original, transcribed);
      
      expect(results[0].word, contains("بِسْمِ"));
      expect(results[0].isCorrect, true);
      
      expect(results[1].word, contains("اللَّهِ"));
      expect(results[1].isCorrect, true);
      
      expect(results[2].word, contains("الرَّحْمَنِ"));
      expect(results[2].isCorrect, false); // Skipped
      
      expect(results[3].word, contains("الرَّحِيمِ"));
      expect(results[3].isCorrect, true);
    });

    test('Handles extra words (repetitions)', () {
      const original = "قُلْ هُوَ اللَّهُ أَحَدٌ";
      const transcribed = "قل هو هو الله احد"; // Repeated "هو"
      
      final results = ComparisonLogic.compare(original, transcribed);
      
      expect(results[0].isCorrect, true); // قل
      expect(results[1].isCorrect, true); // هو
      expect(results[2].isCorrect, true); // الله
      expect(results[3].isCorrect, true); // احد
    });

    test('Robustness to slight spelling variations in transcription', () {
      // Whisper sometimes outputs variations
      const original = "الصَّمَدُ";
      const transcribed = "السمد"; // S instead of Sad (unlikely for Tarteel but possible)
      
      final results = ComparisonLogic.compare(original, transcribed);
      expect(results[0].isCorrect, true); // Should match via Levenshtein
    });

    test('Fails on completely wrong words', () {
      const original = "الْحَمْدُ لِلَّهِ";
      const transcribed = "الشكر لله"; // Wrong word
      
      final results = ComparisonLogic.compare(original, transcribed);
      expect(results[0].isCorrect, false); // الحمد vs الشكر
      expect(results[1].isCorrect, true); // لله
    });

    test('Handles large skips due to window limitation', () {
      const original = "أ ب ج د ه و ز ح ط ي ك ل م ن";
      const transcribed = "أ ب ك ل م ن"; // Skipped 7 words
      
      final results = ComparisonLogic.compare(original, transcribed);
      expect(results[2].isCorrect, false); // ج should be false
      expect(results[10].isCorrect, true); // ك should be true
    });

    test('Handles repetitions gracefully', () {
      const original = "الحمد لله رب العالمين";
      const transcribed = "الحمد الحمد لله رب العالمين"; 
      
      final results = ComparisonLogic.compare(original, transcribed);
      for (var result in results) {
        expect(result.isCorrect, true);
      }
    });
  });
}
