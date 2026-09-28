import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MyAdaptiveLayout extends HookConsumerWidget {
  const MyAdaptiveLayout({
    super.key,
    required this.navigationShell,
    required this.isMobileBreakpoint,
    required this.showProfilesAction,
  });

  final StatefulNavigationShell navigationShell;
  final bool isMobileBreakpoint;
  final bool showProfilesAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final section = useState(0);

    final entries = const <_FlintNavEntry>[
      _FlintNavEntry(Icons.home_rounded, 'Главная'),
      _FlintNavEntry(Icons.tune_rounded, 'Настройки'),
      _FlintNavEntry(Icons.support_agent_rounded, 'Поддержка'),
    ];

    final content = switch (section.value) {
      1 => const _FlintSettingsPage(),
      2 => const _FlintSupportPage(),
      _ => navigationShell,
    };

    return Material(
      color: const Color(0xFF07111F),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: isMobileBreakpoint
            ? content
            : Row(
                children: [
                  Container(
                    width: 218,
                    decoration: const BoxDecoration(
                      color: Color(0xF00A1626),
                      border: Border(
                        right: BorderSide(color: Color(0x1AFFFFFF)),
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                children: [
                                  _FlintMark(),
                                  SizedBox(width: 10),
                                  Text(
                                    'FLINT',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 34),
                            for (var i = 0; i < entries.length; i++) ...[
                              _FlintNavButton(
                                entry: entries[i],
                                selected: section.value == i,
                                onTap: () {
                                  section.value = i;
                                  if (i == 0) {
                                    navigationShell.goBranch(0, initialLocation: false);
                                  }
                                },
                              ),
                              const SizedBox(height: 8),
                            ],
                            const Spacer(),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                'Ваша приватность\nв надежных лапах',
                                style: TextStyle(
                                  color: Color(0xFF8391A7),
                                  height: 1.45,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: content),
                ],
              ),
        bottomNavigationBar: isMobileBreakpoint
            ? Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF0B1728),
                  border: Border(top: BorderSide(color: Color(0x1AFFFFFF))),
                ),
                child: NavigationBar(
                  backgroundColor: Colors.transparent,
                  indicatorColor: const Color(0xFF1F6FEB),
                  selectedIndex: section.value,
                  destinations: entries
                      .map((e) => NavigationDestination(icon: Icon(e.icon), label: e.label))
                      .toList(),
                  onDestinationSelected: (index) {
                    section.value = index;
                    if (index == 0) {
                      navigationShell.goBranch(0, initialLocation: false);
                    }
                  },
                ),
              )
            : null,
      ),
    );
  }
}

class _FlintNavEntry {
  const _FlintNavEntry(this.icon, this.label);
  final IconData icon;
  final String label;
}

class _FlintNavButton extends StatelessWidget {
  const _FlintNavButton({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final _FlintNavEntry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF153154) : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(
                entry.icon,
                color: selected ? const Color(0xFF69A8FF) : const Color(0xFF8391A7),
                size: 21,
              ),
              const SizedBox(width: 13),
              Text(
                entry.label,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFFB7C1D1),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlintMark extends StatelessWidget {
  const _FlintMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        color: const Color(0xFF1F6FEB),
        borderRadius: BorderRadius.circular(11),
        boxShadow: const [
          BoxShadow(color: Color(0x441F6FEB), blurRadius: 16, spreadRadius: 1),
        ],
      ),
      child: const Icon(Icons.pets_rounded, color: Colors.white, size: 20),
    );
  }
}

class _FlintSettingsPage extends StatelessWidget {
  const _FlintSettingsPage();

  @override
  Widget build(BuildContext context) {
    return const _FlintStaticPage(
      title: 'Настройки Flint',
      subtitle: 'Только основные параметры клиента',
      children: [
        _FlintStaticCard(
          icon: Icons.shield_outlined,
          title: 'Flint Guard',
          subtitle: 'Контроль состояния соединения и автоматическое восстановление',
        ),
        _FlintStaticCard(
          icon: Icons.alt_route_rounded,
          title: 'RU Direct',
          subtitle: 'Российские ресурсы напрямую, остальной трафик через Flint',
        ),
        _FlintStaticCard(
          icon: Icons.power_settings_new_rounded,
          title: 'Автозапуск',
          subtitle: 'Запуск Flint вместе с Windows',
        ),
      ],
    );
  }
}

class _FlintSupportPage extends StatelessWidget {
  const _FlintSupportPage();

  @override
  Widget build(BuildContext context) {
    return const _FlintStaticPage(
      title: 'Онлайн поддержка',
      subtitle: 'Помощь без лишних технических экранов',
      children: [
        _FlintStaticCard(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Чат поддержки',
          subtitle: 'Канал поддержки подключается через Flint API',
        ),
        _FlintStaticCard(
          icon: Icons.info_outline_rounded,
          title: 'О приложении',
          subtitle: 'Flint — Ваша приватность в надежных лапах',
        ),
      ],
    );
  }
}

class _FlintStaticPage extends StatelessWidget {
  const _FlintStaticPage({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.all(34),
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF8391A7), fontSize: 14),
            ),
            const SizedBox(height: 28),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _FlintStaticCard extends StatelessWidget {
  const _FlintStaticCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xCC101F33),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF173459),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: const Color(0xFF69A8FF)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Color(0xFF91A0B5), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
