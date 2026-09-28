enum FlintGuardStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

class FlintGuardState {
  const FlintGuardState({
    required this.status,
    this.serverName,
    this.latencyMs,
    this.message,
  });

  final FlintGuardStatus status;
  final String? serverName;
  final int? latencyMs;
  final String? message;

  bool get isProtected => status == FlintGuardStatus.connected;
}
