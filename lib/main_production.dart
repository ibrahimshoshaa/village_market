import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
// TODO: generate per-flavor options via:
//   flutterfire configure --project=village-market-prod --out=lib/firebase_options_prod.dart
import 'firebase_options.dart';

/// Production flavor entry point — points at the live Firebase project.
/// Run with: flutter run -t lib/main_production.dart
/// This is also the entry point built by the CI/CD pipeline (Phase 8).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions
        .currentPlatform, // swap to firebase_options_prod.dart once generated
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  await Hive.initFlutter();

  runApp(
    const ProviderScope(
      child: VillageMarketApp(),
    ),
  );
}
