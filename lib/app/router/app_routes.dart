/// All route paths in one place.
abstract final class AppRoutes {
  static const splash = '/';
  static const intro = '/intro';
  static const welcome = '/welcome';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const register = '/register';
  static const applicationSubmitted = '/application-submitted';
  static const applicationStatus = '/application-status';

  // Bottom navigation tabs
  static const home = '/home';
  static const products = '/products';
  static const sales = '/sales';
  static const account = '/account';

  // Full-screen pages above the tabs
  static const productDetails = '/product/:id';
  static const quickSale = '/new-sale';
  static const saleSuccess = '/sale-success';
  static const saleDetails = '/sale-details/:id';
  static const earnings = '/earnings';
  static const inventory = '/inventory';
  static const stockReturn = '/stock-return';
  static const cashHandover = '/cash-handover';
  static const dayClosing = '/day-closing';
  static const notifications = '/notifications';
  static const profile = '/profile';
  static const settings = '/settings';
  static const support = '/support';
  static const supportChat = '/support/chat';

  static String product(String id) => '/product/$id';
  static String supportThread(String id) => '$supportChat?id=${Uri.encodeQueryComponent(id)}';
  static String supportNew(String topic, String label) =>
      '$supportChat?topic=${Uri.encodeQueryComponent(topic)}&label=${Uri.encodeQueryComponent(label)}';
  static String saleDetail(String id) => '/sale-details/$id';
  static String newSale({String? productId}) =>
      productId == null ? quickSale : '$quickSale?productId=$productId';
  static String returnFor({String? productId}) =>
      productId == null ? stockReturn : '$stockReturn?productId=$productId';
}
