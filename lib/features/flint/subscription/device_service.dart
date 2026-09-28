import '../api/flint_api_client.dart';
import 'device_model.dart';

class FlintDeviceService {
  FlintDeviceService(this.api);

  final FlintApiClient api;

  Future<List<FlintDevice>> list() async {
    final json = await api.getJson('/devices');
    final raw = json['devices'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(FlintDevice.fromJson)
        .toList(growable: false);
  }
}
