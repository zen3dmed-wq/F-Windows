import '../api/flint_api_client.dart';
import 'server_model.dart';

class FlintServerService {
  FlintServerService(this.api);

  final FlintApiClient api;

  Future<List<FlintServer>> list() async {
    final json = await api.getJson('/servers');
    final raw = json['servers'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(FlintServer.fromJson)
        .toList(growable: false);
  }
}
