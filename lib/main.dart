import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/cart/data/models/cart_item_model.dart';

import 'app/app.dart';
import 'firebase_options.dart';

/// Entry point. For multi-flavor setups (dev/prod Firebase projects),
/// see main_development.dart / main_production.dart instead of running
/// this file directly.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Offline-first configuration — see Phase 5.1 of the blueprint.
  // Unlimited cache size: a village-scale catalog + chat history is small
  // enough that the default 100MB LRU eviction does more harm (silently
  // dropping cached listings) than good here.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  await Hive.initFlutter();
  // TODO: register Hive adapters here once cart/local models are generated, e.g.:
  // Hive.registerAdapter(CartItemModelAdapter());
  // await Hive.openBox<CartItemModel>('cart');

Hive.registerAdapter(CartItemModelAdapter());
await Hive.openBox<CartItemModel>('cart');
  runApp(
    const ProviderScope(
      child: VillageMarketApp(),
    ),
  );
}
