import '../api/flint_backend_api.dart';

class FlintSession {
  const FlintSession({
    required this.id,
    required this.name,
    this.platform,
    this.current = false,
  });

  final String id;
  final String name;
  final String? platform;
  final bool current;

  factory FlintSession.fromJson(Map<String, dynamic> json) {
    return FlintSession(
      id: (json['id'] ?? json['sessionId'] ?? '').toString(),
      name: (json['deviceName'] ??
              json['name'] ??
              json['device'] ??
              'Устройство')
          .toString(),
      platform: (json['platform'] ?? json['os'])?.toString(),
      current: json['current'] == true || json['isCurrent'] == true,
    );
  }
}

class FlintSessionsService {
  FlintSessionsService(this.api);

  final FlintBackendApi api;

  Future<List<FlintSession>> load() async {
    final raw = await api.getAny('/api/v1/me/sessions');

    final dynamic value = raw is Map
        ? (raw['sessions'] ?? raw['items'] ?? raw['data'])
        : raw;

    if (value is! List) return const [];

    return value
        .whereType<Map>()
        .map(
          (e) => FlintSession.fromJson(
            e.map((k, v) => MapEntry(k.toString(), v)),
          ),
        )
        .toList(growable: false);
  }
}
