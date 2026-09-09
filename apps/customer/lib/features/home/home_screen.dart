import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_type.dart';
import '../../core/widgets/aida_popup.dart';
import '../../core/widgets/entrance.dart';
import '../../domain/model/member.dart';
import '../../domain/model/loyalty.dart';
import '../../domain/model/menu_item.dart';
import '../history/order_history_screen.dart';
import '../menu/item_detail_screen.dart';
import '../menu/widgets/category_chip.dart';
import '../menu/widgets/category_strip.dart';
import 'widgets/popular_item_card.dart';
import 'widgets/promo_carousel.dart';
import 'widgets/stamp_ring.dart';

/// Home.
///
/// Order is deliberate. Loyalty (points, stamps) sits above browse content
/// (promos, categories, popular picks) because that is Aida's differentiator —
/// PRD §20 takes "keep points and rewards highly visible" as the lesson from
/// ZUS. A pure ordering app would invert this; Aida is not one.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // The page's own scroll view — shared explicitly with every ScrollReveal
  // below rather than left for `Scrollable.maybeOf` to guess at, since the
  // Popular Picks grid nests its own (non-scrolling) Scrollable that would
  // otherwise be found instead. See ScrollReveal's own doc.
  final _scrollController = ScrollController();
  final _viewportKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Open the Menu tab, optionally filtered to one category.
  ///
  /// Passing the category through is what makes the chip worth tapping: "View
  /// All" clears the filter, while tapping Coffee lands you on Coffee.
  void _openMenu({String? categoryId}) {
    ref.read(favoritesOnlyProvider.notifier).set(false);
    ref.read(selectedCategoryProvider.notifier).select(categoryId);
    ref.read(selectedTabProvider.notifier).select(AppTab.menu);
  }

  /// Open the Menu tab filtered to favorites — the strip's first tile.
  void _openFavorites() {
    ref.read(selectedCategoryProvider.notifier).select(null);
    ref.read(favoritesOnlyProvider.notifier).set(true);
    ref.read(selectedTabProvider.notifier).select(AppTab.menu);
  }

  /// Jump to the Rewards tab.
  void _openRewards() =>
      ref.read(selectedTabProvider.notifier).select(AppTab.rewards);

  /// There is no notifications system in this app yet. Saying so plainly
  /// when the bell is tapped is the honest option — a bell that looks
  /// tappable and silently does nothing reads as a bug, not an unbuilt
  /// feature.
  void _showNoNotificationsYet(BuildContext context) {
    AidaPopup.show(context, title: 'No notifications yet');
  }

  /// Points and stamps load together. Showing a balance above an empty track
  /// would flash a half-built card, so it waits for both.
  Widget? _loyaltySection(
    AsyncValue<Points> points,
    AsyncValue<StampCard> stamps,
  ) {
    final p = points.value;
    final s = stamps.value;
    if (p == null || s == null) return null;
    return _LoyaltyInfo(points: p, stamps: s);
  }

  @override
  Widget build(BuildContext context) {
    final member = ref.watch(displayedMemberProvider);
    final points = ref.watch(pointsProvider);
    final stamps = ref.watch(stampCardProvider);
    final promos = ref.watch(promosProvider);
    final categories = ref.watch(categoriesProvider);
    final menuItems = ref.watch(menuItemsProvider);
    final popular = ref.watch(popularItemsProvider);

    // Only categories a customer can actually browse to — Add-ons has no
    // product-kind items of its own (see MenuScreen's own doc comment), so
    // it never gets a tile here either.
    final browsableCategoryIds =
        (menuItems.value ?? const <MenuItem>[])
            .where((item) => item.kind == 'product')
            .map((item) => item.categoryId)
            .toSet();

    return Scaffold(
      backgroundColor: AidaColors.cream,
      body: Stack(
        children: [
          // Soft red → pink → cream wash behind the hero only — same idea as
          // the reference's orange→peach header. Full-page gradient would
          // muddy the menu/promos below; this fades out before browse starts.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 340,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AidaColors.espresso,
                    AidaColors.coffee,
                    AidaColors.coffeeLight,
                    AidaColors.latte,
                    AidaColors.cream.withValues(alpha: 0),
                  ],
                  stops: const [0.0, 0.22, 0.45, 0.72, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              color: AidaColors.coffee,
              onRefresh: () async {
                ref
                  ..invalidate(pointsProvider)
                  ..invalidate(stampCardProvider)
                  ..invalidate(rewardsProvider)
                  ..invalidate(promosProvider)
                  ..invalidate(categoriesProvider)
                  ..invalidate(popularItemsProvider);
              },
              child: Container(
                key: _viewportKey,
                child: ListView(
                  // Keyed so tests can target this scroll view specifically — the
                  // category strip below also contains a ListView once it has more
                  // categories than fit, and `find.byType(ListView)` alone is
                  // ambiguous the moment that happens.
                  key: const Key('home_scroll'),
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    Padding(
                      // 170, not 110, at the bottom: the nav pill alone only
                      // needed 110, but the floating cart bar sits above it once
                      // the cart has items, and 110 never accounted for that
                      // second layer.
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 170),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ScrollReveal(
                            controller: _scrollController,
                            viewportKey: _viewportKey,
                            child: _HeroHeader(
                              member: member.value,
                              onNotifications:
                                  () => _showNoNotificationsYet(context),
                              onScan:
                                  () => ref
                                      .read(selectedTabProvider.notifier)
                                      .select(AppTab.qr),
                              onOrders:
                                  () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder:
                                          (_) => const OrderHistoryScreen(),
                                    ),
                                  ),
                              onFavorites: () {
                                ref
                                    .read(favoritesOnlyProvider.notifier)
                                    .set(true);
                                _openMenu();
                              },
                              onRedeem: _openRewards,
                              loyalty: _loyaltySection(points, stamps),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // --- Then browse -----------------------------------
                          // Active offers are folded into the carousel as slides
                          // (see the note on the Promo model) rather than
                          // repeated below it in a separate banner list.
                          ScrollReveal(
                            order: 2,
                            controller: _scrollController,
                            viewportKey: _viewportKey,
                            child: promos.when(
                              data: (list) => PromoCarousel(promos: list),
                              // Matches the carousel's height, so the page does
                              // not jump when the promos land.
                              loading: () => const _Skeleton(height: 196),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ),
                          const SizedBox(height: 24),

                          ScrollReveal(
                            order: 3,
                            controller: _scrollController,
                            viewportKey: _viewportKey,
                            child: categories.when(
                              data: (list) {
                                final browsable = list
                                    .where(
                                      (c) =>
                                          browsableCategoryIds.contains(c.id),
                                    )
                                    .toList(growable: false);
                                return browsable.isEmpty
                                    ? const SizedBox.shrink()
                                    : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _SectionHeader(
                                          title: 'Explore Our Menu',
                                          onViewAll: () => _openMenu(),
                                        ),
                                        const SizedBox(height: 14),
                                        CategoryStrip(
                                          categories: browsable,
                                          keyPrefix: 'home_cat',
                                          showFavorites: true,
                                          onSelectFavorites: _openFavorites,
                                          onSelect:
                                              (id) => _openMenu(categoryId: id),
                                        ),
                                      ],
                                    );
                              },
                              loading:
                                  () => const _Skeleton(
                                    height: CategoryChip.height + 20,
                                  ),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ),
                          const SizedBox(height: 22),

                          popular.when(
                            data:
                                (list) =>
                                    list.isEmpty
                                        ? const SizedBox.shrink()
                                        : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ScrollReveal(
                                              order: 4,
                                              controller: _scrollController,
                                              viewportKey: _viewportKey,
                                              child: _SectionHeader(
                                                title: 'Popular Picks',
                                                onViewAll: () => _openMenu(),
                                              ),
                                            ),
                                            const SizedBox(height: 26),
                                            // shrinkWrap + disabled physics: this
                                            // grid is nested inside Home's own
                                            // vertical ListView, so it must size
                                            // to its content and let the outer
                                            // list own the actual scrolling.
                                            GridView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              gridDelegate:
                                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                                    crossAxisCount: 2,
                                                    crossAxisSpacing: 14,
                                                    mainAxisSpacing: 22,
                                                    // A fixed height, not
                                                    // childAspectRatio. Aspect
                                                    // ratio makes cell height
                                                    // scale with cell width —
                                                    // fine on a phone, but
                                                    // `flutter run -d chrome`
                                                    // opens at whatever width the
                                                    // browser tab is, and on a
                                                    // wide desktop window this
                                                    // stretched each card's
                                                    // height far past what the
                                                    // fixed-size photo and few
                                                    // lines of text actually
                                                    // need, leaving a large dead
                                                    // gap. The card's content has
                                                    // a fixed size regardless of
                                                    // window width, so its height
                                                    // should be fixed too.
                                                    mainAxisExtent: 250,
                                                  ),
                                              itemCount: list.length,
                                              // Each card reveals on its own as
                                              // its own row scrolls into view —
                                              // order is the row index (i ~/ 2),
                                              // not the card index, so both cards
                                              // in a row cascade in together
                                              // rather than the whole grid
                                              // animating as one block.
                                              itemBuilder:
                                                  (_, i) => ScrollReveal(
                                                    order: i ~/ 2,
                                                    controller:
                                                        _scrollController,
                                                    viewportKey: _viewportKey,
                                                    child: PressableScale(
                                                      child: PopularItemCard(
                                                        item: list[i],
                                                        onTap:
                                                            () =>
                                                                openItemDetail(
                                                                  context,
                                                                  list[i],
                                                                ),
                                                      ),
                                                    ),
                                                  ),
                                            ),
                                          ],
                                        ),
                            loading: () => const _Skeleton(height: 220),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
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

/// Section title with a "View All" affordance.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onViewAll});

  final String title;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: AidaType.sans(
              size: 17,
              weight: FontWeight.w700,
              color: AidaColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: AidaColors.latte.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onViewAll,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View All',
                    style: AidaType.sans(
                      size: 12,
                      weight: FontWeight.w700,
                      color: AidaColors.coffee,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 13,
                    color: AidaColors.coffee,
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

/// Greeting on a darker red wash (so white text stays readable), then balance
/// + weekday check-in, then four equal action circles including Redeem.
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.member,
    required this.onNotifications,
    required this.onScan,
    required this.onOrders,
    required this.onFavorites,
    required this.onRedeem,
    required this.loyalty,
  });

  final Member? member;
  final VoidCallback onNotifications;
  final VoidCallback onScan;
  final VoidCallback onOrders;
  final VoidCallback onFavorites;
  final VoidCallback onRedeem;
  final Widget? loyalty;

  static String _partOfDay() {
    final h = clock.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  /// Soft shadow so white type still reads when the wash lightens.
  static List<Shadow> get _whiteGlow => [
    Shadow(
      color: AidaColors.espresso.withValues(alpha: 0.35),
      blurRadius: 10,
      offset: const Offset(0, 1),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final name = member?.name ?? 'Aida Member';
    final initial = member?.initial ?? 'A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AidaColors.cardWhite.withValues(alpha: 0.22),
                border: Border.all(
                  color: AidaColors.cardWhite.withValues(alpha: 0.55),
                ),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: AidaType.serif(size: 19, color: AidaColors.cardWhite),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _partOfDay(),
                    style: AidaType.sans(
                      size: 13,
                      color: AidaColors.cardWhite,
                    ).copyWith(shadows: _whiteGlow),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AidaType.serif(
                      size: 26,
                      color: AidaColors.cardWhite,
                    ).copyWith(shadows: _whiteGlow),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _NotificationBell(onTap: onNotifications),
          ],
        ),
        const SizedBox(height: 18),
        loyalty ?? const _Skeleton(height: 200),
        const SizedBox(height: 20),
        _QuickActionsRow(
          onScan: onScan,
          onOrders: onOrders,
          onFavorites: onFavorites,
          onRedeem: onRedeem,
        ),
      ],
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AidaColors.cardWhite.withValues(alpha: 0.22),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const Padding(
          padding: EdgeInsets.all(11),
          child: Icon(
            Icons.notifications_none_rounded,
            size: 20,
            color: AidaColors.cardWhite,
          ),
        ),
      ),
    );
  }
}

/// Scan, Orders, Favorites, and Redeem as one row of outline circles.
class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.onScan,
    required this.onOrders,
    required this.onFavorites,
    required this.onRedeem,
  });

  final VoidCallback onScan;
  final VoidCallback onOrders;
  final VoidCallback onFavorites;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _QuickAction(
          icon: Icons.qr_code_2_rounded,
          label: 'Scan',
          onTap: onScan,
        ),
        _QuickAction(
          icon: Icons.receipt_long_rounded,
          label: 'Orders',
          onTap: onOrders,
        ),
        _QuickAction(
          icon: Icons.favorite_border_rounded,
          label: 'Favorites',
          onTap: onFavorites,
        ),
        _QuickAction(
          icon: Icons.card_giftcard_rounded,
          label: 'Redeem',
          onTap: onRedeem,
          solid: true,
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.solid = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Redeem uses a filled coffee circle so it still reads as the primary
  /// loyalty action while sitting in the same row as the others.
  final bool solid;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    solid
                        ? AidaColors.coffee
                        : AidaColors.cardWhite.withValues(alpha: 0.9),
                border:
                    solid
                        ? null
                        : Border.all(
                          color: AidaColors.coffee.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                boxShadow:
                    solid
                        ? [
                          BoxShadow(
                            color: AidaColors.coffee.withValues(alpha: 0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                        : null,
              ),
              child: Icon(
                icon,
                size: 23,
                color: solid ? AidaColors.cardWhite : AidaColors.coffee,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AidaType.sans(
                size: 12,
                weight: FontWeight.w600,
                color: AidaColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Balance row + weekday check-in card. Stamp ring stays beside the points;
/// the dots are Mon–Sun so the customer can check in for the day.
class _LoyaltyInfo extends StatefulWidget {
  const _LoyaltyInfo({required this.points, required this.stamps});

  final Points points;
  final StampCard stamps;

  @override
  State<_LoyaltyInfo> createState() => _LoyaltyInfoState();
}

class _LoyaltyInfoState extends State<_LoyaltyInfo> {
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// Which weekdays (1=Mon … 7=Sun) are already checked in this week.
  /// Seeded with earlier days of the week for a realistic demo; today starts
  /// unchecked so tapping it does something.
  late final Set<int> _checkedDays;

  @override
  void initState() {
    super.initState();
    final today = clock.now().weekday;
    _checkedDays = {for (var d = 1; d < today; d++) d};
  }

  int get _today => clock.now().weekday;

  int get _streak => _checkedDays.length;

  void _onDayTap(int weekday) {
    if (weekday != _today) {
      AidaPopup.show(
        context,
        title:
            weekday < _today
                ? 'Already checked in'
                : 'Come back on ${_weekdays[weekday - 1]}',
      );
      return;
    }

    if (_checkedDays.contains(_today)) {
      AidaPopup.show(context, title: 'You already checked in today');
      return;
    }

    setState(() => _checkedDays.add(_today));
    AidaPopup.show(context, title: 'Checked in', message: 'See you tomorrow.');
  }

  @override
  Widget build(BuildContext context) {
    final stamps = widget.stamps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    widget.points.formatted,
                    style: AidaType.serif(size: 44, color: AidaColors.espresso),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Aida Points',
                    style: AidaType.sans(
                      size: 16,
                      weight: FontWeight.w600,
                      color: AidaColors.coffee,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AidaColors.cardWhite,
                boxShadow: [
                  BoxShadow(
                    color: AidaColors.espresso.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: StampRing(card: stamps, size: 96),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            color: AidaColors.cardWhite,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AidaColors.espresso.withValues(alpha: 0.07),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _streak == 0
                          ? 'Daily check-in'
                          : _streak == 1
                          ? "You've checked in for 1 day"
                          : "You've checked in for $_streak days",
                      style: AidaType.sans(
                        size: 15,
                        weight: FontWeight.w700,
                        color: AidaColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    'This week',
                    style: AidaType.sans(
                      size: 12,
                      weight: FontWeight.w600,
                      color: AidaColors.coffee,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < 7; i++)
                    _WeekdayCheckIn(
                      label: _weekdays[i],
                      checked: _checkedDays.contains(i + 1),
                      isToday: i + 1 == _today,
                      onTap: () => _onDayTap(i + 1),
                    ),
                ],
              ),
              if (stamps.freeDrinksAvailable > 0) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AidaColors.latte.withValues(alpha: 0.55),
                        AidaColors.rewardGold.withValues(alpha: 0.22),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AidaColors.rewardGold.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AidaColors.coffee,
                        ),
                        child: const Icon(
                          Icons.card_giftcard_rounded,
                          size: 14,
                          color: AidaColors.cream,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          stamps.freeDrinksAvailable == 1
                              ? 'Free drink ready, show your QR'
                              : '${stamps.freeDrinksAvailable} free drinks ready, show your QR',
                          textAlign: TextAlign.center,
                          style: AidaType.sans(
                            size: 12.5,
                            weight: FontWeight.w700,
                            color: AidaColors.coffee,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _WeekdayCheckIn extends StatelessWidget {
  const _WeekdayCheckIn({
    required this.label,
    required this.checked,
    required this.isToday,
    required this.onTap,
  });

  final String label;
  final bool checked;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient:
                  checked
                      ? LinearGradient(
                        colors: [
                          AidaColors.rewardGold,
                          AidaColors.rewardGoldDeep,
                        ],
                      )
                      : null,
              color:
                  checked
                      ? null
                      : isToday
                      ? AidaColors.coffee.withValues(alpha: 0.12)
                      : AidaColors.latte.withValues(alpha: 0.5),
              border: Border.all(
                color:
                    isToday && !checked
                        ? AidaColors.coffee
                        : checked
                        ? Colors.transparent
                        : AidaColors.coffee.withValues(alpha: 0.15),
                width: isToday && !checked ? 1.6 : 1,
              ),
            ),
            child:
                checked
                    ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: AidaColors.espresso,
                    )
                    : isToday
                    ? Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: AidaColors.coffee,
                    )
                    : null,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AidaType.sans(
              size: 10,
              weight: isToday ? FontWeight.w700 : FontWeight.w500,
              color: isToday ? AidaColors.coffee : AidaColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Calm placeholder while data loads. A spinner on every card would make the
/// whole screen flicker.
class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AidaColors.latte.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(22),
      ),
    );
  }
}
