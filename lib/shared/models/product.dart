import 'enums.dart';

/// A product assigned to the current seller. Purchase cost and margin are
/// intentionally absent: the seller app never receives them.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.price,
    required this.availableQty,
    this.variantLabel,
    this.variants = const [],
    this.minPrice,
    this.maxPrice,
    this.lowStockThreshold = 5,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String category;
  final UnitType unit;
  final double price;
  final double availableQty;
  final String? variantLabel; // e.g. "সাইজ"
  final List<String> variants; // e.g. S, M, L
  final double? minPrice;
  final double? maxPrice;
  final double lowStockThreshold;
  final String? imageUrl;

  bool get isPriceFlexible => minPrice != null && maxPrice != null;
  bool get isOutOfStock => availableQty <= 0;
  bool get isLowStock => !isOutOfStock && availableQty <= lowStockThreshold;
}
