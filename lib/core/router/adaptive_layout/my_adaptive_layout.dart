import 'package:flutter/material.dart';
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
    final entries = <_FlintNavEntry>[
      const _FlintNavEntry(0, Icons.home_rounded, 'Главная'),
      if (showProfilesAction && !isMobileBreakpoint)
        const _FlintNavEntry(1, Icons.public_rounded, 'Серверы'),
      _FlintNavEntry(
        showProfilesAction && !isMobileBreakpoint ? 2 : 1,
        Icons.tune_rounded,
        'Настройки',
      ),
    ];

    final selected = entries.indexWhere((e) => e.branchIndex == navigationShell.currentIndex);
    final selectedIndex = selected < 0 ? 0 : selected;

    return Material(
      color: const Color(0xFF07111F),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: isMobileBreakpoint
            ? navigationShell
            : Row(
                children: [
                  Container(
                    width: 218,
                    decoration: const BoxDecoration(
                      color: Color(0xE60B1728),
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
                                selected: selectedIndex == i,
                                onTap: () => navigationShell.goBranch(
                                  entries[i].branchIndex,
                                  initialLocation: entries[i].branchIndex == navigationShell.currentIndex,
                                ),
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
                  Expanded(child: navigationShell),
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
                  selectedIndex: selectedIndex,
                  destinations: entries
                      .map((e) => NavigationDestination(icon: Icon(e.icon), label: e.label))
                      .toList(),
                  onDestinationSelected: (index) => navigationShell.goBranch(entries[index].branchIndex),
                ),
              )
            : null,
      ),
    );
  }
}

class _FlintNavEntry {
  const _FlintNavEntry(this.branchIndex, this.icon, this.label);
  final int branchIndex;
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
