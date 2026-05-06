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
    final normalizedTranscribed = normalize(transcribed);
    final transcribedWords = normalizedTranscribed
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    final originalWordsWithDiacritics = original
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
        
    final normalizedOriginalWords = originalWordsWithDiacritics
        .map((w) => normalize(w))
        .toList();

    // Use a basic alignment approach: 
    // For each word in original, find the best match in the transcribed words
    // but keep track of the progress to avoid backward matching.
    
    List<ComparisonResult> results = [];
    int currentTranscribedIdx = 0;

    for (int i = 0; i < originalWordsWithDiacritics.length; i++) {
      final target = normalizedOriginalWords[i];
      bool found = false;
      
      // Search window: allow looking ahead to find the word
      // if the user skipped something or the transcription added noise.
      // We look ahead up to 8 words to handle moderate skips.
      int lookAheadLimit = min(currentTranscribedIdx + 8, transcribedWords.length);
      
      for (int j = currentTranscribedIdx; j < lookAheadLimit; j++) {
        if (_areWordsSimilar(target, transcribedWords[j])) {
          found = true;
          currentTranscribedIdx = j + 1; // Advance pointer
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
