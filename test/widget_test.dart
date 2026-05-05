import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_tracker/main.dart';
import 'package:quran_tracker/providers/recitation_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recitationProvider.overrideWith(() => MockRecitationNotifier()),
        ],
        child: const TasmeeApp(),
      ),
    );

    // Verify that the app title is present
    expect(find.text('Select Surah'), findsOneWidget);
  });
}

class MockRecitationNotifier extends RecitationNotifier {
  @override
  RecitationState build() {
    return RecitationState(
      surahs: [],
      isLoading: false,
    );
  }

  @override
  Future<void> fetchSurahs() async {}
}
