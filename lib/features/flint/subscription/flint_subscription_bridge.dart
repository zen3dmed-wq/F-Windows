import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../api/flint_backend_api.dart';
import 'backend_subscription.dart';

class FlintSubscriptionBridge {
  FlintSubscriptionBridge(this.api);

  final FlintBackendApi api;

  Future<List<FlintBackendSubscription>> loadSubscriptions() async {
    final raw = await api.getAny('/api/v1/subscriptions');

    final List<dynamic> items;
    if (raw is List) {
      items = raw;
    } else if (raw is Map) {
      final value = raw['subscriptions'] ?? raw['items'] ?? raw['data'];
      if (value is List) {
        items = value;
      } else {
        items = [raw];
      }
    } else {
      items = const [];
    }

    return items
        .whereType<Map>()
        .map(
          (e) => FlintBackendSubscription.fromJson(
            e.map((k, v) => MapEntry(k.toString(), v)),
          ),
        )
        .toList(growable: false);
  }

  Future<FlintBackendSubscription?> loadActiveSubscription() async {
    final subscriptions = await loadSubscriptions();

    for (final item in subscriptions) {
      if (item.active && item.subscriptionUrl.trim().isNotEmpty) {
        return item;
      }
    }

    for (final item in subscriptions) {
      if (item.subscriptionUrl.trim().isNotEmpty) {
        return item;
      }
    }

    return null;
  }

  Future<void> installActiveSubscription(WidgetRef ref) async {
    final subscription = await loadActiveSubscription();

    if (subscription == null) {
      throw FlintBackendException(
        'Активная подписка с subscriptionUrl не найдена',
      );
    }

    await ref.read(addProfileNotifierProvider.notifier).addManual(
          url: subscription.subscriptionUrl.trim(),
          userOverride: UserOverride(
            name: subscription.tariff?.trim().isNotEmpty == true
                ? 'Flint ${subscription.tariff}'
                : 'Flint',
          ),
        );

    final result = ref.read(addProfileNotifierProvider);
    if (result.hasError) {
      throw FlintBackendException(
        'Hiddify не смог добавить подписку: ${result.error}',
      );
    }
  }
}
