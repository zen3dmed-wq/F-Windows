class FlintSubscription {
  const FlintSubscription({
    required this.active,
    required this.maxDevices,
    required this.devices,
    this.expiresAt,
    this.planName,
  });

  final bool active;
  final int maxDevices;
  final int devices;
  final DateTime? expiresAt;
  final String? planName;

  int get freeSlots => (maxDevices - devices).clamp(0, maxDevices);

  factory FlintSubscription.fromJson(Map<String, dynamic> json) {
    return FlintSubscription(
      active: json['active'] == true,
      maxDevices: (json['max_devices'] as num?)?.toInt() ?? 1,
      devices: (json['devices'] as num?)?.toInt() ?? 0,
      expiresAt: json['expires_at'] is String
          ? DateTime.tryParse(json['expires_at'] as String)
          : null,
      planName: json['plan_name'] as String?,
    );
  }
}
