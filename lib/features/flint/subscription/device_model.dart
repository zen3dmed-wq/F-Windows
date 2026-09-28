class FlintDevice {
  const FlintDevice({
    required this.id,
    required this.name,
    required this.platform,
    required this.active,
    this.current = false,
  });

  final String id;
  final String name;
  final String platform;
  final bool active;
  final bool current;

  factory FlintDevice.fromJson(Map<String, dynamic> json) {
    return FlintDevice(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Устройство').toString(),
      platform: (json['platform'] ?? '').toString(),
      active: json['active'] != false,
      current: json['current'] == true,
    );
  }
}
