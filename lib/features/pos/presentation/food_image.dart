import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Displays one tile of the bundled 4 × 3 food photography sheet.
class FoodImage extends StatelessWidget {
  const FoodImage({
    super.key,
    required this.index,
    this.borderRadius = const BorderRadius.all(Radius.circular(7)),
  });
  final int index;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: borderRadius,
    child: LayoutBuilder(
      builder: (context, size) {
        final tile = math.max(size.maxWidth, size.maxHeight);
        final beverage = index >= 12;
        final column = beverage ? (index - 12) % 4 : index % 4;
        final row = beverage ? 0 : index ~/ 4;
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: -column * tile + (size.maxWidth - tile) / 2,
              top: -row * tile + (size.maxHeight - tile) / 2,
              width: tile * 4,
              height: tile * (beverage ? 1 : 3),
              child: Image.asset(
                beverage
                    ? 'assets/images/beverage_contact_sheet.png'
                    : 'assets/images/menu_contact_sheet.png',
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ],
        );
      },
    ),
  );
}
