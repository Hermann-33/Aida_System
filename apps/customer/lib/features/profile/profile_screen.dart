import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_type.dart';
import '../../domain/model/member.dart';
import '../history/order_history_screen.dart';
import 'edit_profile_screen.dart';

/// Soft profile sheet matching the client's reference: light header, Back +
/// camera bar, centered avatar with badge, white menu sheet, collapsing
/// scroll. Logout sits at the bottom of the list.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AidaColors.espresso,
          content: Text(
            '$feature is coming soon',
            style: AidaType.sans(size: 13, color: AidaColors.cream),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(displayedMemberProvider);

    return Scaffold(
      // Same pink as the header bottom so the inset card's corners sit on
      // one continuous background (reference: gray page → white card).
      backgroundColor: AidaColors.latte,
      body: SafeArea(
        bottom: false,
        child: member.when(
          data:
              (m) => _ProfileScroll(
                member: m,
                onComingSoon: (f) => _comingSoon(context, f),
                onBack:
                    () => ref
                        .read(selectedTabProvider.notifier)
                        .select(AppTab.home),
                onLogout: () => ref.read(authStateProvider.notifier).logOut(),
              ),
          loading:
              () => _ProfileScroll(
                member: null,
                onComingSoon: (f) => _comingSoon(context, f),
                onBack:
                    () => ref
                        .read(selectedTabProvider.notifier)
                        .select(AppTab.home),
                onLogout: () => ref.read(authStateProvider.notifier).logOut(),
              ),
          error:
              (_, __) => _ProfileScroll(
                member: null,
                onComingSoon: (f) => _comingSoon(context, f),
                onBack:
                    () => ref
                        .read(selectedTabProvider.notifier)
                        .select(AppTab.home),
                onLogout: () => ref.read(authStateProvider.notifier).logOut(),
              ),
        ),
      ),
    );
  }
}

class _ProfileScroll extends StatelessWidget {
  const _ProfileScroll({
    required this.member,
    required this.onComingSoon,
    required this.onBack,
    required this.onLogout,
  });

  final Member? member;
  final ValueChanged<String> onComingSoon;
  final VoidCallback onBack;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverPersistentHeader(
          // Pinned: the header collapses in place instead of scrolling off,
          // so the avatar/name shrink smoothly rather than flying upward.
          pinned: true,
          delegate: _CollapsingProfileHeader(
            member: member,
            onBack: onBack,
            onCamera: () => onComingSoon('Changing your photo'),
            onEditProfile:
                member == null
                    ? () => onComingSoon('Editing your profile')
                    : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(member: member!),
                      ),
                    ),
            onSettings: () => onComingSoon('Settings'),
          ),
        ),
        SliverToBoxAdapter(
          // No negative overlap — the header used to paint over the card's
          // top 20px and flatten the top corners.
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 140),
            child: Container(
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AidaColors.cardWhite,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: AidaColors.espresso.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  _ProfileRow(
                    icon: Icons.receipt_long_rounded,
                    label: 'My Orders',
                    gradient: const [
                      AidaColors.latte,
                      AidaColors.caramelTint,
                      AidaColors.cream,
                    ],
                    iconColor: AidaColors.coffee,
                    onTap:
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const OrderHistoryScreen(),
                          ),
                        ),
                  ),
                  const _RowDivider(),
                  _ProfileRow(
                    icon: Icons.person_rounded,
                    label: 'Edit profile',
                    gradient: const [
                      AidaColors.caramelTint,
                      AidaColors.latte,
                      AidaColors.cream,
                    ],
                    iconColor: AidaColors.coffee,
                    onTap:
                        member == null
                            ? () => onComingSoon('Editing your profile')
                            : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (_) => EditProfileScreen(member: member!),
                              ),
                            ),
                  ),
                  const _RowDivider(),
                  _ProfileRow(
                    icon: Icons.bar_chart_rounded,
                    label: 'My stats',
                    gradient: [
                      AidaColors.latte.withValues(alpha: 0.9),
                      AidaColors.cream,
                      AidaColors.caramelTint.withValues(alpha: 0.7),
                    ],
                    iconColor: AidaColors.espresso,
                    onTap: () => onComingSoon('My stats'),
                  ),
                  const _RowDivider(),
                  _ProfileRow(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    gradient: [
                      AidaColors.rewardGold.withValues(alpha: 0.35),
                      AidaColors.caramelTint,
                      AidaColors.cream,
                    ],
                    iconColor: AidaColors.rewardGoldDeep,
                    onTap: () => onComingSoon('Settings'),
                  ),
                  const _SectionDivider(),
                  _ProfileRow(
                    icon: Icons.person_add_alt_1_rounded,
                    label: 'Invite a friend',
                    gradient: const [
                      AidaColors.cream,
                      AidaColors.latte,
                      AidaColors.caramelTint,
                    ],
                    iconColor: AidaColors.textMuted,
                    onTap: () => onComingSoon('Invite a friend'),
                  ),
                  const _RowDivider(),
                  _ProfileRow(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Help',
                    gradient: const [
                      AidaColors.cream,
                      AidaColors.caramelTint,
                      AidaColors.latte,
                    ],
                    iconColor: AidaColors.textMuted,
                    onTap: () => onComingSoon('Help'),
                  ),
                  const _RowDivider(),
                  _ProfileRow(
                    icon: Icons.logout_rounded,
                    label: 'Logout',
                    gradient: [
                      AidaColors.error.withValues(alpha: 0.16),
                      AidaColors.caramelTint,
                      AidaColors.cream,
                    ],
                    iconColor: AidaColors.error,
                    onTap: onLogout,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Tall light header — Back + camera on top, avatar / badge / name below.
/// When scrolled up, pins to a compact "My Profile" bar + side-by-side
/// avatar, name, and Edit profile (reference layout).
class _CollapsingProfileHeader extends SliverPersistentHeaderDelegate {
  _CollapsingProfileHeader({
    required this.member,
    required this.onBack,
    required this.onCamera,
    required this.onEditProfile,
    required this.onSettings,
  });

  final Member? member;
  final VoidCallback onBack;
  final VoidCallback onCamera;
  final VoidCallback onEditProfile;
  final VoidCallback onSettings;

  // Tall enough that the upper half reads like the reference before the
  // white sheet takes over.
  static const _expanded = 380.0;
  static const _collapsed = 168.0;
  static const _toolbar = 48.0;

  @override
  double get maxExtent => _expanded;

  @override
  double get minExtent => _collapsed;

  @override
  bool shouldRebuild(covariant _CollapsingProfileHeader oldDelegate) =>
      oldDelegate.member != member ||
      oldDelegate.onBack != onBack ||
      oldDelegate.onCamera != onCamera ||
      oldDelegate.onEditProfile != onEditProfile ||
      oldDelegate.onSettings != onSettings;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final range = maxExtent - minExtent;
    final t = range <= 0 ? 1.0 : (shrinkOffset / range).clamp(0.0, 1.0);
    final curved = Curves.easeOutCubic.transform(t);

    final name = member?.name ?? 'Aida Member';
    final initial = member?.initial ?? 'A';
    final tier = member?.tierName ?? 'Member';
    final isStudent = member?.isVerifiedStudent ?? false;
    final idNumber = member?.studentOrEmployeeId;

    final avatarSize = math.max(56.0, 128.0 - curved * 72.0);
    final expandedOpacity = (1.0 - curved * 1.05).clamp(0.0, 1.0);
    final collapsedOpacity = ((curved - 0.28) / 0.72).clamp(0.0, 1.0);
    // A local copy, not `member.email` directly — `member` is a public
    // field, and Dart only promotes private final fields/locals from
    // nullable to non-nullable, so `member != null && member.email` alone
    // doesn't compile.
    final email = member?.email;
    final subtitle = (email != null && email.isNotEmpty) ? email : tier;

    return DecoratedBox(
      decoration: BoxDecoration(
        // Darker at the top, soft pink through the middle, still pink at
        // the bottom so the sheet's big top corners read (cream-on-cream
        // made the curve disappear).
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AidaColors.coffeeLight, AidaColors.latte, AidaColors.latte],
          stops: const [0.0, 0.42, 1.0],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Expanded identity block — pushed lower than the top bar.
          Positioned.fill(
            child: Opacity(
              opacity: expandedOpacity,
              child: IgnorePointer(
                ignoring: expandedOpacity < 0.15,
                child: Column(
                  children: [
                    const SizedBox(height: 88),
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.bottomCenter,
                      children: [
                        Container(
                          width: avatarSize,
                          height: avatarSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AidaColors.cardWhite,
                            boxShadow: [
                              BoxShadow(
                                color: AidaColors.espresso.withValues(
                                  alpha: 0.1,
                                ),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: AidaType.serif(
                                size: avatarSize * 0.36,
                                color: AidaColors.coffee,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -11,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isStudent
                                      ? AidaColors.cityRed
                                      : AidaColors.coffee,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isStudent ? 'STUDENT' : 'MEMBER',
                              style: AidaType.sans(
                                size: 10,
                                weight: FontWeight.w800,
                                letterSpacing: 0.7,
                                color: AidaColors.cardWhite,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: AidaType.sans(
                        size: 22,
                        weight: FontWeight.w700,
                        color: AidaColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tier,
                      style: AidaType.sans(
                        size: 14,
                        color: AidaColors.textMuted,
                      ),
                    ),
                    if (idNumber != null && idNumber.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        isStudent
                            ? 'Student ID: $idNumber'
                            : 'Employee ID: $idNumber',
                        style: AidaType.sans(
                          size: 12,
                          weight: FontWeight.w600,
                          color: AidaColors.coffee,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Collapsed — reference: avatar left, name + subtitle, Edit pill.
          Positioned(
            left: 20,
            right: 20,
            top: _toolbar + 8,
            bottom: 12,
            child: Opacity(
              opacity: collapsedOpacity,
              child: IgnorePointer(
                ignoring: collapsedOpacity < 0.2,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AidaColors.cardWhite,
                            boxShadow: [
                              BoxShadow(
                                color: AidaColors.espresso.withValues(
                                  alpha: 0.1,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: AidaType.serif(
                                size: 28,
                                color: AidaColors.coffee,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Material(
                            color: AidaColors.cardWhite,
                            shape: const CircleBorder(),
                            elevation: 2,
                            child: InkWell(
                              onTap: onCamera,
                              customBorder: const CircleBorder(),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                  Icons.photo_camera_outlined,
                                  size: 16,
                                  color: AidaColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AidaType.sans(
                              size: 17,
                              weight: FontWeight.w700,
                              color: AidaColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AidaType.sans(
                              size: 13,
                              color: AidaColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FilledButton(
                              onPressed: onEditProfile,
                              style: FilledButton.styleFrom(
                                backgroundColor: AidaColors.coffee,
                                foregroundColor: AidaColors.cardWhite,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 8,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: Text(
                                'Edit profile',
                                style: AidaType.sans(
                                  size: 13,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Expanded top bar — Back (left) + camera (right).
          Positioned(
            top: 0,
            left: 8,
            right: 8,
            height: _toolbar,
            child: Opacity(
              opacity: expandedOpacity,
              child: IgnorePointer(
                ignoring: expandedOpacity < 0.2,
                child: Row(
                  children: [
                    InkWell(
                      onTap: onBack,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.chevron_left_rounded,
                              size: 26,
                              color: AidaColors.textPrimary,
                            ),
                            Text(
                              'Back',
                              style: AidaType.sans(
                                size: 16,
                                weight: FontWeight.w600,
                                color: AidaColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: onCamera,
                      tooltip: 'Change photo',
                      icon: const Icon(
                        Icons.add_a_photo_outlined,
                        size: 22,
                        color: AidaColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Collapsed top bar — back icon, title, settings.
          Positioned(
            top: 0,
            left: 4,
            right: 4,
            height: _toolbar,
            child: Opacity(
              opacity: collapsedOpacity,
              child: IgnorePointer(
                ignoring: collapsedOpacity < 0.2,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: AidaColors.textPrimary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'My Profile',
                        textAlign: TextAlign.center,
                        style: AidaType.sans(
                          size: 17,
                          weight: FontWeight.w700,
                          color: AidaColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onSettings,
                      tooltip: 'Settings',
                      icon: const Icon(
                        Icons.settings_outlined,
                        size: 22,
                        color: AidaColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    // Inset under the label (past the icon), matching the original style.
    return Divider(
      height: 1,
      thickness: 1,
      indent: 84,
      color: AidaColors.latte.withValues(alpha: 0.55),
    );
  }
}

/// Slightly taller full-width break before the secondary section.
class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 24,
      thickness: 1,
      color: AidaColors.latte.withValues(alpha: 0.7),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final List<Color> gradient;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // InkWell is edge-to-edge; content padding lives *inside* so hover /
    // splash fills the full sheet width.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AidaColors.latte.withValues(alpha: 0.45),
        highlightColor: AidaColors.latte.withValues(alpha: 0.28),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: AidaType.sans(
                    size: 15,
                    weight: FontWeight.w600,
                    color: AidaColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: AidaColors.textMuted.withValues(alpha: 0.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
