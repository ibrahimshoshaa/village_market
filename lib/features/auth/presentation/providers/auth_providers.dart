import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_user.dart';

/// STUB PROVIDER — replace with a real implementation backed by
/// FirebaseAuth.instance.authStateChanges() + the /users Firestore document,
/// per Phase 3.1 of the blueprint (auto user-document creation on first
/// sign-in). Kept as a simple StateProvider for now so the router and shell
/// scaffolding can be built and run before Firebase Auth wiring lands.
///
/// AsyncValue<AppUser?> mirrors the real shape this will eventually have:
/// - AsyncLoading()      -> still resolving auth state (show splash)
/// - AsyncData(null)     -> signed out
/// - AsyncData(AppUser)  -> signed in, with role/profile loaded
final authStateProvider = StateProvider<AsyncValue<AppUser?>>((ref) {
  return const AsyncData(null);
});

/// Convenience derived provider — used by RoleGuard checks throughout the
/// router (Phase 1.4) without each guard needing to unwrap AsyncValue itself.
final currentUserRoleProvider = Provider<UserRole>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull?.role ?? UserRole.unknown;
});
