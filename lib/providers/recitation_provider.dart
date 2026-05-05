import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../utils/comparison_logic.dart';
import '../models/quran_models.dart';

final audioServiceProvider = Provider((ref) => AudioService());
final apiServiceProvider = Provider((ref) => ApiService());

class RecitationState {
  final bool isRecording;
  final bool isTranscribing;
  final List<ComparisonResult> results;
  final String? error;
  final List<Surah> surahs;
  final Surah? currentSurah;
  final List<Ayah> ayahs;
  final int currentAyahIndex;
  final bool isLoading;
  final String? lastTranscription;

  RecitationState({
    this.isRecording = false,
    this.isTranscribing = false,
    this.results = const [],
    this.error,
    this.surahs = const [],
    this.currentSurah,
    this.ayahs = const [],
    this.currentAyahIndex = 0,
    this.isLoading = false,
    this.lastTranscription,
  });

  RecitationState copyWith({
    bool? isRecording,
    bool? isTranscribing,
    List<ComparisonResult>? results,
    String? error,
    List<Surah>? surahs,
    Surah? currentSurah,
    List<Ayah>? ayahs,
    int? currentAyahIndex,
    bool? isLoading,
    String? lastTranscription,
  }) {
    return RecitationState(
      isRecording: isRecording ?? this.isRecording,
      isTranscribing: isTranscribing ?? this.isTranscribing,
      results: results ?? this.results,
      error: error ?? this.error,
      surahs: surahs ?? this.surahs,
      currentSurah: currentSurah ?? this.currentSurah,
      ayahs: ayahs ?? this.ayahs,
      currentAyahIndex: currentAyahIndex ?? this.currentAyahIndex,
      isLoading: isLoading ?? this.isLoading,
      lastTranscription: lastTranscription ?? this.lastTranscription,
    );
  }

  Ayah? get currentAyah {
    if (ayahs.isEmpty || currentAyahIndex < 0 || currentAyahIndex >= ayahs.length) {
      return null;
    }
    return ayahs[currentAyahIndex];
  }
}

class RecitationNotifier extends Notifier<RecitationState> {
  @override
  RecitationState build() {
    return RecitationState();
  }

  Future<void> fetchSurahs() async {
    if (state.surahs.isNotEmpty) return;
    
    state = state.copyWith(isLoading: true);
    try {
      final apiService = ref.read(apiServiceProvider);
      final surahs = await apiService.getSurahs();
      state = state.copyWith(surahs: surahs, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load surahs: $e', isLoading: false);
    }
  }

  Future<void> selectSurah(Surah surah) async {
    state = state.copyWith(
      isLoading: true, 
      currentSurah: surah, 
      currentAyahIndex: 0, 
      results: [], 
      ayahs: [],
      error: null,
      lastTranscription: null,
    );
    
    try {
      final apiService = ref.read(apiServiceProvider);
      final ayahs = await apiService.getAyahs(surah.number);
      if (ayahs.isEmpty) {
        state = state.copyWith(error: 'No ayahs found for this surah', isLoading: false);
      } else {
        state = state.copyWith(ayahs: ayahs, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(error: 'Error: $e', isLoading: false);
    }
  }

  void nextAyah() {
    if (state.currentAyahIndex < state.ayahs.length - 1) {
      state = state.copyWith(
        currentAyahIndex: state.currentAyahIndex + 1,
        results: [],
        error: null,
        lastTranscription: null,
      );
    }
  }

  void previousAyah() {
    if (state.currentAyahIndex > 0) {
      state = state.copyWith(
        currentAyahIndex: state.currentAyahIndex - 1,
        results: [],
        error: null,
        lastTranscription: null,
      );
    }
  }

  Future<void> toggleRecording() async {
    final audioService = ref.read(audioServiceProvider);
    final apiService = ref.read(apiServiceProvider);
    final currentAyah = state.currentAyah;

    if (currentAyah == null) return;

    if (state.isRecording) {
      state = state.copyWith(isRecording: false, isTranscribing: true);
      final path = await audioService.stopRecording();
      
      if (path != null) {
        final transcriptionResult = await apiService.transcribeAudio(path);
        if (transcriptionResult != null && transcriptionResult['transcription'] != null) {
          final rawTranscription = transcriptionResult['transcription'] as String;
          final results = ComparisonLogic.compare(
            currentAyah.text, 
            rawTranscription
          );
          state = state.copyWith(
            results: results, 
            isTranscribing: false,
            lastTranscription: rawTranscription,
          );
        } else {
          state = state.copyWith(
            error: 'Transcription failed', 
            isTranscribing: false
          );
        }
      } else {
        state = state.copyWith(
          error: 'Failed to save recording', 
          isTranscribing: false
        );
      }
    } else {
      final success = await audioService.startRecording();
      if (success) {
        state = state.copyWith(
          isRecording: true, 
          results: [], 
          error: null,
          lastTranscription: null,
        );
      } else {
        state = state.copyWith(error: 'Microphone permission denied');
      }
    }
  }
}

final recitationProvider = NotifierProvider<RecitationNotifier, RecitationState>(RecitationNotifier.new);
