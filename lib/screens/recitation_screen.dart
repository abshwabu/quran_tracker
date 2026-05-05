import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/recitation_provider.dart';

class RecitationScreen extends ConsumerWidget {
  const RecitationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recitationProvider);
    final currentAyah = state.currentAyah;

    return Scaffold(
      appBar: AppBar(
        title: Text(state.currentSurah?.name ?? 'Recitation'),
        centerTitle: true,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (currentAyah != null) ...[
                      Text(
                        'Ayah ${currentAyah.numberInSurah} of ${state.currentSurah?.numberOfAyahs}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              currentAyah.text,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.amiri(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                    if (state.isTranscribing)
                      const CircularProgressIndicator()
                    else if (state.results.isNotEmpty)
                      _buildEvaluationView(context, state)
                    else if (state.error != null)
                      Text(
                        state.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    
                    if (state.lastTranscription != null) ...[
                      const SizedBox(height: 40),
                      Text(
                        'What we heard:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            state.lastTranscription!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.amiri(
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 80), // Space for FAB row
                  ],
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: state.currentAyahIndex > 0
                  ? () => ref.read(recitationProvider.notifier).previousAyah()
                  : null,
              icon: const Icon(Icons.skip_previous),
              iconSize: 40,
            ),
            _buildRecordButton(ref, state),
            IconButton(
              onPressed: state.currentAyahIndex < state.ayahs.length - 1
                  ? () => ref.read(recitationProvider.notifier).nextAyah()
                  : null,
              icon: const Icon(Icons.skip_next),
              iconSize: 40,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvaluationView(BuildContext context, RecitationState state) {
    return Column(
      children: [
        Text(
          'Feedback:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 20),
        Directionality(
          textDirection: TextDirection.rtl,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: state.results.map((result) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: result.isCorrect ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: result.isCorrect ? Colors.green : Colors.red,
                  ),
                ),
                child: Text(
                  result.word,
                  style: GoogleFonts.amiri(
                    fontSize: 20,
                    color: result.isCorrect ? Colors.green[900] : Colors.red[900],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordButton(WidgetRef ref, RecitationState state) {
    return FloatingActionButton.large(
      heroTag: 'record_btn',
      onPressed: state.isTranscribing
          ? null
          : () => ref.read(recitationProvider.notifier).toggleRecording(),
      backgroundColor: state.isRecording ? Colors.red : Colors.blue,
      child: Icon(
        state.isRecording ? Icons.stop : Icons.mic,
        size: 40,
        color: Colors.white,
      ),
    );
  }
}
