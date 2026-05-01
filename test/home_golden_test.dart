// Golden tests / screenshot fixtures for HomeScreen (literal Home A).
//
// Run with:
//   flutter test --update-goldens test/home_golden_test.dart

import 'package:arc_app/models/band_state.dart';
import 'package:arc_app/providers/band_providers.dart';
import 'package:arc_app/screens/home_screen.dart';
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

class _StaticBandNotifier extends BandNotifier {
  _StaticBandNotifier(BandState initial)
      : super(
          initial,
          const BandMockProgression(
            startDelay: Duration.zero,
            searchRssi: -65,
            foundRssi: -60,
            connectedRssi: -58,
            battery: 87,
          ),
        );

  @override
  void start() {
    // No-op: golden fixtures stay frozen on the initial state.
  }
}

ProviderScope _scope({required Widget child}) {
  return ProviderScope(
    overrides: <Override>[
      leftBandProvider.overrideWith(
        (Ref ref) => _StaticBandNotifier(_connectedLeft),
      ),
      rightBandProvider.overrideWith(
        (Ref ref) => _StaticBandNotifier(_connectedRight),
      ),
    ],
    child: child,
  );
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

void main() {
  setUpAll(_loadFonts);

  testWidgets('Home A — full', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(
      _scope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('goldens/home_a.png'),
    );
  });
}
