import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/surah_selection_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: TasmeeApp(),
    ),
  );
}

class TasmeeApp extends StatelessWidget {
  const TasmeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tasmee\'',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SurahSelectionScreen(),
    );
  }
}
