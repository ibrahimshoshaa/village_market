import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_service.g.dart';

/// Composition-root providers for the raw Firebase SDK instances. Feature
/// repositories (data layer) read these instead of calling
/// FirebaseFirestore.instance directly, so tests can override them with
/// fake_cloud_firestore / firebase_auth_mocks instances.

@riverpod
FirebaseFirestore firestore(Ref ref) => FirebaseFirestore.instance;

@riverpod
FirebaseAuth firebaseAuth(Ref ref) => FirebaseAuth.instance;

@riverpod
FirebaseStorage firebaseStorage(Ref ref) => FirebaseStorage.instance;

@riverpod
FirebaseFunctions firebaseFunctions(Ref ref) => FirebaseFunctions.instance;
