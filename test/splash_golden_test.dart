// Golden / screenshot fixture for SplashScreen after the ARCLogo refactor.
//
// Run with:
//   flutter test --update-goldens test/splash_golden_test.dart

import 'package:arc_app/screens/splash_screen.dart';
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

  testWidgets('Splash — initial frame', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          home: const SplashScreen(),
        ),
      ),
    );
    // First frame only — don't await pumpAndSettle (loading bar repeats forever).
    await tester.pump(const Duration(milliseconds: 100));
    await expectLater(
      find.byType(SplashScreen),
      matchesGoldenFile('goldens/splash.png'),
    );
  });
}
