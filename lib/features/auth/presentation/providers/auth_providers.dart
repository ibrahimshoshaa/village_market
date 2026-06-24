import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/entities/user_role.dart';

/// STUB PROVIDER — replace with real FirebaseAuth.instance.authStateChanges()
/// per Phase 3.1 of the blueprint.
final authStateProvider = StateProvider<AsyncValue<AppUser?>>((ref) {
  return const AsyncData(null);
});

/// Convenience derived provider — used by RoleGuard in the router.
final currentUserRoleProvider = Provider<UserRole>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull?.role ?? UserRole.unknown;
});
