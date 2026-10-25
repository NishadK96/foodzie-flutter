import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/money.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/pos_data_controller.dart';
import 'pos_controller.dart';

class FoodzyShell extends ConsumerWidget {
  const FoodzyShell({
    super.key,
    required this.child,
    required this.active,
    this.showSearch = false,
  });
  final Widget child;
  final String active;
  final bool showSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posControllerProvider);
    final live = ref.watch(posDataControllerProvider).value;
    final liveShiftPaise = live?.orders.fold<int>(
      0,
      (sum, row) =>
          sum +
          (((row['total'] is num
                      ? (row['total'] as num).toDouble()
                      : double.tryParse('${row['total']}') ?? 0) *
                  100)
              .round()),
    );
    final livePending = live?.kots
        .where(
          (row) => ![
            'ready',
            'completed',
          ].contains('${row['status']}'.toLowerCase()),
        )
        .length;
    final auth = ref.watch(authControllerProvider).value;
    final width = MediaQuery.sizeOf(context).width;
    final mobile = width < 650;
    final compact = width < 1120;
    final collapsed = compact || state.sidebarCollapsed;
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: mobile ? (showSearch ? 116 : 66) : 76,
            color: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: mobile
                  ? 12
                  : compact
                  ? 16
                  : 26,
            ),
            child: mobile
                ? Column(
                    children: [
                      const SizedBox(
                        height: 57,
                        child: Row(
                          children: [
                            Icon(
                              Icons.soup_kitchen_rounded,
                              color: FoodzyColors.primary,
                              size: 31,
                            ),
                            SizedBox(width: 7),
                            Text(
                              'Foodzy',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Spacer(),
                            Icon(
                              Icons.circle,
                              color: FoodzyColors.positive,
                              size: 11,
                            ),
                            SizedBox(width: 6),
                            Text('Online', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      if (showSearch)
                        Expanded(
                          child: TextField(
                            onChanged: ref
                                .read(posControllerProvider.notifier)
                                .setSearch,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search),
                              hintText: 'Search dishes...',
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      if (showSearch) const SizedBox(height: 9),
                    ],
                  )
                : Row(
                    children: [
                      SizedBox(
                        width: collapsed ? 175 : 268,
                        child: const Row(
                          children: [
                            Icon(
                              Icons.soup_kitchen_rounded,
                              color: FoodzyColors.primary,
                              size: 40,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Foodzy',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w800,
                                      height: 1.1,
                                    ),
                                  ),
                                  Text(
                                    'Restaurant POS',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: FoodzyColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (showSearch)
                        Flexible(
                          fit: FlexFit.loose,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: width >= 1400
                                  ? 550
                                  : width >= 1100
                                  ? 420
                                  : 300,
                            ),
                            child: TextField(
                              onChanged: ref
                                  .read(posControllerProvider.notifier)
                                  .setSearch,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.search),
                                hintText:
                                    'Search for dishes, e.g. biryani, pizza, burger...',
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      if (!compact) const Spacer(),
                      if (width >= 980)
                        const _HeaderStatus(
                          icon: Icons.circle,
                          iconColor: FoodzyColors.positive,
                          title: 'Online',
                          subtitle: 'Internet Connected',
                        ),
                      if (width >= 1180)
                        _HeaderStatus(
                          icon: Icons.point_of_sale_outlined,
                          title: 'Cash Shift',
                          subtitle:
                              'Open · ${money(liveShiftPaise ?? state.shiftTotalPaise)}',
                        ),
                      if (width >= 1300)
                        _HeaderStatus(
                          icon: Icons.soup_kitchen_outlined,
                          title: 'Kitchen',
                          subtitle:
                              '${livePending ?? state.pendingTickets} pending',
                        ),
                      if (width >= 850)
                        Padding(
                          padding: const EdgeInsets.only(left: 18),
                          child: PopupMenuButton<String>(
                            tooltip: 'Account',
                            onSelected: (value) async {
                              if (value != 'logout') return;
                              await ref
                                  .read(authControllerProvider.notifier)
                                  .logout();
                              if (context.mounted) context.go('/login');
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    Icon(Icons.logout, size: 19),
                                    SizedBox(width: 9),
                                    Text('Sign out'),
                                  ],
                                ),
                              ),
                            ],
                            child: const CircleAvatar(
                              backgroundColor: Color(0xFFE8E8E8),
                              child: Icon(
                                Icons.person,
                                color: FoodzyColors.muted,
                              ),
                            ),
                          ),
                        ),
                      if (width >= 960)
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth?.displayName ?? 'Demo Cashier',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                auth?.branch?['name']?.toString() ??
                                    'Demo Outlet',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: FoodzyColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: collapsed ? 68 : 200,
                  color: FoodzyColors.sidebar,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      for (final item in _nav)
                        _NavTile(
                          item: item,
                          selected: active == item.path,
                          collapsed: collapsed,
                          count: item.path == '/orders'
                              ? state.orders.length
                              : null,
                        ),
                      const Spacer(),
                      if (!compact)
                        InkWell(
                          onTap: ref
                              .read(posControllerProvider.notifier)
                              .toggleSidebar,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Icon(
                                  collapsed
                                      ? Icons.keyboard_double_arrow_right
                                      : Icons.keyboard_double_arrow_left,
                                  color: Colors.white70,
                                  size: 19,
                                ),
                                if (!collapsed)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 10),
                                    child: Text(
                                      'Collapse',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStatus extends StatelessWidget {
  const _HeaderStatus({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor = FoodzyColors.text,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(left: 17),
    padding: const EdgeInsets.only(left: 17),
    decoration: const BoxDecoration(
      border: Border(left: BorderSide(color: FoodzyColors.border)),
    ),
    child: Row(
      children: [
        Icon(icon, size: icon == Icons.circle ? 14 : 22, color: iconColor),
        const SizedBox(width: 10),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: FoodzyColors.muted),
            ),
          ],
        ),
      ],
    ),
  );
}

class _NavItem {
  const _NavItem(this.label, this.path, this.icon);
  final String label;
  final String path;
  final IconData icon;
}

const _nav = [
  _NavItem('POS', '/pos', Icons.home_outlined),
  _NavItem('Orders', '/orders', Icons.receipt_long_outlined),
  _NavItem('Tables', '/tables', Icons.table_restaurant_outlined),
  _NavItem('Menu', '/menu', Icons.restaurant_menu_outlined),
  _NavItem('Inventory', '/inventory', Icons.inventory_2_outlined),
  _NavItem('Customers', '/customers', Icons.people_outline),
  _NavItem('Reports', '/reports', Icons.bar_chart_outlined),
  _NavItem('Kitchen', '/kitchen', Icons.soup_kitchen_outlined),
  _NavItem('Settings', '/settings', Icons.settings_outlined),
];

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.collapsed,
    this.count,
  });
  final _NavItem item;
  final bool selected;
  final bool collapsed;
  final int? count;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: item.label,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Material(
        color: selected ? FoodzyColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: selected ? null : () => context.go(item.path),
          child: SizedBox(
            height: 49,
            child: Row(
              children: [
                SizedBox(
                  width: collapsed ? 48 : 54,
                  child: Icon(
                    item.icon,
                    color: selected ? Colors.white : const Color(0xFFDCE1E7),
                    size: 23,
                  ),
                ),
                if (!collapsed)
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected
                            ? Colors.white
                            : const Color(0xFFE4E7EB),
                      ),
                    ),
                  ),
                if (!collapsed && count != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: CircleAvatar(
                      radius: 11,
                      backgroundColor: FoodzyColors.primary,
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
