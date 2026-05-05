import 'dart:math';

class ComparisonLogic {
  /// Normalizes Arabic text by removing diacritics and standardizing characters.
  static String normalize(String text) {
    if (text.isEmpty) return "";

    // 1. Remove all diacritics (Tashkeel)
    // Range: \u064B to \u065F (includes Fathah, Dammah, Kasrah, Sukun, Shaddah, etc.)
    // Also include Quranic marks (\u06D6-\u06ED)
    final diacritics = RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]');
    String normalized = text.replaceAll(diacritics, '');

    // 2. Normalize Alif forms
    // أ (Alif with Hamza Above), إ (Alif with Hamza Below), آ (Alif with Madda), ٱ (Alif Wasla) -> ا (Plain Alif)
    normalized = normalized.replaceAll(RegExp(r'[أإآٱ]'), 'ا');

    // 3. Normalize Teh Marbuta to Heh
    normalized = normalized.replaceAll('ة', 'ه');

    // 4. Normalize Ya forms
    // ى (Alif Maksura), ی (Persian Ya) -> ي (Standard Ya)
    normalized = normalized.replaceAll(RegExp(r'[ىی]'), 'ي');

    // 5. Normalize Kaf forms
    // ک (Persian Kaf) -> ك (Standard Kaf)
    normalized = normalized.replaceAll('ک', 'ك');

    // 6. Remove any remaining non-Arabic-letter characters (except spaces)
    // We keep basic Arabic letters \u0621-\u064A and common extensions
    normalized = normalized.replaceAll(RegExp(r'[^\u0621-\u064A\s]'), '');
    
    // 7. Condense multiple spaces into one
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');
    
    return normalized.trim();
  }

  /// Compares two strings and returns a list of word-by-word feedback.
  static List<ComparisonResult> compare(String original, String transcribed) {
    // Trim and normalize transcription
    final normalizedTranscribed = normalize(transcribed);
    final transcribedWords = normalizedTranscribed
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    // Original words with diacritics for display
    final originalWordsWithDiacritics = original
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    List<ComparisonResult> results = [];
    
    // We use a search window to find the word in the transcription
    int lastFoundIndex = -1;

    for (int i = 0; i < originalWordsWithDiacritics.length; i++) {
      final displayWord = originalWordsWithDiacritics[i];
      final targetWord = normalize(displayWord);

      bool isCorrect = false;

      // Look ahead in the transcribed words within a window
      // We'll use a slightly larger window (5 words) to be safe
      int searchStart = max(0, lastFoundIndex + 1);
      int searchEnd = min(transcribedWords.length, searchStart + 5);

      for (int j = searchStart; j < searchEnd; j++) {
        if (_areWordsSimilar(targetWord, transcribedWords[j])) {
          isCorrect = true;
          lastFoundIndex = j;
          break;
        }
      }

      results.add(ComparisonResult(
        word: displayWord,
        isCorrect: isCorrect,
      ));
    }

    return results;
  }

  static bool _areWordsSimilar(String word1, String word2) {
    if (word1 == word2) return true;
    if (word1.isEmpty || word2.isEmpty) return false;
    
    final distance = _levenshtein(word1, word2);
    
    // Threshold calculation:
    // - Short words (1-3 chars): must match exactly
    // - Medium words (4-6 chars): 1 char difference allowed
    // - Long words (7+ chars): 2 chars difference allowed
    int threshold = 0;
    if (word1.length > 6) {
      threshold = 2;
    } else if (word1.length > 3) {
      threshold = 1;
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
