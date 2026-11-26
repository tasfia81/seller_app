import '../../../shared/models/enums.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_data.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/seller_payload.dart';
import '../../../core/constants/app_config.dart';
import '../../auth/data/seller_session.dart';
import '../../../core/errors/failure.dart';
import '../../../shared/models/product.dart';
import '../domain/product_repository.dart';

/// Preview implementation. Replace with the FastAPI-backed repository.
class PreviewProductRepository implements ProductRepository {
  @override
  Future<List<Product>> getAssignedProducts() async {
    DemoData.ensureEnabled();
    return DemoData.products;
  }

  @override
  Future<Product> getProduct(String id) async {
    DemoData.ensureEnabled();
    return DemoData.products.firstWhere((p) => p.id == id,
        orElse: () => throw const ValidationFailure('পণ্যটি আর আপনার তালিকায় নেই।'));
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) => AppConfig.previewAuth
    ? PreviewProductRepository()
    : ApiProductRepository(ref.watch(sellerSessionProvider).api));

final assignedProductsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) => ref.watch(productRepositoryProvider).getAssignedProducts());

final productProvider = FutureProvider.autoDispose.family<Product, String>(
    (ref, id) => ref.watch(productRepositoryProvider).getProduct(id));

class ApiProductRepository implements ProductRepository {
  ApiProductRepository(this.api);
  final ApiClient api;

  Product _parse(Json row) {
    final stock = jsonMap(row['variant_stock']);
    final editable = row['price_editable'] == true;
    return Product(
      id: row['id'] as String,
      name: row['name'] as String,
      category: (row['category_name'] ?? row['category_id']) as String,
      unit: parseUnit(row['unit']),
      price: number(row, 'price'),
      availableQty: number(row, 'available_qty'),
      variants: stock.keys.toList(),
      variantStock: stock.map((key, value) => MapEntry(key, (value as num).toDouble())),
      paymentMethods: [
        for (final method in PaymentMethod.values)
          if ((row['payment_methods'] as List).contains(method.name)) method,
      ],
      variantLabel: row['variant_label'] as String?,
      minPrice: editable ? (row['min_price'] as num?)?.toDouble() : null,
      maxPrice: editable ? (row['max_price'] as num?)?.toDouble() : null,
      lowStockThreshold: number(row, 'low_stock_at'),
      imageUrl: row['image_url'] as String?,
    );
  }

  @override
  Future<List<Product>> getAssignedProducts() async =>
      jsonRows(await api.get('/seller/products')).map(_parse).toList();

  @override
  Future<Product> getProduct(String id) async =>
      _parse(jsonMap(await api.get('/seller/products/${Uri.encodeComponent(id)}')));
}
