// Golden tests / screenshot fixtures for ScreenDashboardB.
//
// Run with:
//   flutter test --update-goldens test/dashboard_golden_test.dart

import 'package:arc_app/models/band_state.dart';
import 'package:arc_app/models/live_metrics.dart';
import 'package:arc_app/models/session_status.dart';
import 'package:arc_app/providers/band_providers.dart';
import 'package:arc_app/providers/session_providers.dart';
import 'package:arc_app/screens/dashboard_screen.dart';
import 'package:arc_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const BandState _connectedLeft = BandState(
  chipId: 'A4C1',
  nodeId: 'LEFT_ANKLE',
  name: 'SportBand-A4C1',
  status: BandStatus.connected,
  mac: 'A4:C1:38:7B:21',
  rssi: -58,
  battery: 84,
);

const BandState _connectedRight = BandState(
  chipId: 'A47B',
  nodeId: 'RIGHT_ANKLE',
  name: 'SportBand-A47B',
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
  _StaticMetricsNotifier({required bool warning}) {
    state = LiveMetrics(
      cadenceSpm: 178,
      symmetryLeftPct: warning ? 48 : 50,
      gctMs: 231,
      impactLoad: 12.4,
      strikeAngle: 6.2,
      variability: 4.8,
      symmetryWarning: warning,
      warningCycleId: warning ? 1 : 0,
    );
  }

  @override
  void start() {}

  @override
  void pause() {}
}

ProviderScope _scope({
  required bool recommendationVisible,
  required Widget child,
}) {
  return ProviderScope(
    overrides: <Override>[
      leftBandProvider.overrideWithValue(_connectedLeft),
      rightBandProvider.overrideWithValue(_connectedRight),
      sessionTimerProvider.overrideWith(
        (Ref ref) => _StaticTimerNotifier(),
      ),
      liveMetricsProvider.overrideWith(
        (Ref ref) => _StaticMetricsNotifier(warning: recommendationVisible),
      ),
      sessionStatusProvider.overrideWith(
        (Ref ref) => SessionStatus.running,
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

  Future<void> render(
    WidgetTester tester, {
    required bool recommendation,
  }) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(
      _scope(
        recommendationVisible: recommendation,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          home: const DashboardScreen(),
        ),
      ),
    );
    // The post-frame callback in DashboardScreen would normally start the
    // tickers; our overrides no-op start(), but we still pump once to let
    // it settle.
    await tester.pumpAndSettle();
  }

  testWidgets('Dashboard B — running, all OK', (WidgetTester tester) async {
    await render(tester, recommendation: false);
    await expectLater(
      find.byType(DashboardScreen),
      matchesGoldenFile('goldens/dashboard_b_running.png'),
    );
  });

  testWidgets('Dashboard B — recommendation visible',
      (WidgetTester tester) async {
    await render(tester, recommendation: true);
    await expectLater(
      find.byType(DashboardScreen),
      matchesGoldenFile('goldens/dashboard_b_recommendation.png'),
    );
  });
}
