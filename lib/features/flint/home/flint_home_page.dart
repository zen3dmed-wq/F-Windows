import 'package:flutter/material.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/settings/notifier/config_option/config_option_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../api/flint_backend_api.dart';
import '../flint_config.dart';
import '../ru_direct/flint_ru_direct_bridge.dart';
import '../subscription/backend_subscription.dart';
import '../subscription/flint_sessions_service.dart';
import '../subscription/flint_subscription_bridge.dart';

class FlintHomePage extends HookConsumerWidget {
  const FlintHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final connectionStatus = ref.watch(connectionNotifierProvider);
    final activeProxy = ref.watch(activeProxyNotifierProvider);
    final delay = activeProxy.valueOrNull?.urlTestDelay ?? 0;
    final requiresReconnect =
        ref.watch(configOptionNotifierProvider).valueOrNull;

    final api = FlintBackendApi();
    final subscriptionBridge = FlintSubscriptionBridge(api);
    final sessionsService = FlintSessionsService(api);
    final ruDirect = FlintRuDirectBridge(api);

    final isConnected = switch (connectionStatus) {
      AsyncData(value: Connected()) => true,
      _ => false,
    };

    final isDisconnected = switch (connectionStatus) {
      AsyncData(value: Disconnected()) || AsyncError() => true,
      _ => false,
    };

    final isBusy = !isConnected && !isDisconnected;

    Future<void> handleConnection() async {
      switch (connectionStatus) {
        case AsyncData(value: Connected()) when requiresReconnect == true:
          final activeProfile =
              await ref.read(activeProfileProvider.future);
          await ref
              .read(connectionNotifierProvider.notifier)
              .reconnect(activeProfile);

        case AsyncData(value: Disconnected()) || AsyncError():
          if (ref.read(activeProfileProvider).valueOrNull == null) {
            await ref
                .read(dialogNotifierProvider.notifier)
                .showNoActiveProfile();
            ref
                .read(bottomSheetsNotifierProvider.notifier)
                .showAddProfile();
            return;
          }

          if (await ref
              .read(dialogNotifierProvider.notifier)
              .showExperimentalFeatureNotice()) {
            await ref
                .read(connectionNotifierProvider.notifier)
                .toggleConnection();
          }

        case AsyncData(value: Connected()):
          await ref
              .read(connectionNotifierProvider.notifier)
              .toggleConnection();

        default:
          break;
      }
    }

    final statusText = switch (connectionStatus) {
      AsyncData(value: Connected()) when requiresReconnect == true =>
        'Требуется переподключение',
      AsyncData(value: Connected()) => 'Вы защищены',
      AsyncData(value: Disconnected()) => 'Вы не защищены',
      AsyncError() => 'Ошибка подключения',
      _ => 'Подключение…',
    };

    final buttonText = switch (connectionStatus) {
      AsyncData(value: Connected()) when requiresReconnect == true =>
        'Переподключить',
      AsyncData(value: Connected()) => 'Отключиться',
      AsyncData(value: Disconnected()) || AsyncError() =>
        'Подключиться',
      _ => 'Подключение…',
    };

    final guardText = switch (connectionStatus) {
      AsyncData(value: Connected())
          when delay > 0 && delay < 65000 =>
        'Защищено • $delay мс',
      AsyncData(value: Connected()) => 'Защищено',
      AsyncData(value: Disconnected()) => 'Не подключено',
      AsyncError() => 'Ошибка соединения',
      _ => 'Устанавливаем соединение…',
    };

    Future<void> showApiNotConfigured() async {
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('Flint API не настроен'),
          content: Text(
            'Для тестовой сборки задайте '
            'FLINT_API_BASE_URL и FLINT_API_TOKEN.',
          ),
        ),
      );
    }

    Future<void> installSubscription() async {
      if (!FlintConfig.apiConfigured) {
        await showApiNotConfigured();
        return;
      }

      try {
        await subscriptionBridge.installActiveSubscription(ref);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Подписка Flint передана в Hiddify.',
            ),
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка подписки: $e')),
        );
      }
    }

    Future<void> toggleRuDirect() async {
      if (!FlintConfig.apiConfigured &&
          ruDirect.currentDomainCount(ref) == 0) {
        await showApiNotConfigured();
        return;
      }

      final currentlyEnabled = ruDirect.isEnabled(ref);

      try {
        if (currentlyEnabled) {
          await ruDirect.setEnabled(ref, false);
        } else {
          await ruDirect.setEnabled(ref, true);
        }

        if (context.mounted) {
          (context as Element).markNeedsBuild();
        }
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('RU Direct: $e')),
        );
      }
    }

    Future<void> refreshRuDirect() async {
      if (!FlintConfig.apiConfigured) {
        await showApiNotConfigured();
        return;
      }

      try {
        final snapshot = await ruDirect.refreshAndApply(ref);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'RU Direct обновлён: ${snapshot.domains.length} доменов',
            ),
          ),
        );
        (context as Element).markNeedsBuild();
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось обновить RU Direct: $e')),
        );
      }
    }

    final ruEnabled = ruDirect.isEnabled(ref);
    final ruCount = ruDirect.currentDomainCount(ref);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              children: [
                Text(
                  'Flint',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ваша приватность в надежных лапах',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 36),

                Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 116,
                    height: 116,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isConnected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                    ),
                    child: Icon(
                      isConnected
                          ? Icons.verified_user_rounded
                          : Icons.shield_outlined,
                      size: 58,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                Text(
                  statusText,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  height: 58,
                  child: FilledButton(
                    onPressed: isBusy ? null : handleConnection,
                    child: Text(buttonText),
                  ),
                ),
                const SizedBox(height: 14),

                _GuardCard(
                  connected: isConnected,
                  busy: isBusy,
                  text: guardText,
                ),
                const SizedBox(height: 18),

                FutureBuilder<FlintBackendSubscription?>(
                  future: FlintConfig.apiConfigured
                      ? subscriptionBridge.loadActiveSubscription()
                      : null,
                  builder: (context, snapshot) {
                    final sub = snapshot.data;
                    return _FlintMenuTile(
                      icon: Icons.workspace_premium_rounded,
                      title: 'Подписка',
                      subtitle: !FlintConfig.apiConfigured
                          ? 'API не настроен'
                          : sub == null
                              ? 'Нажмите для загрузки'
                              : _subscriptionText(sub),
                      onTap: installSubscription,
                    );
                  },
                ),

                _FlintMenuTile(
                  icon: Icons.public_rounded,
                  title: 'Страна',
                  subtitle: 'Используется активный профиль Hiddify',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Выбор страны через proxy selector '
                          'подключим следующим пакетом.',
                        ),
                      ),
                    );
                  },
                ),

                _FlintMenuTile(
                  icon: Icons.alt_route_rounded,
                  title: 'RU Direct',
                  subtitle: ruCount > 0
                      ? '$ruCount доменов'
                      : 'Белые списки',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Обновить',
                        onPressed: refreshRuDirect,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                      Switch(
                        value: ruEnabled,
                        onChanged: (_) => toggleRuDirect(),
                      ),
                    ],
                  ),
                  onTap: refreshRuDirect,
                ),

                FutureBuilder<List<FlintSession>>(
                  future: FlintConfig.apiConfigured
                      ? sessionsService.load()
                      : null,
                  builder: (context, snapshot) {
                    final count = snapshot.data?.length ?? 0;
                    return _FlintMenuTile(
                      icon: Icons.family_restroom_rounded,
                      title: 'Семейная подписка',
                      subtitle: FlintConfig.apiConfigured
                          ? 'Устройства $count / 3'
                          : 'API не настроен',
                      onTap: () {},
                    );
                  },
                ),

                const _FlintMenuTile(
                  icon: Icons.support_agent_rounded,
                  title: 'Онлайн поддержка',
                  subtitle: 'Помощь и ответы',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _subscriptionText(FlintBackendSubscription sub) {
    final tariff = sub.tariff?.trim();
    final expires = sub.expiresAt;

    final parts = <String>[
      if (tariff != null && tariff.isNotEmpty) tariff,
      if (expires != null)
        'до ${expires.day.toString().padLeft(2, '0')}.'
            '${expires.month.toString().padLeft(2, '0')}.'
            '${expires.year}',
    ];

    return parts.isEmpty ? 'Активна' : parts.join(' • ');
  }
}

class _GuardCard extends StatelessWidget {
  const _GuardCard({
    required this.connected,
    required this.busy,
    required this.text,
  });

  final bool connected;
  final bool busy;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (busy)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            else
              Icon(
                connected
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                size: 22,
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Flint Guard',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(text),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlintMenuTile extends StatelessWidget {
  const _FlintMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing:
            trailing ?? const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
