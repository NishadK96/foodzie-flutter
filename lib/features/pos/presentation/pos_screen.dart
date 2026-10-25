import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../core/money.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/demo_repository.dart';
import '../data/live_menu_repository.dart';
import '../data/pos_data_controller.dart';
import '../domain/models.dart';
import 'food_image.dart';
import 'pos_controller.dart';
import 'order_panel.dart';
import 'shell.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});
  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  bool showTabletCart = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final auth = await ref.read(authControllerProvider.future);
      if (!mounted || !auth.authenticated) return;
      if (ref.read(menuRepositoryProvider) is DemoMenuRepository) {
        await ref.read(catalogControllerProvider.notifier).loadLive();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(posControllerProvider);
    final width = MediaQuery.sizeOf(context).width;
    final tablet = width < 1100;
    return FoodzyShell(
      active: '/pos',
      showSearch: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final categoryWidth = constraints.maxWidth < 900 ? 175.0 : 238.0;
          final orderWidth = constraints.maxWidth < 1250 ? 385.0 : 475.0;
          return Row(
            children: [
              if (!tablet)
                SizedBox(width: categoryWidth, child: const _CategorySidebar()),
              if (!(width < 650 && showTabletCart))
                Expanded(
                  child: Column(
                    children: [
                      if (tablet)
                        SizedBox(
                          height: 64,
                          child: _TabletCategoryStrip(
                            onCart: () => setState(() => showTabletCart = true),
                            itemCount: state.cart.fold<int>(
                              0,
                              (count, item) => count + item.quantity,
                            ),
                          ),
                        ),
                      const Expanded(child: _ProductArea()),
                    ],
                  ),
                ),
              if (!tablet)
                SizedBox(width: orderWidth, child: const ActiveOrderPanel()),
              if (tablet && showTabletCart)
                SizedBox(
                  width: width < 650
                      ? constraints.maxWidth
                      : constraints.maxWidth < 760
                      ? constraints.maxWidth * .62
                      : 385,
                  child: Stack(
                    children: [
                      const ActiveOrderPanel(),
                      Positioned(
                        right: 12,
                        top: 10,
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () =>
                              setState(() => showTabletCart = false),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CategorySidebar extends ConsumerWidget {
  const _CategorySidebar();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(menuRepositoryProvider).categories;
    final products = ref.watch(menuRepositoryProvider).products;
    final active = ref.watch(
      posControllerProvider.select((state) => state.category),
    );
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFCFBF9),
        border: Border(right: BorderSide(color: FoodzyColors.border)),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 20, 14, 16),
        children: [
          for (final category in categories)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Material(
                color: category.id == active
                    ? FoodzyColors.selected
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => ref
                      .read(posControllerProvider.notifier)
                      .setCategory(category.id),
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 51,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 48,
                          child: Icon(
                            _categoryIcon(category.iconKey),
                            size: 21,
                            color: category.id == active
                                ? FoodzyColors.primary
                                : FoodzyColors.text,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            category.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: category.id == active
                                  ? FoodzyColors.primary
                                  : FoodzyColors.text,
                              fontWeight: category.id == active
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (category.id != 'all')
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: const Color(0xFFF0EFED),
                              child: Text(
                                '${products.where((p) => p.categoryId == category.id).length}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: FoodzyColors.muted,
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
        ],
      ),
    );
  }
}

class _TabletCategoryStrip extends ConsumerWidget {
  const _TabletCategoryStrip({required this.onCart, required this.itemCount});
  final VoidCallback onCart;
  final int itemCount;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(menuRepositoryProvider).categories;
    final active = ref.watch(
      posControllerProvider.select((state) => state.category),
    );
    return Row(
      children: [
        Expanded(
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            children: [
              for (final category in categories)
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: ChoiceChip(
                    label: Text(category.name),
                    selected: category.id == active,
                    onSelected: (_) => ref
                        .read(posControllerProvider.notifier)
                        .setCategory(category.id),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: FilledButton.icon(
            onPressed: onCart,
            icon: const Icon(Icons.shopping_cart_outlined, size: 18),
            label: Text('Order ($itemCount)'),
          ),
        ),
      ],
    );
  }
}

IconData _categoryIcon(String key) => switch (key) {
  'all' => Icons.grid_view_rounded,
  'starters' => Icons.tapas_outlined,
  'soups' => Icons.ramen_dining_outlined,
  'salads' => Icons.eco_outlined,
  'mains' => Icons.dinner_dining_outlined,
  'rice' => Icons.rice_bowl_outlined,
  'pizzas' => Icons.local_pizza_outlined,
  'burgers' => Icons.lunch_dining_outlined,
  'sandwiches' => Icons.layers_outlined,
  'pasta' => Icons.restaurant_outlined,
  'chinese' => Icons.takeout_dining_outlined,
  'desserts' => Icons.cake_outlined,
  _ => Icons.local_cafe_outlined,
};

class _ProductArea extends ConsumerWidget {
  const _ProductArea();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posControllerProvider);
    final products = ref.read(posControllerProvider.notifier).visibleProducts();
    final category = ref
        .read(menuRepositoryProvider)
        .categories
        .firstWhere((cat) => cat.id == state.category);
    return LayoutBuilder(
      builder: (context, size) {
        final columns = size.maxWidth >= 570
            ? 3
            : size.maxWidth >= 390
            ? 2
            : 1;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 17, 17, 15),
              child: Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: category.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: ' (${products.length})',
                            style: const TextStyle(
                              fontSize: 15,
                              color: FoodzyColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (size.maxWidth >= 500) ...[
                    const Text(
                      'Sort by',
                      style: TextStyle(fontSize: 12, color: FoodzyColors.muted),
                    ),
                    const SizedBox(width: 7),
                  ],
                  Container(
                    height: 37,
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: FoodzyColors.border),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<SortMode>(
                        value: state.sort,
                        isDense: true,
                        style: const TextStyle(
                          fontSize: 12,
                          color: FoodzyColors.text,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: SortMode.popular,
                            child: Text('Popular'),
                          ),
                          DropdownMenuItem(
                            value: SortMode.name,
                            child: Text('Name'),
                          ),
                          DropdownMenuItem(
                            value: SortMode.priceLow,
                            child: Text('Price: Low'),
                          ),
                          DropdownMenuItem(
                            value: SortMode.priceHigh,
                            child: Text('Price: High'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            ref
                                .read(posControllerProvider.notifier)
                                .setSort(value);
                          }
                        },
                      ),
                    ),
                  ),
                  if (size.maxWidth >= 500) ...[
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      onPressed: state.grid
                          ? null
                          : ref.read(posControllerProvider.notifier).toggleGrid,
                      icon: const Icon(Icons.grid_view_rounded, size: 20),
                    ),
                    IconButton.filledTonal(
                      onPressed: !state.grid
                          ? null
                          : ref.read(posControllerProvider.notifier).toggleGrid,
                      icon: const Icon(Icons.view_list_outlined, size: 20),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: products.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 38,
                            color: FoodzyColors.muted,
                          ),
                          SizedBox(height: 10),
                          Text('No dishes match your search'),
                        ],
                      ),
                    )
                  : state.grid
                  ? GridView.builder(
                      padding: const EdgeInsets.fromLTRB(17, 0, 17, 20),
                      itemCount: products.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: size.maxWidth >= 500 ? 214 : 204,
                      ),
                      itemBuilder: (context, index) =>
                          _ProductCard(product: products[index]),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(17, 0, 17, 20),
                      itemCount: products.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ProductListTile(product: products[index]),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});
  final MenuProduct product;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: FoodzyColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => showProductCustomization(context, product),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 107,
            width: double.infinity,
            child: FoodImage(
              index: product.imageIndex,
              borderRadius: BorderRadius.zero,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 7, 10, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: FoodzyColors.muted,
                      height: 1.25,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        money(product.pricePaise),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      _VegMark(vegetarian: product.vegetarian),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ProductListTile extends StatelessWidget {
  const _ProductListTile({required this.product});
  final MenuProduct product;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: FoodzyColors.border),
    ),
    child: InkWell(
      onTap: () => showProductCustomization(context, product),
      child: SizedBox(
        height: 88,
        child: Row(
          children: [
            SizedBox(
              width: 100,
              height: 88,
              child: FoodImage(index: product.imageIndex),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    product.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: FoodzyColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              money(product.pricePaise),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 12),
            _VegMark(vegetarian: product.vegetarian),
            const SizedBox(width: 14),
          ],
        ),
      ),
    ),
  );
}

class _VegMark extends StatelessWidget {
  const _VegMark({required this.vegetarian});
  final bool vegetarian;
  @override
  Widget build(BuildContext context) => Container(
    width: 17,
    height: 17,
    decoration: BoxDecoration(
      border: Border.all(
        color: vegetarian ? FoodzyColors.positive : FoodzyColors.primary,
      ),
      borderRadius: BorderRadius.circular(2),
    ),
    child: Center(
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: vegetarian ? FoodzyColors.positive : FoodzyColors.primary,
          shape: BoxShape.circle,
        ),
      ),
    ),
  );
}

Future<void> showProductCustomization(
  BuildContext context,
  MenuProduct product,
) async {
  final container = ProviderScope.containerOf(context);
  var configuredProduct = product;
  if (product.groups.isEmpty &&
      container.read(menuRepositoryProvider) is! DemoMenuRepository) {
    try {
      final groups = await container
          .read(posApiRepositoryProvider)
          .modifiersFor(product.id);
      configuredProduct = product.copyWith(groups: groups);
    } catch (_) {
      // Items without modifier configuration remain orderable.
    }
  }
  if (!context.mounted) return;
  final chosen = <String, ModifierOption>{};
  final note = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setLocal) {
        final requiredMissing = configuredProduct.groups.any(
          (group) => group.required && !chosen.containsKey(group.id),
        );
        final price =
            configuredProduct.pricePaise +
            chosen.values.fold<int>(
              0,
              (sum, option) => sum + option.pricePaise,
            );
        return AlertDialog(
          titlePadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
          actionsPadding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
          title: SizedBox(
            height: 150,
            width: 420,
            child: Stack(
              children: [
                Positioned.fill(
                  child: FoodImage(
                    index: configuredProduct.imageIndex,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: IconButton.filledTonal(
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ],
            ),
          ),
          content: SizedBox(
            width: 420,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 390),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      configuredProduct.name,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      configuredProduct.description,
                      style: const TextStyle(
                        color: FoodzyColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 15),
                    for (final group in configuredProduct.groups) ...[
                      Row(
                        children: [
                          Text(
                            group.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (group.required)
                            const Text(
                              '  Required',
                              style: TextStyle(
                                color: FoodzyColors.primary,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      for (final option in group.options)
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: chosen.containsValue(option),
                          title: Text(
                            option.name,
                            style: const TextStyle(fontSize: 12),
                          ),
                          secondary: option.pricePaise == 0
                              ? null
                              : Text(
                                  '+ ${money(option.pricePaise)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                          onChanged: (selected) => setLocal(() {
                            if (!group.multiple) {
                              for (final candidate in group.options) {
                                chosen.remove(candidate.id);
                              }
                              chosen.remove(group.id);
                            }
                            if (selected == true) {
                              chosen[group.multiple ? option.id : group.id] =
                                  option;
                            } else {
                              chosen.remove(
                                group.multiple ? option.id : group.id,
                              );
                            }
                          }),
                        ),
                      const Divider(),
                    ],
                    TextField(
                      controller: note,
                      maxLength: 100,
                      decoration: const InputDecoration(
                        hintText: 'Item note (optional)',
                        prefixIcon: Icon(Icons.notes),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: requiredMissing
                    ? null
                    : () {
                        container
                            .read(posControllerProvider.notifier)
                            .addProduct(
                              configuredProduct,
                              chosen.values.toList(),
                              note: note.text.trim(),
                            );
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${configuredProduct.name} added to order',
                            ),
                          ),
                        );
                      },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('Add to order · ${money(price)}'),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
  note.dispose();
}
