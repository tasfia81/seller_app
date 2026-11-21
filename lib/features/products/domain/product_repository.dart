import '../../../shared/models/product.dart';

abstract interface class ProductRepository {
  /// Products assigned to the signed-in seller only.
  Future<List<Product>> getAssignedProducts();
  Future<Product> getProduct(String id);
}
