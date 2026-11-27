import 'package:flutter/material.dart';

/// Outlined logo tile (trend arrow) used on green backgrounds.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 44, this.outlined = true});

  final double size;
  final bool outlined;


  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        border: outlined ? Border.all(color: Colors.white, width: 1.4) : null,
      ),
      child: Icon(Icons.trending_up_rounded, color: Colors.white, size: size * 0.55),
    );
  }
}
