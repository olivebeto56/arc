/// Lifecycle of a running session as seen by the Dashboard screen.
enum SessionStatus {
  /// Pre-start. Timer at 00:00, no metrics streaming.
  idle,

  /// Active session — timer ticks, metrics stream.
  running,

  /// Active session held — timer frozen, metrics frozen.
  paused,

  /// Session ended — Summary screen takes over from here.
  stopped,
}
