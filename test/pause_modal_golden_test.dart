// Golden / screenshot fixture for PauseModal mounted on top of Dashboard.
//
// We render `PauseModalContent` directly as a Stack child rather than going
// through `PauseModalRoute`. The route animation drops the screenshot mid-
// transition; rendering the static content gives the post-settle state.
//
// Run with:
//   flutter test --update-goldens test/pause_modal_golden_test.dart

import 'package:arc_app/models/band_state.dart';
import 'package:arc_app/models/live_metrics.dart';
import 'package:arc_app/models/session_status.dart';
import 'package:arc_app/providers/band_providers.dart';
import 'package:arc_app/providers/session_providers.dart';
import 'package:arc_app/screens/dashboard/widgets/pause_modal.dart';
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
  battery: 84,
);

const BandState _connectedRight = BandState(
  nodeId: 'RIGHT_ANKLE',
  name: 'SportBand-R',
  status: BandStatus.connected,
  mac: 'A4:C1:38:7B:9F',
  rssi: -65,
  battery: 89,
);

class _StaticTimerNotifier extends SessionTimerNotifier {
  _StaticTimerNotifier() {
    state = const Duration(minutes: 28, seconds: 43);
  }
  @override
  void start() {}
  @override
  void pause() {}
  @override
  void reset() {}
}

class _StaticMetricsNotifier extends LiveMetricsNotifier {
  _StaticMetricsNotifier() {
    state = const LiveMetrics(
      cadenceSpm: 178,
      symmetryLeftPct: 49,
      gctMs: 231,
      impactLoad: 12.4,
      strikeAngle: 6.2,
      variability: 4.8,
      symmetryWarning: false,
      warningCycleId: 0,
    );
  }
  @override
  void start() {}
  @override
  void pause() {}
}

ProviderScope _scope({required Widget child}) {
  return ProviderScope(
    overrides: <Override>[
      leftBandProvider.overrideWithValue(_connectedLeft),
      rightBandProvider.overrideWithValue(_connectedRight),
      sessionTimerProvider.overrideWith((Ref ref) => _StaticTimerNotifier()),
      liveMetricsProvider.overrideWith((Ref ref) => _StaticMetricsNotifier()),
      sessionStatusProvider.overrideWith((Ref ref) => SessionStatus.paused),
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

  testWidgets('Pause modal — rendered over Dashboard B',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));

    await tester.pumpWidget(
      _scope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          home: const Scaffold(
            backgroundColor: Color(0xFF0A0A0A),
            body: PauseModalContent(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/pause_modal.png'),
    );
  });
}
