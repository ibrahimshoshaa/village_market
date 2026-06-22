import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/entities/user_role.dart';

/// STUB PROVIDER — replace with a real implementation backed by
/// FirebaseAuth.instance.authStateChanges() + the /users Firestore document,
/// per Phase 3.1 of the blueprint.
///
/// AsyncValue states:
/// - AsyncLoading()   -> still resolving auth state (show splash)
/// - AsyncData(null)  -> signed out
/// - AsyncData(user)  -> signed in, with role/profile loaded
final authStateProvider = StateProvider<AsyncValue<AppUser?>>((ref) {
  return const AsyncData(null);
});

/// Convenience derived provider — used by RoleGuard checks in the router.
final currentUserRoleProvider = Provider<UserRole>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull?.role ?? UserRole.unknown;
});
