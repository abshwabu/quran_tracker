import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/recitation_provider.dart';
import 'recitation_screen.dart';

class SurahSelectionScreen extends ConsumerWidget {
  const SurahSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recitationProvider);

    // Fetch surahs if list is empty
    if (state.surahs.isEmpty && !state.isLoading) {
      Future.microtask(() => ref.read(recitationProvider.notifier).fetchSurahs());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Surah'),
        centerTitle: true,
      ),
      body: state.isLoading && state.surahs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: state.surahs.length,
              itemBuilder: (context, index) {
                final surah = state.surahs[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(surah.number.toString()),
                  ),
                  title: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      surah.name,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.amiri(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  subtitle: Text('${surah.englishName} (${surah.numberOfAyahs} Ayahs)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ref.read(recitationProvider.notifier).selectSurah(surah);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RecitationScreen(),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
