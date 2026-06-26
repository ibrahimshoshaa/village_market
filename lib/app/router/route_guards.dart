import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/user_role.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import 'app_routes.dart';

class AuthGuard {
  final Ref ref;
  AuthGuard(this.ref);

  String? call(BuildContext context, GoRouterState state) {
    final authState = ref.read(authStateProvider);
    final isLoggedIn = authState.valueOrNull != null;
    final isAuthRoute = state.matchedLocation.startsWith('/auth');
    final isOnboarding =
        state.matchedLocation.startsWith(AppRoutes.roleSelection);
    final isSplash = state.matchedLocation == AppRoutes.splash;

    // لسه بيحمل
    if (authState.isLoading) {
      return isSplash ? null : AppRoutes.splash;
    }

    // مش logged in
    if (!isLoggedIn && !isAuthRoute) {
      return AppRoutes.phoneEntry;
    }

    // logged in وعلى شاشة auth
    if (isLoggedIn && (isAuthRoute || isSplash)) {
      final user = authState.valueOrNull!;
      if (user.role == UserRole.unknown) return AppRoutes.roleSelection;
      return _homeForRole(user.role);
    }

    // logged in بس مش اختار role
    final user = authState.valueOrNull;
    if (isLoggedIn &&
        user?.role == UserRole.unknown &&
        !isOnboarding) {
      return AppRoutes.roleSelection;
    }

    return null;
  }

  String _homeForRole(UserRole role) => switch (role) {
        UserRole.villager => AppRoutes.home,
        UserRole.vendor => AppRoutes.vendorHome,
        UserRole.driver => AppRoutes.driverHome,
        UserRole.admin => AppRoutes.adminHome,
        _ => AppRoutes.roleSelection,
      };
}

class RoleGuard {
  final List<UserRole> allowedRoles;
  const RoleGuard(this.allowedRoles);

  String? check(UserRole currentRole, String fallback) {
    if (!allowedRoles.contains(currentRole)) return fallback;
    return null;
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
