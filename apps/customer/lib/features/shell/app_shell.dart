import 'package:flutter/material.dart';

import '../../core/theme/aida_colors.dart';
import '../card/membership_card_screen.dart';
import '../home/home_screen.dart';
import '../../core/theme/aida_type.dart';

/// The five-tab shell. PRD CUS-16, with the QR elevated per CUS-17.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _tabs = <Widget>[
    HomeScreen(),
    _ComingSoon(title: 'Rewards', note: 'Vouchers, redemption, and stamp rewards'),
    MembershipCardScreen(),
    _ComingSoon(title: 'Menu', note: 'Categories, items, and prices'),
    _ComingSoon(title: 'Profile', note: 'Account, history, and settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AidaColors.cream,
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: _BottomNav(
        index: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AidaColors.cardWhite,
        boxShadow: [
          BoxShadow(
            color: AidaColors.espresso.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavIcon(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: index == 0,
                onTap: () => onTap(0),
              ),
              _NavIcon(
                icon: Icons.card_giftcard_rounded,
                label: 'Rewards',
                selected: index == 1,
                onTap: () => onTap(1),
              ),
              _QrButton(selected: index == 2, onTap: () => onTap(2)),
              _NavIcon(
                icon: Icons.restaurant_menu_rounded,
                label: 'Menu',
                selected: index == 3,
                onTap: () => onTap(3),
              ),
              _NavIcon(
                icon: Icons.person_rounded,
                label: 'Profile',
                selected: index == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AidaColors.coffee : AidaColors.textMuted;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: SizedBox(
          width: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                style: AidaType.sans(
                  size: 10,
                  weight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The elevated centre QR button. CUS-17: one tap from anywhere.
class _QrButton extends StatelessWidget {
  const _QrButton({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'My QR',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AidaColors.rewardGold, Color(0xFFB58B3C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AidaColors.rewardGold.withValues(alpha: 0.45),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: selected ? Border.all(color: AidaColors.espresso, width: 2) : null,
          ),
          child: const Icon(
            Icons.qr_code_2_rounded,
            size: 28,
            color: AidaColors.espresso,
          ),
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
              Text(
                title,
                style: AidaType.serif(
                  size: 26,
                  weight: FontWeight.w700,
                  color: AidaColors.textPrimary,
                ),
              ),
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
