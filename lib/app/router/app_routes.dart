/// Centralized route path constants.
abstract class AppRoutes {
  static const splash = '/splash';

  // --- Auth ---
  static const phoneEntry = '/auth/phone-entry';
  static const otpVerification = '/auth/otp';
  static const roleSelection = '/role-selection';

  // --- Villager ---
  static const home = '/home';
  static const shopDetail = '/shop/:shopId';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const orderTracking = '/order/:orderId';
  static const orders = '/orders';
  static const profile = '/profile';
  static const chatList = '/chats';
  static const chatThread = '/chat/:threadId';

  // --- Vendor ---
  static const vendorHome = '/vendor/home';
  static const vendorProducts = '/vendor/products';

  // --- Driver ---
  static const driverHome = '/driver/home';

  // --- Admin ---
  static const adminHome = '/admin/home';

  // --- Helpers ---
  static String shopDetailPath(String shopId) => '/shop/$shopId';
  static String orderTrackingPath(String orderId) => '/order/$orderId';
  static String chatThreadPath(String threadId) => '/chat/$threadId';
}
