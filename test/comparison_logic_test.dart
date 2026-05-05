import 'package:flutter_test/flutter_test.dart';
import 'package:quran_tracker/utils/comparison_logic.dart';

void main() {
  group('ComparisonLogic - normalize', () {
    test('should remove diacritics and quranic marks', () {
      expect(ComparisonLogic.normalize("بِسْمِ اللَّهِ ۖ"), "بسم الله");
    });

    test('should normalize all Alif forms including Alif Wasla', () {
      expect(ComparisonLogic.normalize("أإآٱ"), "اااا");
    });

    test('should normalize Teh Marbuta', () {
      expect(ComparisonLogic.normalize("سورة"), "سوره");
    });

    test('should normalize Ya and Kaf variants', () {
      expect(ComparisonLogic.normalize("ىی ک"), "يي ك");
    });

    test('should condense multiple spaces', () {
      expect(ComparisonLogic.normalize("  كلمه    اخرى  "), "كلمه اخري");
    });
  });

  group('ComparisonLogic - compare (Quranic specific)', () {
    test('should match Alif Wasla in original with plain Alif in transcription', () {
      // ٱلْحَمْدُ (with Alif Wasla) vs الحمد (plain Alif)
      final results = ComparisonLogic.compare("ٱلْحَمْدُ", "الحمد");
      expect(results[0].isCorrect, true);
    });

    test('should handle common mismatches reported by user', () {
      final results = ComparisonLogic.compare(
        "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ",
        "بسم الله الرحمن الرحيم " // Added extra space at end
      );
      
      for (var result in results) {
        expect(result.isCorrect, true);
      }
    });
  });
}
