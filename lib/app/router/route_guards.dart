import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/user_role.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import 'app_routes.dart';

/// Note: this is UX-level routing protection only — it prevents an honest
/// user from accidentally landing on a screen meant for another role. It is
/// NOT the security boundary; that's Firestore Security Rules (Phase 6),
/// which re-check the role server-side on every read/write. Never treat a
/// successful client-side route guard as proof of authorization.
class AuthGuard {
  final Ref ref;
  AuthGuard(this.ref);

  String? call(BuildContext context, GoRouterState state) {
    final authState = ref.read(authStateProvider);
    final isLoggedIn = authState.valueOrNull != null;
    final isAuthRoute = state.matchedLocation.startsWith('/auth');
    final isOnboarding = state.matchedLocation.startsWith(AppRoutes.roleSelection);
    final isSplash = state.matchedLocation == AppRoutes.splash;

    if (authState.isLoading) {
      return isSplash ? null : AppRoutes.splash;
    }

    if (!isLoggedIn && !isAuthRoute) {
      return AppRoutes.phoneEntry;
    }

    if (isLoggedIn && (isAuthRoute || isSplash)) {
      final user = authState.valueOrNull!;
      if (user.role == UserRole.unknown) return AppRoutes.roleSelection;
      return _homeForRole(user.role);
    }

    final user = authState.valueOrNull;
    if (isLoggedIn && user!.role == UserRole.unknown && !isOnboarding) {
      return AppRoutes.roleSelection;
    }

    return null;
  }

  String _homeForRole(UserRole role) => switch (role) {
        UserRole.villager => AppRoutes.home,
        UserRole.vendor => AppRoutes.vendorHome,
        UserRole.driver => AppRoutes.driverHome,
        UserRole.admin => AppRoutes.adminHome,
        UserRole.unknown => AppRoutes.roleSelection,
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

/// Bridges a Riverpod Stream/State provider to GoRouter's `refreshListenable`
/// so navigation re-evaluates `redirect` whenever auth state changes
/// (sign-in, sign-out, role update) — not just on explicit navigation calls.
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
