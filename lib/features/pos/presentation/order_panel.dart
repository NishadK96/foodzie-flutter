import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../core/money.dart';
import '../domain/models.dart';
import 'food_image.dart';
import 'pos_controller.dart';
import '../data/order_sync_controller.dart';

class ActiveOrderPanel extends ConsumerWidget {
  const ActiveOrderPanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posControllerProvider);
    final controller = ref.read(posControllerProvider.notifier);
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFCFBF9),
        border: Border(left: BorderSide(color: FoodzyColors.border)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 19, 16, 14),
            child: Row(
              children: [
                const Icon(Icons.table_restaurant_outlined, size: 23),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTable(context, ref),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.selectedTable == 0
                              ? 'Takeaway'
                              : 'Table ${state.selectedTable.toString().padLeft(2, '0')}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                state.selectedTable == 0
                                    ? 'Pickup Order'
                                    : '4 Guests · Dine In',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: FoodzyColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down, size: 17),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: FoodzyColors.selected,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    state.selectedTable == 0 ? 'Takeaway' : 'Dine In',
                    style: const TextStyle(
                      color: FoodzyColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Order options',
                  onSelected: (value) async {
                    if (value == 'table') {
                      _selectTable(context, ref);
                    }
                    if (value == 'clear') {
                      final yes = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Clear this order?'),
                          content: const Text(
                            'Only unsent items can be cleared.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                      );
                      if (yes == true && context.mounted) {
                        if (!controller.clearOrder()) {
                          _message(
                            context,
                            'Sent kitchen items cannot be cleared',
                          );
                        }
                      }
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'table', child: Text('Change table')),
                    PopupMenuItem(value: 'clear', child: Text('Clear order')),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: state.cart.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shopping_basket_outlined,
                          size: 42,
                          color: FoodzyColors.muted,
                        ),
                        SizedBox(height: 9),
                        Text(
                          'No items in this order',
                          style: TextStyle(color: FoodzyColors.muted),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                    itemCount: state.cart.length,
                    separatorBuilder: (_, _) => const Divider(height: 16),
                    itemBuilder: (context, index) =>
                        _OrderLineTile(line: state.cart[index]),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 3, 16, 0),
            child: TextFormField(
              key: ValueKey('note_${state.selectedTable}'),
              initialValue: state.activeNote,
              onChanged: controller.setOrderNote,
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.notes_outlined, size: 19),
                hintText: 'Add Notes (e.g. less spicy, no onion)',
                contentPadding: EdgeInsets.symmetric(vertical: 9),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 9, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: _OutlineAction(
                    label: 'Apply Discount',
                    icon: Icons.local_offer_outlined,
                    onTap: () => _discountDialog(context, ref),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _OutlineAction(
                    label: 'Apply Coupon',
                    icon: Icons.discount_outlined,
                    onTap: () => _couponDialog(context, ref),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _OutlineAction(
                    label: 'Split Bill',
                    icon: Icons.people_outline,
                    onTap: () =>
                        _paymentDialog(context, ref, splitInitially: true),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 5, 18, 0),
            child: Column(
              children: [
                _SummaryRow('Subtotal', money(state.bill.subtotalPaise)),
                _SummaryRow(
                  'Discount',
                  '− ${money(state.bill.discountPaise)}',
                  red: true,
                ),
                _SummaryRow(
                  'Tax (${(state.taxBasisPoints / 100).toStringAsFixed(state.taxBasisPoints % 100 == 0 ? 0 : 2)}%)',
                  money(state.bill.taxPaise),
                ),
                const Divider(height: 14),
                Row(
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      money(state.bill.totalPaise),
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 17),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        state.unsentItemCount == 0 ||
                            ref.watch(orderSyncControllerProvider).processing
                        ? null
                        : () async {
                            final id = await ref
                                .read(orderSyncControllerProvider.notifier)
                                .sendToKitchen();
                            if (!context.mounted) return;
                            final sync = ref.read(orderSyncControllerProvider);
                            if (sync.error != null) {
                              _message(context, sync.error!);
                            } else {
                              _message(
                                context,
                                id == null
                                    ? 'Order sent to kitchen'
                                    : 'Order #$id sent to kitchen',
                              );
                            }
                          },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: FoodzyColors.primary),
                      foregroundColor: FoodzyColors.primary,
                      minimumSize: const Size(0, 50),
                    ),
                    icon: const Icon(Icons.soup_kitchen_outlined, size: 20),
                    label: const Text(
                      'Send to Kitchen',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: state.cart.isEmpty
                        ? null
                        : () => _paymentDialog(context, ref),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 50),
                    ),
                    icon: const Icon(Icons.credit_card_outlined, size: 20),
                    label: const Text(
                      'Charge',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderLineTile extends ConsumerWidget {
  const _OrderLineTile({required this.line});
  final CartLine line;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(posControllerProvider.notifier);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 68,
            height: 68,
            child: FoodImage(index: line.product.imageIndex),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        line.product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      money(line.product.pricePaise),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 29,
                        minHeight: 29,
                      ),
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: FoodzyColors.primary,
                      ),
                      onPressed: () {
                        if (!controller.removeLine(line.key)) {
                          _message(context, 'Kitchen items cannot be removed');
                        }
                      },
                    ),
                  ],
                ),
                for (final modifier in line.modifiers)
                  Text(
                    '• ${modifier.name}${modifier.pricePaise > 0 ? '   + ${money(modifier.pricePaise)}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: FoodzyColors.muted,
                    ),
                  ),
                if (line.note.isNotEmpty)
                  Text(
                    '• ${line.note}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: FoodzyColors.muted,
                    ),
                  ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    _QuantityButton(
                      Icons.remove,
                      onTap:
                          line.quantity <= 1 ||
                              line.quantity <= line.sentQuantity
                          ? null
                          : () => controller.changeQuantity(line.key, -1),
                    ),
                    SizedBox(
                      width: 29,
                      child: Text(
                        '${line.quantity}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _QuantityButton(
                      Icons.add,
                      onTap: () => controller.changeQuantity(line.key, 1),
                    ),
                    const Spacer(),
                    Text(
                      money(line.totalPaise),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (line.sentQuantity > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${line.sentQuantity} sent to kitchen',
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: FoodzyColors.positive,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton(this.icon, {this.onTap});
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(5),
    child: Container(
      width: 27,
      height: 25,
      decoration: BoxDecoration(
        border: Border.all(color: FoodzyColors.border),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Icon(
        icon,
        size: 15,
        color: onTap == null ? FoodzyColors.border : FoodzyColors.text,
      ),
    ),
  );
}

class _OutlineAction extends StatelessWidget {
  const _OutlineAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      foregroundColor: FoodzyColors.text,
      side: const BorderSide(color: FoodzyColors.border),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      minimumSize: const Size(0, 37),
    ),
    icon: Icon(icon, size: 17),
    label: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(label, style: const TextStyle(fontSize: 11)),
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.amount, {this.red = false});
  final String label;
  final String amount;
  final bool red;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const Spacer(),
        Text(
          amount,
          style: TextStyle(
            fontSize: 12,
            color: red ? FoodzyColors.primary : FoodzyColors.text,
          ),
        ),
      ],
    ),
  );
}

void _message(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );

Future<void> _selectTable(BuildContext context, WidgetRef ref) async {
  final tables = ref.read(posControllerProvider).tables;
  final choice = await showDialog<int>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Select order location'),
      content: SizedBox(
        width: 400,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              label: const Text('Takeaway'),
              onPressed: () => Navigator.pop(context, 0),
            ),
            for (final table in tables)
              ActionChip(
                label: Text('Table ${table.number.toString().padLeft(2, '0')}'),
                avatar: Icon(
                  Icons.circle,
                  size: 10,
                  color: table.status == TableStatus.available
                      ? FoodzyColors.positive
                      : table.status == TableStatus.occupied
                      ? FoodzyColors.primary
                      : Colors.orange,
                ),
                onPressed: () => Navigator.pop(context, table.number),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
  if (choice != null) {
    ref.read(posControllerProvider.notifier).selectTable(choice);
  }
}

Future<void> _discountDialog(BuildContext context, WidgetRef ref) async {
  final state = ref.read(posControllerProvider);
  final amount = TextEditingController(
    text: '${state.fixedDiscountPaise ~/ 100}',
  );
  final percent = TextEditingController(
    text: '${state.percentageDiscountBasisPoints / 100}',
  );
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Apply discount'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Fixed discount (₹)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: percent,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Percentage discount (%)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final fixed = int.tryParse(amount.text) ?? 0;
            final pct = double.tryParse(percent.text) ?? 0;
            ref.read(posControllerProvider.notifier)
              ..setFixedDiscount(fixed * 100)
              ..setPercentDiscount((pct * 100).round());
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    ),
  );
  amount.dispose();
  percent.dispose();
}

Future<void> _couponDialog(BuildContext context, WidgetRef ref) async {
  final code = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Apply coupon'),
      content: SizedBox(
        width: 320,
        child: TextField(
          controller: code,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Coupon code',
            helperText: 'Try FOODZY100 for ₹100 off',
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (code.text.trim().toUpperCase() == 'FOODZY100') {
              ref.read(posControllerProvider.notifier).setFixedDiscount(10000);
              Navigator.pop(context);
              _message(context, 'Coupon applied');
            } else {
              _message(context, 'Invalid coupon code');
            }
          },
          child: const Text('Apply'),
        ),
      ],
    ),
  );
  code.dispose();
}

Future<void> _paymentDialog(
  BuildContext context,
  WidgetRef ref, {
  bool splitInitially = false,
}) async {
  final state = ref.read(posControllerProvider);
  if (state.cart.isEmpty) {
    _message(context, 'Add an item before checkout');
    return;
  }
  final total = state.bill.totalPaise;
  PaymentMethod method = PaymentMethod.cash;
  bool split = splitInitially;
  final tendered = TextEditingController(text: '${total ~/ 100}');
  final cashPart = TextEditingController(text: '${total ~/ 200}');
  final result = await showDialog<CompletedOrder>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setLocal) {
        final cashPaise = (int.tryParse(cashPart.text) ?? 0) * 100;
        final cardPaise = total - cashPaise;
        final changePaise = ((int.tryParse(tendered.text) ?? 0) * 100 - total)
            .clamp(0, 1 << 60);
        return AlertDialog(
          title: const Text('Charge order'),
          content: SizedBox(
            width: 390,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  money(total),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Select payment method',
                  style: TextStyle(color: FoodzyColors.muted),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Split payment'),
                  value: split,
                  onChanged: (value) => setLocal(() => split = value),
                ),
                if (split) ...[
                  TextField(
                    controller: cashPart,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setLocal(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Cash amount (₹)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Card balance: ${money(cardPaise.clamp(0, total))}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ] else ...[
                  SegmentedButton<PaymentMethod>(
                    segments: const [
                      ButtonSegment(
                        value: PaymentMethod.cash,
                        label: Text('Cash'),
                        icon: Icon(Icons.payments_outlined),
                      ),
                      ButtonSegment(
                        value: PaymentMethod.card,
                        label: Text('Card'),
                        icon: Icon(Icons.credit_card_outlined),
                      ),
                      ButtonSegment(
                        value: PaymentMethod.upi,
                        label: Text('UPI'),
                        icon: Icon(Icons.qr_code),
                      ),
                    ],
                    selected: {method},
                    onSelectionChanged: (selection) =>
                        setLocal(() => method = selection.first),
                  ),
                  if (method == PaymentMethod.cash) ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: tendered,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setLocal(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Cash tendered (₹)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Change due: ${money(changePaise)}'),
                  ],
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed:
                  (split && (cashPaise < 0 || cashPaise > total)) ||
                      (!split &&
                          method == PaymentMethod.cash &&
                          (int.tryParse(tendered.text) ?? 0) * 100 < total)
                  ? null
                  : () async {
                      final order = await ref
                          .read(orderSyncControllerProvider.notifier)
                          .completePayment(
                            split ? PaymentMethod.cash : method,
                            payments: split
                                ? [
                                    PaymentAllocation(
                                      PaymentMethod.cash,
                                      cashPaise,
                                    ),
                                    PaymentAllocation(
                                      PaymentMethod.card,
                                      cardPaise,
                                    ),
                                  ]
                                : const [],
                          );
                      if (!dialogContext.mounted) return;
                      final error = ref.read(orderSyncControllerProvider).error;
                      if (error != null) {
                        _message(dialogContext, error);
                        return;
                      }
                      Navigator.pop(dialogContext, order);
                    },
              child: const Text('Confirm payment'),
            ),
          ],
        );
      },
    ),
  );
  tendered.dispose();
  cashPart.dispose();
  if (result != null && context.mounted) {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.id,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text('Total paid: ${money(result.totalPaise)}'),
            Text('Table: ${result.tableNumber ?? 'Takeaway'}'),
            const SizedBox(height: 8),
            for (final payment in result.payments)
              Text(
                '${payment.method.name.toUpperCase()}: ${money(payment.amountPaise)}',
              ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
