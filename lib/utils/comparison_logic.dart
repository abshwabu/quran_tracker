import 'dart:math';

class ComparisonLogic {
  /// Normalizes Arabic text.
  /// [keepVowels] If true, keeps basic Harakat (Fatha, Damma, Kasra, etc.)
  static String normalize(String text, {bool keepVowels = false}) {
    if (text.isEmpty) return "";

    // 1. Strip ornamental Quranic marks (always)
    // Range: \u06D6-\u06ED (various stop marks, etc.)
    // \u0670 (Alif Khanjari / Superscript Alif)
    final ornamental = RegExp(r'[\u0670\u06D6-\u06ED]');
    String normalized = text.replaceAll(ornamental, '');

    if (!keepVowels) {
      // Remove all basic diacritics
      // Range: \u064B-\u065F
      final diacritics = RegExp(r'[\u064B-\u065F]');
      normalized = normalized.replaceAll(diacritics, '');
    } else {
      // If keeping vowels, we still might want to strip things that are NOT basic Harakat
      // Basic Harakat range: \u064B-\u0652
      // We strip the rest of the \u064B-\u065F range if any (like \u0653-\u065F)
      final nonBasicDiacritics = RegExp(r'[\u0653-\u065F]');
      normalized = normalized.replaceAll(nonBasicDiacritics, '');
    }

    // 2. Normalize Alif forms
    normalized = normalized.replaceAll(RegExp(r'[أإآٱ]'), 'ا');

    // 3. Normalize Teh Marbuta to Heh
    normalized = normalized.replaceAll('ة', 'ه');

    // 4. Normalize Ya forms
    normalized = normalized.replaceAll(RegExp(r'[ىی]'), 'ي');

    // 5. Normalize Kaf forms
    normalized = normalized.replaceAll('ک', 'ك');

    // 6. Remove non-Arabic-letter characters (except spaces and kept diacritics)
    if (!keepVowels) {
      normalized = normalized.replaceAll(RegExp(r'[^\u0621-\u064A\s]'), '');
    } else {
      normalized = normalized.replaceAll(RegExp(r'[^\u0621-\u064A\u064B-\u0652\s]'), '');
    }
    
    // 7. Condense multiple spaces
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');
    
    return normalized.trim();
  }

  /// Compares two strings and returns a list of word-by-word feedback.
  static List<ComparisonResult> compare(String original, String transcribed) {
    // If the transcription has diacritics, we use diacritic-aware comparison
    // We detect this by checking if there are any diacritics in the transcribed string
    final hasDiacritics = RegExp(r'[\u064B-\u0652]').hasMatch(transcribed);

    final normalizedTranscribed = normalize(transcribed, keepVowels: hasDiacritics);
    final transcribedWords = normalizedTranscribed
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    final originalWordsWithDiacritics = original
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
        
    final normalizedOriginalWords = originalWordsWithDiacritics
        .map((w) => normalize(w, keepVowels: hasDiacritics))
        .toList();

    List<ComparisonResult> results = [];
    int currentTranscribedIdx = 0;

    for (int i = 0; i < originalWordsWithDiacritics.length; i++) {
      final target = normalizedOriginalWords[i];
      bool found = false;
      
      int lookAheadLimit = min(currentTranscribedIdx + 8, transcribedWords.length);
      
      for (int j = currentTranscribedIdx; j < lookAheadLimit; j++) {
        // If we are comparing with diacritics, we use a slightly more lenient similarity
        // because a single wrong vowel shouldn't necessarily skip the word if the letters are right,
        // but we'll flag it as "Incorrect" if the vowels don't match.
        if (_areWordsSimilar(target, transcribedWords[j], useDiacritics: hasDiacritics)) {
          found = true;
          currentTranscribedIdx = j + 1;
          break;
        }
      }

      results.add(ComparisonResult(
        word: originalWordsWithDiacritics[i],
        isCorrect: found,
      ));
    }

    return results;
  }

  static bool _areWordsSimilar(String word1, String word2, {bool useDiacritics = false}) {
    if (word1 == word2) return true;
    if (word1.isEmpty || word2.isEmpty) return false;
    
    final distance = _levenshtein(word1, word2);
    
    int threshold = 0;
    if (word1.length > 6) {
      threshold = 2;
    } else if (word1.length > 3) {
      threshold = 1;
    }

    // If using diacritics, the strings are much longer (diacritics count as chars).
    // We increase the threshold to allow for 1-2 vowel mistakes in longer words.
    if (useDiacritics) {
      threshold += 1;
    }
    
    return distance <= threshold;
  }

  static int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.generate(t.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[t.length];
  }
}

class ComparisonResult {
  final String word;
  final bool isCorrect;

  ComparisonResult({required this.word, required this.isCorrect});
}
