// Golden / screenshot fixture for SummaryScreen.
//
// Run with:
//   flutter test --update-goldens test/summary_golden_test.dart
//
// The screen exceeds 852 px tall, so we capture the natural intrinsic size
// of the body (no clipping) by setting a tall surface.

import 'package:arc_app/screens/summary_screen.dart';
import 'package:arc_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _loadFonts() async {
  Future<void> loadOne(String family, List<String> assets) async {
    final FontLoader loader = FontLoader(family);
    for (final String asset in assets) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }

  await loadOne('Inter', <String>[
    'assets/fonts/Inter-ExtraLight.ttf',
    'assets/fonts/Inter-Light.ttf',
    'assets/fonts/Inter-Regular.ttf',
    'assets/fonts/Inter-Medium.ttf',
    'assets/fonts/Inter-SemiBold.ttf',
    'assets/fonts/Inter-Bold.ttf',
  ]);
  await loadOne('JetBrainsMono', <String>[
    'assets/fonts/JetBrainsMono-Regular.ttf',
    'assets/fonts/JetBrainsMono-Medium.ttf',
  ]);
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('Summary — top of screen (above the fold)',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          home: const SummaryScreen(),
        ),
      ),
    );
    // Let the score circle's 800 ms TweenAnimationBuilder finish.
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(SummaryScreen),
      matchesGoldenFile('goldens/summary_top.png'),
    );
  });

  testWidgets('Summary — bottom of screen (below the fold)',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          home: const SummaryScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
    // Scroll the body to its bottom.
    final Finder scrollable = find.byType(Scrollable).first;
    await tester.drag(scrollable, const Offset(0, -1500));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(SummaryScreen),
      matchesGoldenFile('goldens/summary_bottom.png'),
    );
  });
}
