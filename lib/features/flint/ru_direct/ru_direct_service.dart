import '../api/flint_api_client.dart';

class RuDirectSnapshot {
  const RuDirectSnapshot({
    required this.version,
    required this.domains,
  });

  final String version;
  final List<String> domains;
}

class RuDirectService {
  RuDirectService(this.api);
  final FlintApiClient api;

  Future<RuDirectSnapshot> download() async {
    final json = await api.getJson('/ru-direct/list');

    final version = (json['version'] ?? 'unknown').toString();
    final raw = json['domains'];

    if (raw is! List) {
      throw StateError('API /ru-direct/list не вернул массив domains');
    }

    final domains = raw
        .whereType<String>()
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList(growable: false);

    return RuDirectSnapshot(version: version, domains: domains);
  }
}
