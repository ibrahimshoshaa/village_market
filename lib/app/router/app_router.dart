import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/domain/entities/user_role.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/auth/presentation/screens/phone_entry_screen.dart';
import '../../features/auth/presentation/screens/role_selection_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/admin_panel/presentation/screens/admin_home_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/driver_dashboard/presentation/screens/driver_home_screen.dart';
import '../../features/orders/presentation/screens/order_history_screen.dart';
import '../../features/orders/presentation/screens/order_tracking_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/shops/presentation/screens/shop_detail_screen.dart';
import '../../features/shops/presentation/screens/shop_list_screen.dart';
import '../../features/vendor_dashboard/presentation/screens/manage_products_screen.dart';
import '../../features/vendor_dashboard/presentation/screens/vendor_dashboard_screen.dart';
import '../shells/driver_shell.dart';
import '../shells/vendor_shell.dart';
import '../shells/villager_shell.dart';
import 'app_routes.dart';
import 'route_guards.dart';

part 'app_router.g.dart';

/// See Phase 1.4 of the blueprint for the full role-based routing
/// rationale. Remember: this guards UX navigation only — Firestore
/// Security Rules (Phase 6) are the actual authorization boundary.
@riverpod
GoRouter appRouter(Ref ref) {
  final authGuard = AuthGuard(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) => authGuard.call(context, state),
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),

      // --- AUTH ---
      GoRoute(path: AppRoutes.phoneEntry, builder: (_, __) => const PhoneEntryScreen()),
      GoRoute(path: AppRoutes.otpVerification, builder: (_, __) => const OtpVerificationScreen()),
      GoRoute(path: AppRoutes.roleSelection, builder: (_, __) => const RoleSelectionScreen()),

      // --- VILLAGER ---
      ShellRoute(
        builder: (context, state, child) => VillagerShell(child: child),
        routes: [
          GoRoute(path: AppRoutes.home, builder: (_, __) => const ShopListScreen()),
          GoRoute(
            path: AppRoutes.shopDetail,
            builder: (_, s) => ShopDetailScreen(shopId: s.pathParameters['shopId']!),
          ),
          GoRoute(path: AppRoutes.cart, builder: (_, __) => const CartScreen()),
          GoRoute(path: '/orders', builder: (_, __) => const OrderHistoryScreen()),
          GoRoute(
            path: AppRoutes.orderTracking,
            redirect: (context, state) {
              final role = ref.read(currentUserRoleProvider);
              return const RoleGuard([UserRole.villager]).check(role, AppRoutes.home);
            },
            builder: (_, s) => OrderTrackingScreen(orderId: s.pathParameters['orderId']!),
          ),
          GoRoute(path: AppRoutes.profile, builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // --- VENDOR (gated) ---
      ShellRoute(
        builder: (context, state, child) => VendorShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.vendorHome,
            redirect: (context, state) {
              final role = ref.read(currentUserRoleProvider);
              return const RoleGuard([UserRole.vendor]).check(role, AppRoutes.home);
            },
            builder: (_, __) => const VendorDashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.vendorProducts,
            redirect: (context, state) {
              final role = ref.read(currentUserRoleProvider);
              return const RoleGuard([UserRole.vendor]).check(role, AppRoutes.home);
            },
            builder: (_, __) => const ManageProductsScreen(),
          ),
        ],
      ),

      // --- DRIVER (gated) ---
      ShellRoute(
        builder: (context, state, child) => DriverShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.driverHome,
            redirect: (context, state) {
              final role = ref.read(currentUserRoleProvider);
              return const RoleGuard([UserRole.driver]).check(role, AppRoutes.home);
            },
            builder: (_, __) => const DriverHomeScreen(),
          ),
        ],
      ),

      // --- ADMIN (gated, strictest) ---
      GoRoute(
        path: AppRoutes.adminHome,
        redirect: (context, state) {
          final role = ref.read(currentUserRoleProvider);
          return const RoleGuard([UserRole.admin]).check(role, AppRoutes.home);
        },
        builder: (_, __) => const AdminHomeScreen(),
      ),
    ],
  );
}
