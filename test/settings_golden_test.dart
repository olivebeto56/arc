// Golden / screenshot fixture for SettingsScreen.
//
// Run with:
//   flutter test --update-goldens test/settings_golden_test.dart

import 'package:arc_app/models/band_state.dart';
import 'package:arc_app/providers/band_providers.dart';
import 'package:arc_app/screens/settings_screen.dart';
import 'package:arc_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const BandState _connectedLeft = BandState(
  nodeId: 'LEFT_ANKLE',
  name: 'SportBand-L',
  status: BandStatus.connected,
  mac: 'A4:C1:38:7B:21',
  rssi: -58,
  battery: 87,
);

const BandState _connectedRight = BandState(
  nodeId: 'RIGHT_ANKLE',
  name: 'SportBand-R',
  status: BandStatus.connected,
  mac: 'A4:C1:38:7B:9F',
  rssi: -65,
  battery: 92,
);

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

ProviderScope _scope({required Widget child}) {
  return ProviderScope(
    overrides: <Override>[
      leftBandProvider.overrideWithValue(_connectedLeft),
      rightBandProvider.overrideWithValue(_connectedRight),
    ],
    child: child,
  );
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('Settings — top of screen', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(
      _scope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(SettingsScreen),
      matchesGoldenFile('goldens/settings_top.png'),
    );
  });

  testWidgets('Settings — bottom of screen', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(
      _scope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final Finder scrollable = find.byType(Scrollable).first;
    await tester.drag(scrollable, const Offset(0, -1500));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(SettingsScreen),
      matchesGoldenFile('goldens/settings_bottom.png'),
    );
  });
}
