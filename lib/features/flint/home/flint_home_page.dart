import 'package:flutter/material.dart';

import '../guard/flint_guard_state.dart';
import '../ru_direct/ru_direct_state.dart';

class FlintHomePage extends StatefulWidget {
  const FlintHomePage({super.key});

  @override
  State<FlintHomePage> createState() => _FlintHomePageState();
}

class _FlintHomePageState extends State<FlintHomePage> {
  FlintGuardState guard = const FlintGuardState(
    status: FlintGuardStatus.disconnected,
  );

  RuDirectState ruDirect = const RuDirectState(
    enabled: true,
    domainCount: 0,
  );

  String country = 'Нидерланды';
  int usedDevices = 0;
  int maxDevices = 3;

  bool get connected => guard.status == FlintGuardStatus.connected;

  void toggleConnection() {
    setState(() {
      guard = FlintGuardState(
        status: connected
            ? FlintGuardStatus.disconnected
            : FlintGuardStatus.connected,
        serverName: connected ? null : country,
        latencyMs: connected ? null : 43,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 8),
                Text(
                  'Flint',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ваша приватность в надежных лапах',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 34),
                Icon(
                  connected ? Icons.verified_user_rounded : Icons.shield_outlined,
                  size: 84,
                ),
                const SizedBox(height: 14),
                Text(
                  connected ? 'Вы защищены' : 'Вы не защищены',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: toggleConnection,
                    child: Text(connected ? 'Отключиться' : 'Подключиться'),
                  ),
                ),
                const SizedBox(height: 16),
                _GuardCard(state: guard),
                const SizedBox(height: 18),
                _MenuTile(
                  icon: Icons.public_rounded,
                  title: 'Страна',
                  subtitle: country,
                  onTap: () {},
                ),
                _MenuTile(
                  icon: Icons.alt_route_rounded,
                  title: 'RU Direct',
                  subtitle: ruDirect.enabled
                      ? 'Белые списки включены'
                      : 'Выключено',
                  trailing: Switch(
                    value: ruDirect.enabled,
                    onChanged: (value) {
                      setState(() {
                        ruDirect = ruDirect.copyWith(enabled: value);
                      });
                    },
                  ),
                  onTap: () {},
                ),
                _MenuTile(
                  icon: Icons.family_restroom_rounded,
                  title: 'Семейная подписка',
                  subtitle: 'Устройства $usedDevices / $maxDevices',
                  onTap: () {},
                ),
                _MenuTile(
                  icon: Icons.support_agent_rounded,
                  title: 'Онлайн поддержка',
                  subtitle: 'Помощь и ответы',
                  onTap: () {},
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
  const _GuardCard({required this.state});
  final FlintGuardState state;

  @override
  Widget build(BuildContext context) {
    final protected = state.isProtected;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(protected ? Icons.check_circle : Icons.circle_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Flint Guard',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    protected
                        ? '${state.serverName ?? 'Подключено'}'
                          '${state.latencyMs == null ? '' : ' • ${state.latencyMs} мс'}'
                        : 'Соединение не установлено',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
