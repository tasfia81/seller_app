import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_data.dart';
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

final productRepositoryProvider = Provider<ProductRepository>((_) => PreviewProductRepository());

final assignedProductsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) => ref.watch(productRepositoryProvider).getAssignedProducts());

final productProvider = FutureProvider.autoDispose.family<Product, String>(
    (ref, id) => ref.watch(productRepositoryProvider).getProduct(id));
