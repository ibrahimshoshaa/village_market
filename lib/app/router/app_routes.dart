/// Centralized route path constants. Never hardcode path strings inline
/// elsewhere in the app — always reference these, so a path rename is a
/// one-file change.
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
  static const orderTracking = '/order/:orderId';
  static const profile = '/profile';

  // --- Vendor ---
  static const vendorHome = '/vendor/home';
  static const vendorProducts = '/vendor/products';

  // --- Driver ---
  static const driverHome = '/driver/home';

  // --- Admin ---
  static const adminHome = '/admin/home';

  static const checkout = '/checkout';

  static String shopDetailPath(String shopId) => '/shop/$shopId';
  static String orderTrackingPath(String orderId) => '/order/$orderId';
}
