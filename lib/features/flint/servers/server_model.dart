class FlintServer {
  const FlintServer({
    required this.id,
    required this.country,
    required this.name,
    required this.online,
    this.city,
    this.latencyMs,
  });

  final String id;
  final String country;
  final String name;
  final String? city;
  final bool online;
  final int? latencyMs;

  factory FlintServer.fromJson(Map<String, dynamic> json) {
    return FlintServer(
      id: (json['id'] ?? '').toString(),
      country: (json['country'] ?? '').toString(),
      name: (json['name'] ?? json['country'] ?? 'Сервер').toString(),
      city: json['city'] as String?,
      online: json['online'] != false,
      latencyMs: (json['latency'] as num?)?.toInt(),
    );
  }
}
