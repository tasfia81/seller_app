import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Placeholder brand mark (shopping bag). Swap for the real logo asset.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 72, this.inverted = false});

  final double size;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: inverted ? Colors.white : AppColors.primary,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(
        Icons.shopping_bag_outlined,
        size: size * 0.52,
        color: inverted ? AppColors.darkGreen : Colors.white,
        semanticLabel: 'স্ট্রিট সেলস লোগো',
      ),
    );
  }
}
