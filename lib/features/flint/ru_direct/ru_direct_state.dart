class RuDirectState {
  const RuDirectState({
    required this.enabled,
    required this.domainCount,
    this.updatedAt,
    this.lastError,
  });

  final bool enabled;
  final int domainCount;
  final DateTime? updatedAt;
  final String? lastError;

  RuDirectState copyWith({
    bool? enabled,
    int? domainCount,
    DateTime? updatedAt,
    String? lastError,
    bool clearError = false,
  }) {
    return RuDirectState(
      enabled: enabled ?? this.enabled,
      domainCount: domainCount ?? this.domainCount,
      updatedAt: updatedAt ?? this.updatedAt,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}
