import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/theme/aida_colors.dart';
import '../card/membership_card_screen.dart';
import '../cart/widgets/floating_cart_bar.dart';
import '../home/home_screen.dart';
import '../menu/menu_screen.dart';
import '../profile/profile_screen.dart';
import '../rewards/rewards_screen.dart';

/// The five-tab shell. PRD CUS-16, with the QR given permanent prominence
/// per CUS-17.
///
/// The selected tab lives in [selectedTabProvider] rather than local state, so
/// a screen can navigate to another tab — Home's "View All" jumps to Menu.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const _tabs = <Widget>[
    HomeScreen(),
    RewardsScreen(),
    MembershipCardScreen(),
    MenuScreen(),
    ProfileScreen(),
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
      body: Stack(
        children: [
          IndexedStack(index: tab.index, children: _tabs),
          // Positioned above the nav (72 tall + 12 bottom padding), not
          // inside its 5 fixed slots — see FloatingCartBar's own doc for why.
          const Positioned(
            left: 20,
            right: 20,
            bottom: 96,
            child: FloatingCartBar(),
          ),
        ],
      ),
      bottomNavigationBar: _FloatingNav(
        current: tab,
        onSelect: (t) => ref.read(selectedTabProvider.notifier).select(t),
      ),
    );
  }
}

/// Neumorphic floating tab buttons on the cream page — raised when idle,
/// pressed-in when selected (see reference soft-UI circles).
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
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final tab in AppTab.values)
                _NeumorphicNavButton(
                  key: ValueKey('nav_${tab.name}'),
                  icon: _icons[tab]!.$1,
                  label: _icons[tab]!.$2,
                  selected: tab == current,
                  variant:
                      tab == AppTab.qr
                          ? _NavButtonVariant.qr
                          : _NavButtonVariant.standard,
                  onTap: () => onSelect(tab),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _NavButtonVariant { standard, qr }

class _NeumorphicNavButton extends StatefulWidget {
  const _NeumorphicNavButton({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.variant,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final _NavButtonVariant variant;
  final VoidCallback onTap;

  static const _size = 56.0;

  @override
  State<_NeumorphicNavButton> createState() => _NeumorphicNavButtonState();
}

class _NeumorphicNavButtonState extends State<_NeumorphicNavButton> {
  bool _pressed = false;

  bool get _inset => widget.selected || _pressed;

  LinearGradient get _gradient {
    if (widget.variant == _NavButtonVariant.qr) {
      if (_inset) {
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AidaColors.rewardGoldDeep, AidaColors.rewardGold],
        );
      }
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AidaColors.rewardGold,
          AidaColors.rewardGoldDeep,
        ],
      );
    }
    if (_inset) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AidaColors.latte.withValues(alpha: 0.95),
          AidaColors.caramelTint,
          AidaColors.cream,
        ],
        stops: const [0.0, 0.45, 1.0],
      );
    }
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AidaColors.cardWhite,
        AidaColors.cream,
        AidaColors.latte.withValues(alpha: 0.65),
      ],
      stops: const [0.0, 0.55, 1.0],
    );
  }

  Color get _iconColor {
    if (widget.variant == _NavButtonVariant.qr) {
      return AidaColors.espresso;
    }
    return _inset ? AidaColors.coffee : AidaColors.textMuted;
  }

  List<BoxShadow> _shadows() {
    if (_inset) {
      // Deeper pressed well — strong top-left shade, bottom-right catch light.
      return [
        BoxShadow(
          color: AidaColors.espresso.withValues(alpha: 0.32),
          offset: const Offset(6, 6),
          blurRadius: 12,
          spreadRadius: -3,
        ),
        BoxShadow(
          color: AidaColors.coffee.withValues(alpha: 0.12),
          offset: const Offset(4, 4),
          blurRadius: 8,
          spreadRadius: -6,
        ),
        BoxShadow(
          color: AidaColors.cardWhite.withValues(alpha: 0.75),
          offset: const Offset(-4, -4),
          blurRadius: 10,
          spreadRadius: -4,
        ),
      ];
    }
    return [
      BoxShadow(
        color: AidaColors.cardWhite,
        offset: const Offset(-6, -6),
        blurRadius: 14,
      ),
      BoxShadow(
        color: AidaColors.latte.withValues(alpha: 0.95),
        offset: const Offset(6, 6),
        blurRadius: 16,
      ),
      BoxShadow(
        color: AidaColors.espresso.withValues(alpha: 0.08),
        offset: const Offset(0, 10),
        blurRadius: 20,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _inset ? 0.9 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: _NeumorphicNavButton._size,
            height: _NeumorphicNavButton._size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _gradient,
              boxShadow: _shadows(),
              border:
                  widget.variant == _NavButtonVariant.qr && widget.selected
                      ? Border.all(color: AidaColors.cream, width: 2.5)
                      : Border.all(
                        color:
                            _inset
                                ? AidaColors.latte.withValues(alpha: 0.5)
                                : AidaColors.cardWhite.withValues(alpha: 0.6),
                        width: 1,
                      ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_inset)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(-0.55, -0.55),
                          radius: 1.05,
                          colors: [
                            AidaColors.espresso.withValues(alpha: 0.16),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                Icon(widget.icon, size: 24, color: _iconColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
