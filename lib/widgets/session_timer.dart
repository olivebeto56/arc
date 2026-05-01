// from: design/design_handoff_arc_app/design/screens/screens-live.jsx
//        (ScreenDashboardB hero timer)

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/session_providers.dart';
import '../theme/app_text.dart';

/// Big mono-style countdown of the active session.
///
/// Subscribes only to `sessionTimerProvider` so the rest of the screen
/// doesn't rebuild on every 1 s tick.
///
/// Format:
///  - `MM:SS` while elapsed < 1 h
///  - `H:MM:SS` once elapsed crosses the hour mark
class SessionTimer extends ConsumerWidget {
  const SessionTimer({
    super.key,
    this.style,
  });

  /// Override the default `AppText.display2` style — useful for Dashboard A
  /// (uses `display3 = 64`).
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Duration elapsed = ref.watch(sessionTimerProvider);
    return Text(_format(elapsed), style: style ?? AppText.display2);
  }

  static String _format(Duration d) {
    final int totalSeconds = d.inSeconds;
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds ~/ 60) % 60;
    final int seconds = totalSeconds % 60;
    final String mm = minutes.toString().padLeft(2, '0');
    final String ss = seconds.toString().padLeft(2, '0');
    if (hours == 0) return '$mm:$ss';
    return '$hours:$mm:$ss';
  }
}
