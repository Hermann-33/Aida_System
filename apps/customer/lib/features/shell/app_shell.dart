import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_type.dart';
import '../card/membership_card_screen.dart';
import '../home/home_screen.dart';
import '../menu/menu_screen.dart';

/// The five-tab shell. PRD CUS-16, with the QR given permanent prominence
/// per CUS-17.
///
/// The selected tab lives in [selectedTabProvider] rather than local state, so
/// a screen can navigate to another tab — Home's "View All" jumps to Menu.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const _tabs = <Widget>[
    HomeScreen(),
    _ComingSoon(title: 'Rewards', note: 'Vouchers, redemption, and stamp rewards'),
    MembershipCardScreen(),
    MenuScreen(),
    _ComingSoon(title: 'Profile', note: 'Account, history, and settings'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(selectedTabProvider);

    return Scaffold(
      backgroundColor: AidaColors.cream,
      // The nav floats over the content rather than sitting in its own strip.
      extendBody: true,
      // IndexedStack, not a swap: it keeps each tab's scroll position and
      // avoids refetching every time a customer flips back to Home.
      body: IndexedStack(index: tab.index, children: _tabs),
      bottomNavigationBar: _FloatingNav(
        current: tab,
        onSelect: (t) => ref.read(selectedTabProvider.notifier).select(t),
      ),
    );
  }
}

/// A detached dark pill. Icon-only.
///
/// No visible labels, which is a deliberate trade: it reads as premium, but a
/// customer must infer "Rewards" from a gift icon. Every item carries a
/// [Semantics] label so screen readers still announce it (PRD §18), and the
/// labels can come back if customers hesitate.
class _FloatingNav extends StatelessWidget {
  const _FloatingNav({required this.current, required this.onSelect});

  final AppTab current;
  final ValueChanged<AppTab> onSelect;

  static const _icons = {
    AppTab.home: (Icons.home_rounded, 'Home'),
    AppTab.rewards: (Icons.card_giftcard_rounded, 'Rewards'),
    AppTab.qr: (Icons.qr_code_2_rounded, 'My QR'),
    AppTab.menu: (Icons.restaurant_menu_rounded, 'Menu'),
    AppTab.profile: (Icons.person_rounded, 'Profile'),
  };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: AidaColors.espresso,
            borderRadius: BorderRadius.circular(34),
            boxShadow: [
              BoxShadow(
                color: AidaColors.espresso.withValues(alpha: 0.32),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final tab in AppTab.values)
                _NavItem(
                  key: ValueKey('nav_${tab.name}'),
                  icon: _icons[tab]!.$1,
                  label: _icons[tab]!.$2,
                  selected: tab == current,
                  // The QR stays gold whether selected or not. CUS-17 asks for
                  // one-tap QR access, and a button that only stands out once
                  // you are already on it defeats that.
                  alwaysGold: tab == AppTab.qr,
                  onTap: () => onSelect(tab),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.alwaysGold,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool alwaysGold;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;

    if (alwaysGold) {
      background = AidaColors.rewardGold;
      foreground = AidaColors.espresso;
    } else if (selected) {
      background = AidaColors.cream;
      foreground = AidaColors.espresso;
    } else {
      background = Colors.transparent;
      foreground = AidaColors.latte;
    }

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: background,
            // A selected QR needs some mark of its own, since it is gold either
            // way — a cream ring reads clearly against the dark pill.
            border:
                alwaysGold && selected
                    ? Border.all(color: AidaColors.cream, width: 2)
                    : null,
          ),
          child: Icon(icon, size: 23, color: foreground),
        ),
      ),
    );
  }
}

/// Honest placeholder for the tabs not yet built. Says what is coming rather
/// than pretending to be broken.
class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.title, required this.note});

  final String title;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AidaColors.cream,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: AidaType.serif(size: 26, color: AidaColors.textPrimary)),
              const SizedBox(height: 8),
              Text(
                note,
                textAlign: TextAlign.center,
                style: AidaType.sans(size: 13, color: AidaColors.textMuted),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AidaColors.latte.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'NEXT UP',
                  style: AidaType.sans(
                    size: 10,
                    weight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AidaColors.coffee,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
