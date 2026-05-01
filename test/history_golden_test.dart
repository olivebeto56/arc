// Golden / screenshot fixtures for HistoryScreen.
//
// Two captures:
//   - populated: default state with the JSX-literal seed of 5 entries.
//   - empty:     `sessionHistoryProvider` overridden to an empty list to
//                show the empty-state widget.
//
// Run with:
//   flutter test --update-goldens test/history_golden_test.dart

import 'package:arc_app/models/session_summary.dart';
import 'package:arc_app/providers/history_provider.dart';
import 'package:arc_app/screens/history_screen.dart';
import 'package:arc_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _EmptyHistoryNotifier extends SessionHistoryNotifier {
  _EmptyHistoryNotifier() {
    state = const <SessionSummaryData>[];
  }
}

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

Widget _scope({
  required Widget child,
  bool empty = false,
}) {
  return ProviderScope(
    overrides: <Override>[
      if (empty)
        sessionHistoryProvider
            .overrideWith((Ref ref) => _EmptyHistoryNotifier()),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: child,
    ),
  );
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('History — populated', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(_scope(child: const HistoryScreen()));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(HistoryScreen),
      matchesGoldenFile('goldens/history_populated.png'),
    );
  });

  testWidgets('History — empty', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(_scope(child: const HistoryScreen(), empty: true));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(HistoryScreen),
      matchesGoldenFile('goldens/history_empty.png'),
    );
  });
}
