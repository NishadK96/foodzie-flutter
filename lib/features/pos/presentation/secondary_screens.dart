import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/money.dart';
import '../domain/models.dart';
import '../data/pos_data_controller.dart';
import 'food_image.dart';
import 'pos_controller.dart';
import 'shell.dart';

class _Page extends StatelessWidget {
  const _Page({
    required this.title,
    required this.subtitle,
    required this.active,
    required this.child,
  });
  final String title, subtitle, active;
  final Widget child;
  @override
  Widget build(BuildContext context) => FoodzyShell(
    active: active,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: FoodzyColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 22),
          Expanded(child: child),
        ],
      ),
    ),
  );
}

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(posControllerProvider).orders;
    final liveOrders = ref.watch(posDataControllerProvider).value?.orders;
    if (liveOrders != null) {
      return _Page(
        title: 'Orders',
        subtitle: 'Live orders from this branch',
        active: '/orders',
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(posDataControllerProvider.notifier).refresh(),
          child: _LiveRecordList(
            rows: liveOrders,
            emptyText: 'No orders have been created yet',
            title: (row) => _firstText(row, [
              'formatted_order_number',
              'order_number',
              'id',
            ], prefix: 'Order '),
            subtitle: (row) => [
              _firstText(row, ['order_type', 'status', 'order_status']),
              if (row['date_time'] != null) '${row['date_time']}',
            ].where((value) => value.isNotEmpty).join(' · '),
            trailing: (row) => _moneyFrom(row, ['total', 'grand_total']),
          ),
        ),
      );
    }
    return _Page(
      title: 'Orders',
      subtitle: 'Recent payments and completed orders',
      active: '/orders',
      child: ListView.separated(
        itemCount: orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 9),
        itemBuilder: (context, index) {
          final order = orders[index];
          return Card(
            elevation: 0,
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.receipt_long_outlined),
              ),
              title: Text(
                order.id,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                'Table ${order.tableNumber ?? 'Takeaway'} · ${order.method.name.toUpperCase()} · ${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}',
              ),
              trailing: Text(
                money(order.totalPaise),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              onTap: () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(order.id),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total: ${money(order.totalPaise)}'),
                      for (final line in order.lines)
                        Text('${line.quantity} × ${line.product.name}'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class TablesScreen extends ConsumerWidget {
  const TablesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tables = ref.watch(posControllerProvider).tables;
    return _Page(
      title: 'Tables',
      subtitle: 'Select a table to continue its order',
      active: '/tables',
      child: LayoutBuilder(
        builder: (context, size) => GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: (size.maxWidth / 190).floor().clamp(2, 6),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 138,
          ),
          itemCount: tables.length,
          itemBuilder: (context, index) {
            final table = tables[index];
            final color = table.status == TableStatus.available
                ? FoodzyColors.positive
                : table.status == TableStatus.occupied
                ? FoodzyColors.primary
                : Colors.orange;
            return InkWell(
              onTap: () {
                ref
                    .read(posControllerProvider.notifier)
                    .selectTable(table.number);
                context.go('/pos');
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: FoodzyColors.border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.table_restaurant_outlined,
                      color: color,
                      size: 28,
                    ),
                    const Spacer(),
                    Text(
                      'Table ${table.number.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${table.seats} seats · ${table.status.name}',
                      style: TextStyle(color: color, fontSize: 11),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class KitchenScreen extends ConsumerWidget {
  const KitchenScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(posControllerProvider).tickets;
    final liveTickets = ref.watch(posDataControllerProvider).value?.kots;
    if (liveTickets != null) {
      return _Page(
        title: 'Kitchen display',
        subtitle: 'Live kitchen order tickets',
        active: '/kitchen',
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(posDataControllerProvider.notifier).refresh(),
          child: _LiveKitchenList(rows: liveTickets),
        ),
      );
    }
    return _Page(
      title: 'Kitchen display',
      subtitle: 'Move tickets from new to preparing to ready',
      active: '/kitchen',
      child: LayoutBuilder(
        builder: (context, size) => GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: (size.maxWidth / 280).floor().clamp(1, 4),
            mainAxisExtent: 228,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: tickets.length,
          itemBuilder: (context, index) {
            final ticket = tickets[index];
            final color = ticket.status == TicketStatus.newOrder
                ? FoodzyColors.primary
                : ticket.status == TicketStatus.preparing
                ? Colors.orange
                : FoodzyColors.positive;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: FoodzyColors.border),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        ticket.id,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      Text(
                        ticket.status == TicketStatus.newOrder
                            ? 'New'
                            : ticket.status.name,
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Table ${ticket.tableNumber ?? 'Takeaway'}',
                    style: const TextStyle(color: FoodzyColors.muted),
                  ),
                  const Divider(),
                  ...ticket.items
                      .take(3)
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(
                            item,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: ticket.status == TicketStatus.ready
                          ? null
                          : () => ref
                                .read(posControllerProvider.notifier)
                                .setTicketStatus(
                                  ticket.id,
                                  ticket.status == TicketStatus.newOrder
                                      ? TicketStatus.preparing
                                      : TicketStatus.ready,
                                ),
                      child: Text(
                        ticket.status == TicketStatus.newOrder
                            ? 'Start preparing'
                            : ticket.status == TicketStatus.preparing
                            ? 'Mark ready'
                            : 'Ready',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LiveKitchenList extends ConsumerWidget {
  const _LiveKitchenList({required this.rows});

  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (rows.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 100),
          Icon(Icons.inbox_outlined, size: 46, color: FoodzyColors.muted),
          SizedBox(height: 12),
          Center(
            child: Text(
              'No kitchen tickets are pending',
              style: TextStyle(color: FoodzyColors.muted),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final row = rows[index];
        final status = '${row['status'] ?? 'pending_confirmation'}';
        final nextStatus = switch (status) {
          'pending_confirmation' => 'in_kitchen',
          'in_kitchen' => 'food_ready',
          'food_ready' => 'served',
          _ => null,
        };
        final actionLabel = switch (nextStatus) {
          'in_kitchen' => 'Start preparing',
          'food_ready' => 'Mark ready',
          'served' => 'Mark served',
          _ => status == 'cancelled' ? 'Cancelled' : 'Completed',
        };
        return Card(
          elevation: 0,
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.soup_kitchen_outlined),
            ),
            title: Text(
              _firstText(row, [
                'kot_number',
                'token_number',
                'id',
              ], prefix: 'KOT '),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(_kitchenStatusLabel(status)),
            trailing: FilledButton.tonal(
              onPressed: nextStatus == null
                  ? null
                  : () async {
                      final id = int.tryParse('${row['id']}');
                      if (id == null) return;
                      try {
                        await ref
                            .read(posApiRepositoryProvider)
                            .updateKotStatus(id, nextStatus);
                        await ref
                            .read(posDataControllerProvider.notifier)
                            .refresh();
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.toString())),
                          );
                        }
                      }
                    },
              child: Text(actionLabel),
            ),
          ),
        );
      },
    );
  }
}

String _kitchenStatusLabel(String status) => switch (status) {
  'pending_confirmation' => 'Pending confirmation',
  'in_kitchen' => 'Preparing',
  'food_ready' => 'Ready for service',
  'served' => 'Served',
  'cancelled' => 'Cancelled',
  _ => status.replaceAll('_', ' '),
};

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(menuRepositoryProvider).products;
    return _Page(
      title: 'Menu',
      subtitle: '${products.length} demo items across categories',
      active: '/menu',
      child: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Card(
            elevation: 0,
            child: ListTile(
              leading: SizedBox(
                width: 58,
                height: 58,
                child: FoodImage(index: product.imageIndex),
              ),
              title: Text(product.name),
              subtitle: Text(product.description),
              trailing: Text(money(product.pricePaise)),
            ),
          );
        },
      ),
    );
  }
}

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});
  @override
  Widget build(BuildContext context) => _Page(
    title: 'Inventory',
    subtitle: 'Demo stock overview',
    active: '/inventory',
    child: ListView(
      children: const [
        _InfoTile('Mozzarella', '8.5 kg available', Icons.inventory_2_outlined),
        _InfoTile(
          'Basmati rice',
          '22 kg available',
          Icons.inventory_2_outlined,
        ),
        _InfoTile('Chicken', '12 kg available', Icons.inventory_2_outlined),
        _InfoTile(
          'Fresh vegetables',
          '6.2 kg available',
          Icons.inventory_2_outlined,
        ),
      ],
    ),
  );
}

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(posDataControllerProvider).value?.customers;
    return _Page(
      title: 'Customers',
      subtitle: 'Customer directory for this restaurant',
      active: '/customers',
      child: customers == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(posDataControllerProvider.notifier).refresh(),
              child: _LiveRecordList(
                rows: customers,
                emptyText: 'No customers have been added yet',
                title: (row) => _firstText(row, ['name'], prefix: 'Customer '),
                subtitle: (row) => [
                  _firstText(row, ['phone']),
                  _firstText(row, ['email']),
                ].where((value) => value.isNotEmpty).join(' · '),
              ),
            ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile(this.title, this.subtitle, this.icon);
  final String title, subtitle;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
    ),
  );
}

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posControllerProvider);
    final live = ref.watch(posDataControllerProvider).value;
    final sales = live == null
        ? state.orders.fold<int>(0, (sum, order) => sum + order.totalPaise)
        : live.orders.fold<int>(
            0,
            (sum, row) =>
                sum +
                ((_numberValue(row['total'] ?? row['grand_total']) * 100)
                    .round()),
          );
    final orderCount = live?.orders.length ?? state.orders.length;
    final pendingTickets =
        live?.kots
            .where(
              (row) => ![
                'ready',
                'completed',
              ].contains('${row['status']}'.toLowerCase()),
            )
            .length ??
        state.pendingTickets;
    return _Page(
      title: 'Reports',
      subtitle: live == null ? 'Shift overview' : 'Live branch overview',
      active: '/reports',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _Metric('Total sales', money(sales), Icons.trending_up),
          _Metric('Orders', '$orderCount', Icons.receipt_long_outlined),
          _Metric(
            'Kitchen pending',
            '$pendingTickets',
            Icons.soup_kitchen_outlined,
          ),
          _Metric(
            'Cash shift',
            money(state.shiftTotalPaise),
            Icons.point_of_sale_outlined,
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.icon);
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: 220,
    height: 135,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: FoodzyColors.border),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: FoodzyColors.primary),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          style: const TextStyle(color: FoodzyColors.muted, fontSize: 12),
        ),
      ],
    ),
  );
}

class _LiveRecordList extends StatelessWidget {
  const _LiveRecordList({
    required this.rows,
    required this.emptyText,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final List<Map<String, dynamic>> rows;
  final String emptyText;
  final String Function(Map<String, dynamic>) title;
  final String Function(Map<String, dynamic>) subtitle;
  final String Function(Map<String, dynamic>)? trailing;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          Icon(Icons.inbox_outlined, size: 46, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Center(
            child: Text(
              emptyText,
              style: const TextStyle(color: FoodzyColors.muted),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final row = rows[index];
        final trailingText = trailing?.call(row) ?? '';
        return Card(
          elevation: 0,
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.receipt_long_outlined),
            ),
            title: Text(
              title(row),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(subtitle(row)),
            trailing: trailingText.isEmpty
                ? null
                : Text(
                    trailingText,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        );
      },
    );
  }
}

String _firstText(
  Map<String, dynamic> row,
  List<String> keys, {
  String prefix = '',
}) {
  for (final key in keys) {
    final value = row[key];
    if (value != null && '$value'.trim().isNotEmpty) return '$prefix$value';
  }
  return '';
}

String _moneyFrom(Map<String, dynamic> row, List<String> keys) {
  for (final key in keys) {
    final value = row[key];
    final amount = value is num ? value.toDouble() : double.tryParse('$value');
    if (amount != null) return money((amount * 100).round());
  }
  return '';
}

double _numberValue(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tax = ref.watch(
      posControllerProvider.select((state) => state.taxBasisPoints),
    );
    return _Page(
      title: 'Settings',
      subtitle: 'Local POS demo configuration',
      active: '/settings',
      child: Align(
        alignment: Alignment.topLeft,
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: FoodzyColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tax policy',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tax applies after discounts and rounds to the nearest rupee.',
                style: TextStyle(fontSize: 12, color: FoodzyColors.muted),
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<int>(
                initialValue: tax,
                decoration: const InputDecoration(labelText: 'Tax rate'),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('No tax')),
                  DropdownMenuItem(value: 500, child: Text('5%')),
                  DropdownMenuItem(value: 1200, child: Text('12%')),
                  DropdownMenuItem(value: 1800, child: Text('18%')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    ref.read(posControllerProvider.notifier).setTaxRate(value);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
