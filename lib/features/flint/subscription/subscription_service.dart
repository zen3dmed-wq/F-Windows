import '../api/flint_api_client.dart';
import 'subscription_model.dart';

class FlintSubscriptionService {
  FlintSubscriptionService(this.api);

  final FlintApiClient api;

  Future<FlintSubscription> load() async {
    final json = await api.getJson('/subscription');
    final data = json['subscription'];
    if (data is Map<String, dynamic>) {
      return FlintSubscription.fromJson(data);
    }
    return FlintSubscription.fromJson(json);
  }
}
