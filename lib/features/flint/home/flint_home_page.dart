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
    final connectionStatus = ref.watch(connectionNotifierProvider);
    final activeProxy = ref.watch(activeProxyNotifierProvider);
    final delay = activeProxy.valueOrNull?.urlTestDelay ?? 0;
    final requiresReconnect = ref.watch(configOptionNotifierProvider).valueOrNull;

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
          final activeProfile = await ref.read(activeProfileProvider.future);
          await ref.read(connectionNotifierProvider.notifier).reconnect(activeProfile);
        case AsyncData(value: Disconnected()) || AsyncError():
          if (ref.read(activeProfileProvider).valueOrNull == null) {
            ref.read(bottomSheetsNotifierProvider.notifier).showProfilesOverview();
            return;
          }
          if (await ref.read(dialogNotifierProvider.notifier).showExperimentalFeatureNotice()) {
            await ref.read(connectionNotifierProvider.notifier).toggleConnection();
          }
        case AsyncData(value: Connected()):
          await ref.read(connectionNotifierProvider.notifier).toggleConnection();
        default:
          break;
      }
    }

    Future<void> showApiNotConfigured() async {
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('Flint API не настроен'),
          content: Text('Подключите адрес API и токен для подписки и белых списков.'),
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
          const SnackBar(content: Text('Подписка Flint обновлена')),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка подписки: $e')),
        );
      }
    }

    Future<void> toggleRuDirect() async {
      if (!FlintConfig.apiConfigured && ruDirect.currentDomainCount(ref) == 0) {
        await showApiNotConfigured();
        return;
      }
      try {
        await ruDirect.setEnabled(ref, !ruDirect.isEnabled(ref));
        if (context.mounted) (context as Element).markNeedsBuild();
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
          SnackBar(content: Text('Белый список обновлён: ${snapshot.domains.length} доменов')),
        );
        (context as Element).markNeedsBuild();
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось обновить список: $e')),
        );
      }
    }

    final statusText = switch (connectionStatus) {
      AsyncData(value: Connected()) when requiresReconnect == true => 'Нужно переподключиться',
      AsyncData(value: Connected()) => 'Вы защищены',
      AsyncData(value: Disconnected()) => 'Вы не защищены',
      AsyncError() => 'Ошибка подключения',
      _ => 'Подключаемся…',
    };

    final buttonText = switch (connectionStatus) {
      AsyncData(value: Connected()) when requiresReconnect == true => 'Переподключить',
      AsyncData(value: Connected()) => 'Отключиться',
      AsyncData(value: Disconnected()) || AsyncError() => 'Подключиться',
      _ => 'Подключение…',
    };

    final guardText = switch (connectionStatus) {
      AsyncData(value: Connected()) when delay > 0 && delay < 65000 => 'Защищено · $delay мс',
      AsyncData(value: Connected()) => 'Защищено',
      AsyncData(value: Disconnected()) => 'Не подключено',
      AsyncError() => 'Ошибка соединения',
      _ => 'Устанавливаем соединение…',
    };

    final ruEnabled = ruDirect.isEnabled(ref);
    final ruCount = ruDirect.currentDomainCount(ref);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF07111F), Color(0xFF0D2038)],
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(34, 28, 34, 34),
          children: [
            const Row(
              children: [
                Text(
                  'Flint',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .3,
                  ),
                ),
                Spacer(),
                _MiniBadge(icon: Icons.people_alt_rounded, text: 'Семья 0/3'),
                SizedBox(width: 10),
                _MiniBadge(icon: Icons.shield_rounded, text: 'Flint Guard'),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Ваша приватность в надежных лапах',
              style: TextStyle(color: Color(0xFF8391A7), fontSize: 14),
            ),
            const SizedBox(height: 30),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  children: [
                    Container(
                      width: 126,
                      height: 126,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isConnected ? const Color(0xFF143E72) : const Color(0xFF111F31),
                        border: Border.all(
                          color: isConnected ? const Color(0xFF4A9BFF) : const Color(0xFF26384F),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isConnected ? const Color(0x334A9BFF) : Colors.transparent,
                            blurRadius: 28,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: Icon(
                        isConnected ? Icons.shield_rounded : Icons.shield_outlined,
                        color: isConnected ? const Color(0xFF69A8FF) : const Color(0xFF8391A7),
                        size: 58,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      statusText,
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 360,
                      height: 58,
                      child: FilledButton(
                        onPressed: isBusy ? null : handleConnection,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1F6FEB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        child: Text(buttonText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 760;
                final cardWidth = wide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: _FlintCard(
                        icon: Icons.shield_outlined,
                        title: 'Flint Guard',
                        subtitle: guardText,
                        accent: isConnected,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _FlintCard(
                        icon: Icons.public_rounded,
                        title: 'Страна',
                        subtitle: 'Выбрать сервер',
                        onTap: () => ref.read(bottomSheetsNotifierProvider.notifier).showProfilesOverview(),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _FlintCard(
                        icon: Icons.alt_route_rounded,
                        title: 'RU Direct',
                        subtitle: ruCount > 0 ? '$ruCount доменов в белом списке' : 'Белые списки',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Обновить список',
                              onPressed: refreshRuDirect,
                              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF8391A7)),
                            ),
                            Switch(value: ruEnabled, onChanged: (_) => toggleRuDirect()),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: FutureBuilder<FlintBackendSubscription?>(
                        future: FlintConfig.apiConfigured ? subscriptionBridge.loadActiveSubscription() : null,
                        builder: (context, snapshot) {
                          final sub = snapshot.data;
                          return _FlintCard(
                            icon: Icons.workspace_premium_rounded,
                            title: 'Подписка',
                            subtitle: !FlintConfig.apiConfigured
                                ? 'API не настроен'
                                : sub == null
                                    ? 'Получить данные подписки'
                                    : _subscriptionText(sub),
                            onTap: installSubscription,
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: FutureBuilder<List<FlintSession>>(
                        future: FlintConfig.apiConfigured ? sessionsService.load() : null,
                        builder: (context, snapshot) {
                          final count = snapshot.data?.length ?? 0;
                          return _FlintCard(
                            icon: Icons.family_restroom_rounded,
                            title: 'Семейная подписка',
                            subtitle: FlintConfig.apiConfigured ? 'Устройства $count / 3' : 'API не настроен',
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: const _FlintCard(
                        icon: Icons.support_agent_rounded,
                        title: 'Онлайн поддержка',
                        subtitle: 'Помощь и ответы',
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
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
        'до ${expires.day.toString().padLeft(2, '0')}.${expires.month.toString().padLeft(2, '0')}.${expires.year}',
    ];
    return parts.isEmpty ? 'Активна' : parts.join(' · ');
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xAA101F33),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF69A8FF), size: 17),
          const SizedBox(width: 7),
          Text(text, style: const TextStyle(color: Color(0xFFB7C1D1), fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _FlintCard extends StatelessWidget {
  const _FlintCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.accent = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xCC101F33),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          minHeight: 86,
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent ? const Color(0x554A9BFF) : const Color(0x1FFFFFFF)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent ? const Color(0xFF143E72) : const Color(0xFF173459),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: const Color(0xFF69A8FF), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Color(0xFF91A0B5), height: 1.3, fontSize: 13)),
                  ],
                ),
              ),
              if (trailing != null) trailing! else if (onTap != null) const Icon(Icons.chevron_right_rounded, color: Color(0xFF66768C)),
            ],
          ),
        ),
      ),
    );
  }
}
