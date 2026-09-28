class FlintBackendSubscription {
  const FlintBackendSubscription({
    required this.id,
    required this.active,
    required this.subscriptionUrl,
    this.status,
    this.tariff,
    this.expiresAt,
    this.usedBytes,
    this.limitBytes,
  });

  final String id;
  final bool active;
  final String subscriptionUrl;
  final String? status;
  final String? tariff;
  final DateTime? expiresAt;
  final int? usedBytes;
  final int? limitBytes;

  factory FlintBackendSubscription.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString();
    final activeValue = json['active'];
    final traffic = json['traffic'];

    int? usedBytes;
    int? limitBytes;
    if (traffic is Map) {
      usedBytes = _asInt(traffic['usedBytes'] ?? traffic['used_bytes']);
      limitBytes = _asInt(traffic['limitBytes'] ?? traffic['limit_bytes']);
    }

    return FlintBackendSubscription(
      id: (json['id'] ?? '').toString(),
      active: activeValue is bool
          ? activeValue
          : const {'active', 'enabled', 'trialing'}
              .contains((status ?? '').toLowerCase()),
      subscriptionUrl:
          (json['subscriptionUrl'] ?? json['subscription_url'] ?? '')
              .toString(),
      status: status,
      tariff: (json['tariff'] ?? json['plan'] ?? json['planName'])
          ?.toString(),
      expiresAt: _asDate(
        json['expiresAt'] ??
            json['expires_at'] ??
            json['expiry'] ??
            json['expires'],
      ),
      usedBytes: usedBytes,
      limitBytes: limitBytes,
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static DateTime? _asDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
