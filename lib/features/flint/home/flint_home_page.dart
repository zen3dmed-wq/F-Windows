import 'package:flutter/material.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/settings/notifier/config_option/config_option_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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
          final activeProfile = await ref.read(activeProfileProvider.future);
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
      AsyncData(value: Disconnected()) || AsyncError() => 'Подключиться',
      _ => 'Подключение…',
    };

    final guardText = switch (connectionStatus) {
      AsyncData(value: Connected()) when delay > 0 && delay < 65000 =>
        'Защищено • $delay мс',
      AsyncData(value: Connected()) => 'Защищено',
      AsyncData(value: Disconnected()) => 'Не подключено',
      AsyncError() => 'Ошибка соединения',
      _ => 'Устанавливаем соединение…',
    };

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
                const _FlintMenuTile(
                  icon: Icons.public_rounded,
                  title: 'Страна',
                  subtitle: 'Выбор сервера',
                ),
                const _FlintMenuTile(
                  icon: Icons.alt_route_rounded,
                  title: 'RU Direct',
                  subtitle: 'Белые списки',
                  badge: 'ВКЛ',
                ),
                const _FlintMenuTile(
                  icon: Icons.family_restroom_rounded,
                  title: 'Семейная подписка',
                  subtitle: 'Устройства 0 / 3',
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
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: badge == null
            ? const Icon(Icons.chevron_right_rounded)
            : Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer,
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
      ),
    );
  }
}
