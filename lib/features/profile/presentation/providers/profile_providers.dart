import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/firebase_service.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';

part 'profile_providers.g.dart';

@riverpod
class ProfileController extends _$ProfileController {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> updateDisplayName(String newName) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    state = const AsyncLoading();
    try {
      final firestore = ref.read(firestoreProvider);
      await firestore.collection('users').doc(user.uid).update({
        'displayName': newName.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      final auth = ref.read(firebaseAuthProvider);
      await auth.signOut();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
