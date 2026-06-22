# سوق القرية (Village Market) — Master Engineering Blueprint

**Stack:** Flutter (Dart) · Firebase (Firestore, Auth, Storage, Functions, FCM, Crashlytics, App Check)
**Roles:** Villager (Customer) · Vendor (Shop/Craftsman) · Driver (Delivery) · Admin
**State Management:** Riverpod (with code generation)
**Primary Locale:** Arabic (RTL) — Egyptian rural context, weak connectivity assumed by default

---
## فهرس المحتويات (Table of Contents)

- [PHASE 1 — Architecture & Folder Structure](#phase-1--architecture--folder-structure)
  - 1.1 Feature-First Clean Architecture
  - 1.2 Full Folder Structure
  - 1.3 State Management: Riverpod
  - 1.4 Routing: GoRouter + Role-Based Access Control
  - 1.5 Localization Strategy (Arabic RTL)
- [PHASE 2 — Advanced Firestore Schema & Indexing](#phase-2--advanced-firestore-schema--indexing)
  - 2.1 `users` · 2.2 `shops` & `products` · 2.3 `craftsmen` · 2.4 `orders`
  - 2.5 `chats` · 2.6 `reviews` · 2.7 Search Strategy · 2.8 Compound Indexes
- [PHASE 3 — Core Workflows & Business Logic](#phase-3--core-workflows--business-logic-crud)
  - 3.1 Phone Auth (OTP) · 3.2 Cart & Checkout (Transactions) · 3.3 Geolocation & Maps
- [PHASE 4 — Cloud Functions (Node.js)](#phase-4--cloud-functions-nodejs--typescript)
  - 4.1 Rating Aggregation · 4.2 Push Notifications · 4.3 Auto-Cancellation · 4.4 Role Claims Sync
- [PHASE 5 — Offline-First & Error Handling](#phase-5--offline-first--error-handling)
  - 5.1 Firestore Persistence · 5.2 Cached Images · 5.3 Retry Logic · 5.4 Connectivity UI
- [PHASE 6 — Firebase Security Rules](#phase-6--firebase-security-rules)
  - 6.1 firestore.rules (full file) · 6.2 storage.rules (full file)
- [PHASE 7 — UI/UX & Performance Optimization](#phase-7--uiux--performance-optimization)
  - 7.1 Elderly/Non-Tech-Savvy Accessibility · 7.2 Image Grid Performance · 7.3 Cursor Pagination
- [PHASE 8 — Cloud Development & CI/CD Pipeline](#phase-8--cloud-development--cicd-pipeline-low-spec-hardware)
  - 8.1 Codespaces Setup · 8.2 GitHub Actions Workflow · 8.3 Secrets Management · 8.4 Downloading APKs
  - Closing Notes — Recommended Build Order

---


## PHASE 1 — ARCHITECTURE & FOLDER STRUCTURE

### 1.1 Architectural Style: Feature-First Clean Architecture

We use **Clean Architecture** sliced **by feature**, not by layer-at-the-root. This is critical at scale: a layer-first structure (`lib/presentation`, `lib/domain`, `lib/data` at the root) forces you to jump between 5 folders to touch one feature. Feature-first keeps everything related to "orders" inside `features/orders/`, with Clean Architecture's 3 layers *nested inside* each feature.

**The 3 layers, per feature:**

| Layer | Responsibility | Depends on |
|---|---|---|
| `domain` | Entities, repository contracts (abstract), use cases. Pure Dart, zero Flutter/Firebase imports. | Nothing |
| `data` | Repository implementations, DTOs/models (`fromJson`/`toJson`/`fromFirestore`), Firebase data sources. | `domain` |
| `presentation` | Widgets (screens, components), Riverpod providers/notifiers, view state. | `domain` (never directly `data`) |

This means: presentation calls a **use case** (or directly a repository interface) from `domain`. It never imports a Firestore document type directly. This is what lets you swap Firebase for another backend later, and — more realistically for you — what lets you **unit test business logic without spinning up Firebase emulators** for every test.

### 1.2 Full Folder Structure

```
village_market/
├── android/
├── ios/
├── lib/
│   ├── main.dart                       # Entry point, ProviderScope, Firebase.initializeApp
│   ├── main_development.dart           # Flavored entry point (dev Firebase project)
│   ├── main_production.dart            # Flavored entry point (prod Firebase project)
│   │
│   ├── app/
│   │   ├── app.dart                    # MaterialApp.router, theme, locale wiring
│   │   ├── router/
│   │   │   ├── app_router.dart         # GoRouter config + role-based redirect logic
│   │   │   ├── app_routes.dart         # Route path constants (typed)
│   │   │   └── route_guards.dart       # AuthGuard, RoleGuard logic
│   │   └── theme/
│   │       ├── app_theme.dart          # ThemeData (light/dark), elder-friendly scale
│   │       ├── app_colors.dart
│   │       └── app_text_styles.dart
│   │
│   ├── core/                           # Shared across ALL features — no feature imports this back
│   │   ├── constants/
│   │   │   ├── firestore_collections.dart   # Collection name constants (single source of truth)
│   │   │   ├── app_constants.dart
│   │   │   └── storage_paths.dart
│   │   ├── error/
│   │   │   ├── failures.dart           # Failure sealed class (NetworkFailure, AuthFailure...)
│   │   │   ├── exceptions.dart         # Custom exceptions thrown by data layer
│   │   │   └── error_mapper.dart       # FirebaseException -> Failure mapper
│   │   ├── network/
│   │   │   ├── connectivity_service.dart    # connectivity_plus wrapper, stream<bool>
│   │   │   └── retry_policy.dart            # Exponential backoff helper (Phase 5)
│   │   ├── result/
│   │   │   └── result.dart             # Result<T> / Either<Failure, T> (using fpdart or dartz)
│   │   ├── utils/
│   │   │   ├── geo_utils.dart          # Haversine distance, geohash helpers
│   │   │   ├── currency_formatter.dart # EGP formatting, Arabic-Indic digits toggle
│   │   │   ├── date_formatter.dart     # Arabic date/time formatting (intl)
│   │   │   └── validators.dart         # Phone number, OTP, form validators
│   │   ├── widgets/                    # Dumb, reusable, NO business logic
│   │   │   ├── app_button.dart         # Large-tap-target button (elder-friendly, Phase 7)
│   │   │   ├── app_text_field.dart
│   │   │   ├── loading_indicator.dart
│   │   │   ├── error_view.dart         # Retry-capable error widget
│   │   │   ├── empty_state.dart
│   │   │   ├── cached_image.dart       # Wraps cached_network_image w/ placeholder+error
│   │   │   └── offline_banner.dart     # Persistent "أنت غير متصل" banner (Phase 5)
│   │   ├── services/
│   │   │   ├── firebase_service.dart        # Firestore/Auth/Storage instance providers
│   │   │   ├── fcm_service.dart             # Push notification handling, token refresh
│   │   │   ├── location_service.dart        # geolocator wrapper
│   │   │   ├── local_cache_service.dart     # Hive/SharedPreferences for cart, drafts
│   │   │   ├── analytics_service.dart
│   │   │   └── crashlytics_service.dart
│   │   └── extensions/
│   │       ├── context_extensions.dart      # context.l10n, context.colors shortcuts
│   │       └── timestamp_extensions.dart    # Firestore Timestamp <-> DateTime helpers
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── app_user.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── auth_repository.dart        # abstract class
│   │   │   │   └── usecases/
│   │   │   │       ├── send_otp_usecase.dart
│   │   │   │       ├── verify_otp_usecase.dart
│   │   │   │       └── sign_out_usecase.dart
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   └── app_user_model.dart          # extends AppUser, fromFirestore/toMap
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── auth_remote_datasource.dart  # FirebaseAuth calls
│   │   │   │   │   └── user_remote_datasource.dart  # Firestore /users CRUD
│   │   │   │   └── repositories/
│   │   │   │       └── auth_repository_impl.dart
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   ├── auth_providers.dart          # riverpod_generator @riverpod
│   │   │       │   └── otp_controller.dart          # AsyncNotifier for OTP flow state
│   │   │       ├── screens/
│   │   │       │   ├── phone_entry_screen.dart
│   │   │       │   ├── otp_verification_screen.dart
│   │   │       │   └── role_selection_screen.dart   # First-time: villager vs vendor signup
│   │   │       └── widgets/
│   │   │           ├── otp_input_field.dart
│   │   │           └── country_code_picker.dart
│   │   │
│   │   ├── shops/                       # Vendor shop catalog (browsing side)
│   │   │   ├── domain/{entities,repositories,usecases}/
│   │   │   ├── data/{models,datasources,repositories}/
│   │   │   └── presentation/{providers,screens,widgets}/
│   │   │       # screens: shop_list_screen, shop_detail_screen, category_filter_screen
│   │   │
│   │   ├── products/                    # Product catalog + inventory subcollection
│   │   │   ├── domain/...
│   │   │   ├── data/...
│   │   │   └── presentation/...
│   │   │       # screens: product_grid_screen, product_detail_screen
│   │   │       # widgets: product_card.dart (paginated grid item, Phase 7)
│   │   │
│   │   ├── craftsmen/                    # Service directory (plumbers, electricians, etc.)
│   │   │   ├── domain/...
│   │   │   ├── data/...
│   │   │   └── presentation/...
│   │   │       # screens: craftsmen_list_screen, craftsman_profile_screen
│   │   │       # widgets: availability_toggle.dart, portfolio_gallery.dart
│   │   │
│   │   ├── cart/                         # Local-first cart (Phase 3)
│   │   │   ├── domain/
│   │   │   │   ├── entities/cart_item.dart, cart.dart
│   │   │   │   └── usecases/calculate_totals_usecase.dart
│   │   │   ├── data/
│   │   │   │   └── repositories/cart_repository_impl.dart   # backed by Hive, NOT Firestore
│   │   │   └── presentation/
│   │   │       ├── providers/cart_provider.dart              # @riverpod class CartNotifier
│   │   │       └── screens/cart_screen.dart
│   │   │
│   │   ├── orders/
│   │   │   ├── domain/
│   │   │   │   ├── entities/order.dart, order_item.dart, order_status.dart (enum)
│   │   │   │   ├── repositories/order_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── place_order_usecase.dart      # Wraps Firestore transaction
│   │   │   │       ├── update_order_status_usecase.dart
│   │   │   │       └── watch_order_usecase.dart       # Stream<Order> for tracking screen
│   │   │   ├── data/...
│   │   │   └── presentation/
│   │   │       # screens: checkout_screen, order_tracking_screen, order_history_screen
│   │   │       # vendor side: incoming_orders_screen, order_management_screen
│   │   │       # driver side: available_deliveries_screen, active_delivery_screen
│   │   │
│   │   ├── chat/
│   │   │   ├── domain/{entities: chat_thread.dart, message.dart}/...
│   │   │   ├── data/...
│   │   │   └── presentation/
│   │   │       # screens: chat_list_screen, chat_thread_screen
│   │   │       # providers: chat_thread_provider (StreamProvider.family<List<Message>, String>)
│   │   │
│   │   ├── reviews/
│   │   │   ├── domain/...
│   │   │   ├── data/...
│   │   │   └── presentation/
│   │   │       # widgets: rating_stars.dart, review_form_sheet.dart
│   │   │
│   │   ├── geolocation/
│   │   │   ├── domain/usecases/get_nearby_craftsmen_usecase.dart, calculate_delivery_fee_usecase.dart
│   │   │   ├── data/...
│   │   │   └── presentation/widgets/map_picker.dart, distance_badge.dart
│   │   │
│   │   ├── vendor_dashboard/             # Vendor-only feature module
│   │   │   ├── domain/...
│   │   │   ├── data/...
│   │   │   └── presentation/
│   │   │       # screens: vendor_home, manage_products_screen, shop_settings_screen, payout_screen
│   │   │
│   │   ├── driver_dashboard/             # Driver-only feature module
│   │   │   └── presentation/
│   │   │       # screens: driver_home, delivery_map_screen, earnings_screen
│   │   │
│   │   ├── admin_panel/                  # Admin-only feature module (could be separate Flutter Web app)
│   │   │   └── presentation/
│   │   │       # screens: user_management, shop_approval_queue, dispute_resolution
│   │   │
│   │   ├── notifications/
│   │   │   ├── data/datasources/fcm_token_datasource.dart
│   │   │   └── presentation/screens/notifications_inbox_screen.dart
│   │   │
│   │   └── profile/
│   │       ├── domain/...
│   │       ├── data/...
│   │       └── presentation/
│   │           # screens: profile_screen, edit_profile_screen, address_book_screen
│   │
│   ├── l10n/
│   │   ├── app_ar.arb                  # Primary — Arabic
│   │   ├── app_en.arb                  # Secondary — English
│   │   └── l10n.yaml config (project root, see 1.4)
│   │
│   └── firebase_options.dart           # Generated by flutterfire CLI, per-flavor
│
├── test/
│   ├── features/
│   │   └── orders/
│   │       ├── domain/usecases/place_order_usecase_test.dart
│   │       └── data/repositories/order_repository_impl_test.dart
│   └── core/
│       └── utils/geo_utils_test.dart
│
├── functions/                          # Cloud Functions (Node.js) — Phase 4, separate package.json
│   ├── src/
│   │   ├── index.ts
│   │   ├── triggers/
│   │   │   ├── onReviewCreated.ts
│   │   │   ├── onOrderStatusChanged.ts
│   │   │   └── onUserCreated.ts
│   │   ├── scheduled/
│   │   │   └── autoCancelOrders.ts
│   │   └── utils/
│   │       └── fcmSender.ts
│   ├── package.json
│   └── tsconfig.json
│
├── .github/
│   └── workflows/
│       └── build-apk.yml               # Phase 8
│
├── firestore.rules                     # Phase 6
├── storage.rules                       # Phase 6
├── firestore.indexes.json              # Phase 2
├── pubspec.yaml
└── analysis_options.yaml
```

**Why this matters at your scale:** With 4 roles and ~12 features, a flat structure becomes unmanageable past month 2. The feature-first split also lets you **delete entire role-dashboards as deferred work** (e.g., ship `admin_panel` as a bare-bones Flutter Web build later) without touching anything else.

### 1.3 State Management: Riverpod (with `riverpod_generator`)

**Packages:**
```yaml
dependencies:
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1

dev_dependencies:
  riverpod_generator: ^2.6.3
  build_runner: ^2.4.13
  custom_lint: ^0.7.0
  riverpod_lint: ^2.6.3
```

**Why Riverpod over BLoC for this app specifically:**
- Less boilerplate per feature (you have ~12 features × 4 roles — BLoC's event/state class explosion gets heavy fast).
- `family` providers map perfectly onto your data shape: `orderStreamProvider(orderId)`, `chatMessagesProvider(threadId)`, `nearbyDriversProvider(geohash)`.
- `AsyncValue<T>` natively models the 3 states every Firestore read has: loading / data / error — which directly feeds Phase 5's offline/error handling without extra wrapper types.
- Compile-time safety (no `BuildContext` lookups failing at runtime) — important since you're developing entirely in a cloud IDE without a fast local hot-reload-debug loop; catching errors at analysis time saves CI round-trips.

**Provider Conventions (mandatory across all features):**

| Type | Use case | Example |
|---|---|---|
| `@riverpod Stream<T>` (Notifier-less) | Read-only realtime Firestore stream | `productListStream(shopId)` |
| `@riverpod class Foo extends _$Foo` (`AsyncNotifier`) | Mutable state with async actions (place order, send OTP) | `OtpController`, `CheckoutController` |
| `@riverpod class Foo extends _$Foo` (sync `Notifier`) | Pure local UI/client state | `CartNotifier` (Hive-backed, not Firestore) |
| `@riverpod` plain function | Computed/derived value | `cartTotalProvider` (derives from `cartProvider`) |

**Layering rule:** Providers in `presentation/providers/` call **use cases** from `domain/usecases/`, which call **repository interfaces** (also `domain`). The concrete repository (`data/repositories/*_impl.dart`) is bound via `Provider<AuthRepository>` override at the composition root (`core/services/firebase_service.dart` or a dedicated `injection.dart`). This is your dependency injection — no separate DI package (get_it) is needed since Riverpod's provider graph **is** the DI container.

Example skeleton (full code in Phase 3):
```dart
// domain/repositories/order_repository.dart
abstract class OrderRepository {
  Future<Result<String, Failure>> placeOrder(Order order);
  Stream<Order> watchOrder(String orderId);
}

// data/repositories/order_repository_impl.dart
@riverpod
OrderRepository orderRepository(Ref ref) {
  return OrderRepositoryImpl(
    firestore: ref.watch(firestoreProvider),
  );
}

// presentation/providers/checkout_controller.dart
@riverpod
class CheckoutController extends _$CheckoutController {
  @override
  FutureOr<void> build() {} // idle state

  Future<void> submitOrder(Order draft) async {
    state = const AsyncLoading();
    final repo = ref.read(orderRepositoryProvider);
    final result = await repo.placeOrder(draft);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (orderId) => const AsyncData(null),
    );
  }
}
```

### 1.4 Routing: GoRouter with Role-Based Access Control

**Package:** `go_router: ^14.6.2`

**Core principle:** Role-based routing must be enforced via `GoRouter`'s `redirect` callback, evaluated on **every** navigation — not just guarded with `if` checks inside individual screens (which is bypassable via deep link or back-stack manipulation).

**Route guard architecture:**

```dart
// app/router/route_guards.dart
enum UserRole { villager, vendor, driver, admin, unknown }

class AuthGuard {
  final Ref ref;
  AuthGuard(this.ref);

  String? call(BuildContext context, GoRouterState state) {
    final authState = ref.read(authStateProvider); // AsyncValue<AppUser?>
    final isLoggedIn = authState.valueOrNull != null;
    final isAuthRoute = state.matchedLocation.startsWith('/auth');
    final isOnboarding = state.matchedLocation.startsWith('/role-selection');

    // Still resolving auth state -> stay on splash
    if (authState.isLoading) return '/splash';

    // Not logged in, trying to access protected route
    if (!isLoggedIn && !isAuthRoute) return '/auth/phone-entry';

    // Logged in, but stuck on auth screens
    if (isLoggedIn && isAuthRoute) return _homeForRole(authState.valueOrNull!.role);

    // Logged in but role not yet chosen (first-time user)
    final user = authState.valueOrNull;
    if (isLoggedIn && user!.role == UserRole.unknown && !isOnboarding) {
      return '/role-selection';
    }

    return null; // no redirect needed
  }

  String _homeForRole(UserRole role) => switch (role) {
    UserRole.villager => '/home',
    UserRole.vendor   => '/vendor/home',
    UserRole.driver   => '/driver/home',
    UserRole.admin    => '/admin/home',
    UserRole.unknown  => '/role-selection',
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
```

```dart
// app/router/app_router.dart
@riverpod
GoRouter appRouter(Ref ref) {
  final authGuard = AuthGuard(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(ref.watch(authStateChangesProvider.stream)),
    redirect: (context, state) => authGuard.call(context, state),
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),

      // --- AUTH ---
      GoRoute(path: '/auth/phone-entry', builder: (_, __) => const PhoneEntryScreen()),
      GoRoute(path: '/auth/otp', builder: (_, __) => const OtpVerificationScreen()),
      GoRoute(path: '/role-selection', builder: (_, __) => const RoleSelectionScreen()),

      // --- VILLAGER (default role, /home) ---
      ShellRoute(
        builder: (context, state, child) => VillagerShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const ShopListScreen()),
          GoRoute(path: '/shop/:shopId', builder: (_, s) => ShopDetailScreen(shopId: s.pathParameters['shopId']!)),
          GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
          GoRoute(
            path: '/order/:orderId',
            redirect: (context, state) {
              final role = ref.read(currentUserRoleProvider);
              return const RoleGuard([UserRole.villager]).check(role, '/home');
            },
            builder: (_, s) => OrderTrackingScreen(orderId: s.pathParameters['orderId']!),
          ),
        ],
      ),

      // --- VENDOR (gated) ---
      ShellRoute(
        builder: (context, state, child) => VendorShell(child: child),
        routes: [
          GoRoute(
            path: '/vendor/home',
            redirect: (context, state) {
              final role = ref.read(currentUserRoleProvider);
              return const RoleGuard([UserRole.vendor]).check(role, '/home');
            },
            builder: (_, __) => const VendorDashboardScreen(),
          ),
          GoRoute(
            path: '/vendor/products',
            redirect: (context, state) {
              final role = ref.read(currentUserRoleProvider);
              return const RoleGuard([UserRole.vendor]).check(role, '/home');
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
            path: '/driver/home',
            redirect: (context, state) {
              final role = ref.read(currentUserRoleProvider);
              return const RoleGuard([UserRole.driver]).check(role, '/home');
            },
            builder: (_, __) => const DriverHomeScreen(),
          ),
        ],
      ),

      // --- ADMIN (gated, strictest) ---
      GoRoute(
        path: '/admin/home',
        redirect: (context, state) {
          final role = ref.read(currentUserRoleProvider);
          return const RoleGuard([UserRole.admin]).check(role, '/home');
        },
        builder: (_, __) => const AdminHomeScreen(),
      ),
    ],
  );
}
```

**Critical point:** This is **UX-level** routing protection only (prevents an honest villager user from accidentally landing on a vendor screen, and improves app navigation flow). It is **NOT** your security boundary — a modified client or direct API call can bypass it entirely. The actual security boundary is **Firestore Security Rules** (Phase 6), which check the user's role server-side on every read/write. Never trust `role` claims that haven't been verified against the rules layer.

**Role claim source:** Store `role` in the Firestore `/users/{uid}` document (Phase 2) AND mirror it into a **custom claim** on the Firebase Auth token via a Cloud Function trigger (`onUserCreated` / `onUserRoleChanged`, see Phase 4) so Security Rules can read `request.auth.token.role` cheaply without an extra `get()` call on every single rule evaluation.

### 1.5 Localization Strategy (Arabic RTL Primary)

**Packages:**
```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0
```

**`l10n.yaml` (project root):**
```yaml
arb-dir: lib/l10n
template-arb-file: app_ar.arb     # Arabic is the TEMPLATE — not English
output-localization-file: app_localizations.dart
output-class: AppLocalizations
preferred-supported-locales: ["ar", "en"]
nullable-getter: false
```

**Why Arabic as the template ARB (not English):** Flutter's codegen treats the template file as the canonical source of truth for keys/placeholders. Making Arabic the template forces every translator/dev to think in Arabic-first phrasing (correct pluralization rules, RTL-aware placeholders) rather than retrofitting Arabic onto English sentence structure, which produces awkward literal translations.

**`app/app.dart` — locale + directionality wiring:**
```dart
class VillageMarketApp extends ConsumerWidget {
  const VillageMarketApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      routerConfig: router,
      locale: const Locale('ar', 'EG'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl, // Force RTL even if device locale is EN
          child: child!,
        );
      },
      theme: AppTheme.light,
    );
  }
}
```

**RTL-specific implementation rules (apply across ALL widgets):**

1. **Never hardcode `left`/`right`** in `Padding`, `Positioned`, `Alignment`. Always use directional equivalents:
   - `EdgeInsets.only(left: ...)` → `EdgeInsetsDirectional.only(start: ...)`
   - `Alignment.centerLeft` → `AlignmentDirectional.centerStart`
   - `Positioned(left: ...)` → `PositionedDirectional(start: ...)`
2. **Icons that imply direction** (back arrows, chevrons, "send" arrows) must be mirrored. Use `Icons.arrow_back` (Flutter auto-mirrors Material icons under RTL `Directionality`) — never `Icons.arrow_back_ios` combined with manual `Transform.flip`, which double-flips inconsistently. Test explicitly.
3. **Numbers:** Arabic-Indic digits (٠١٢٣...) vs Western Arabic digits (0123...) is a real product decision for a rural Egyptian audience — many users read Western digits more easily despite Arabic UI text. Recommend keeping **Western digits** for prices/phone numbers/OTP (universally understood, avoids confusion with currency), Arabic text for everything else. Implement via `intl.NumberFormat('#,##0', 'en')` even inside the `ar` locale context — don't rely on the locale's default digit system.
4. **Currency formatting** (`core/utils/currency_formatter.dart`):
   ```dart
   String formatEGP(num amount) {
     final formatter = NumberFormat.currency(
       locale: 'en', // forces Western digits
       symbol: 'ج.م',
       decimalDigits: 2,
     );
     return formatter.format(amount);
   }
   ```
5. **Test on a real low-end device emulator profile** (Phase 8 covers CI, but locally test text overflow — Arabic script height/line-spacing differs from Latin and breaks fixed-height widgets sized for English).

---

*(Continued in Phase 2 — Firestore Schema & Indexing)*
## PHASE 2 — ADVANCED FIRESTORE SCHEMA & INDEXING

### 2.0 Schema Design Principles (read before the collections)

1. **Denormalize aggressively for read paths users hit constantly** (shop name+image on every order line, vendor display name on chat threads). Firestore charges per-document-read; a normalized join-everything schema multiplies reads on every screen.
2. **Subcollections over arrays for unbounded lists.** Arrays of maps (`reviews: [...]`) hit the 1MB document limit and force you to rewrite the *entire* document for one new review. Use subcollections (`/shops/{id}/reviews/{reviewId}`) whenever the list grows unboundedly.
3. **Counters/aggregates are written by Cloud Functions, never computed client-side at read time** (Phase 4 covers the triggers). `avgRating`, `totalOrders`, `productCount` live as top-level fields on the parent doc, updated transactionally.
4. **Geohashing for proximity queries.** Firestore has no native geo-radius query; we store a `geohash` string field (via the `dart_geohash` / `geoflutterfire_plus` package) on any location-bearing document and query geohash range buckets, then filter precisely client-side with Haversine.
5. **Timestamps:** every document gets `createdAt` and `updatedAt` as Firestore `Timestamp` (server-set via `FieldValue.serverTimestamp()` — never client `DateTime.now()`, which is forgeable and clock-skewed on rural devices with bad time sync).

---

### 2.1 `users/{uid}`

```jsonc
{
  "uid": "string (matches Firebase Auth UID, also doc ID)",
  "phoneNumber": "+201XXXXXXXXX",       // E.164 format, from Phone Auth
  "displayName": "string",
  "role": "villager | vendor | driver | admin",
  "profileImageUrl": "string | null",   // Storage download URL

  "fcmTokens": ["string", "string"],    // array — user can have multiple devices
  "isOnline": true,                      // presence indicator (RTDB mirror recommended, see note)
  "lastSeenAt": "Timestamp",

  "location": {
    "geopoint": "GeoPoint(lat, lng)",   // last known location
    "geohash": "string",                 // precomputed for proximity queries
    "addressLabel": "string",            // "بجوار مسجد النور"  — landmark-based, NOT street address (rural)
  },

  "addressBook": [                       // small bounded array OK — rarely >5 entries
    {
      "id": "string (uuid)",
      "label": "المنزل | العمل | أخرى",
      "geopoint": "GeoPoint",
      "geohash": "string",
      "landmarkNote": "string",
      "isDefault": true
    }
  ],

  "vendorProfile": {                     // null unless role == vendor; denormalized shopId pointer
    "shopId": "string | null",
    "isApproved": false                  // admin must approve before shop goes live
  },

  "driverProfile": {                     // null unless role == driver
    "isAvailable": false,
    "vehicleType": "motorcycle | tuk_tuk | car",
    "currentDeliveryOrderId": "string | null",
    "rating": 4.8,
    "totalDeliveries": 0
  },

  "isActive": true,                      // soft-ban flag (admin can disable without deleting)
  "isPhoneVerified": true,
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

**Notes:**
- `role` is mirrored to a **custom claim** on the Auth token (`onUserWrite` Cloud Function, Phase 4) — Security Rules read `request.auth.token.role` instead of doing a `get(/users/$(uid))` on every single rule check (cuts rule-evaluation read costs roughly in half across the entire ruleset).
- `isOnline`/`lastSeenAt`: for true real-time presence (e.g., "is the vendor online right now"), Firestore is the wrong tool — its writes aren't cheap enough for frequent presence pings, and it has no `onDisconnect()` hook. **Recommendation:** mirror presence into **Firebase Realtime Database** (which has native `onDisconnect()`), and only sync a coarse `isOnline` boolean back into Firestore via a Cloud Function on change, debounced. Keep this in mind as an addendum to your stack — RTDB is free-tier friendly and built exactly for this.

---

### 2.2 `shops/{shopId}`

```jsonc
{
  "shopId": "string",
  "ownerId": "string (uid)",
  "shopName": "string",
  "shopNameLower": "string",            // lowercased copy for prefix search (see 2.7)
  "category": "grocery | bakery | pharmacy | clothing | electronics | other",
  "description": "string",
  "logoUrl": "string",
  "coverImageUrl": "string",

  "location": {
    "geopoint": "GeoPoint",
    "geohash": "string",
    "addressLabel": "string"
  },

  "operatingHours": {                    // map keyed by weekday, not array — O(1) lookup
    "sunday":    { "isOpen": true,  "openTime": "08:00", "closeTime": "22:00" },
    "monday":    { "isOpen": true,  "openTime": "08:00", "closeTime": "22:00" },
    "tuesday":   { "isOpen": true,  "openTime": "08:00", "closeTime": "22:00" },
    "wednesday": { "isOpen": true,  "openTime": "08:00", "closeTime": "22:00" },
    "thursday":  { "isOpen": true,  "openTime": "08:00", "closeTime": "22:00" },
    "friday":    { "isOpen": false, "openTime": null,    "closeTime": null },
    "saturday":  { "isOpen": true,  "openTime": "08:00", "closeTime": "22:00" }
  },
  "isManuallyOverrideClosed": false,     // vendor's "تعطيل مؤقت" toggle, takes precedence over hours

  "deliveryRadiusKm": 5,
  "minOrderAmount": 30.0,
  "baseDeliveryFee": 10.0,

  "isApproved": false,                   // admin gate — invisible to villagers until true
  "isActive": true,

  // Denormalized aggregates (written ONLY by Cloud Functions, see Phase 4)
  "avgRating": 4.5,
  "reviewCount": 128,
  "productCount": 47,
  "totalOrdersCompleted": 340,

  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

**Subcollection: `shops/{shopId}/products/{productId}`**

```jsonc
{
  "productId": "string",
  "shopId": "string",                    // denormalized back-pointer (needed for collectionGroup queries)
  "name": "string",
  "nameLower": "string",
  "description": "string",
  "category": "string",
  "imageUrls": ["string", "string"],     // max ~5, Storage URLs

  "price": 25.50,
  "discountPrice": 20.00,                // null if no discount
  "unit": "كيلو | قطعة | علبة | كرتونة",

  "stockQuantity": 50,                   // decremented via Cloud Function on order (Phase 4)
  "isInStock": true,                      // derived flag, kept in sync with stockQuantity for cheap filtering
  "isAvailable": true,                    // vendor manual toggle (independent of stock)

  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

**Why `products` is a subcollection of `shops`, not top-level:** Almost every product query is scoped to a single shop ("show me this shop's catalog"). Subcollections give you that scoping for free with no `where('shopId', '==', ...)` filter needed, and the per-shop document count stays small (no shop will realistically have 50,000 products in this context), keeping pagination cursors cheap. We still denormalize `shopId` onto the product doc itself to support **`collectionGroup('products')`** queries for village-wide search (Section 2.7).

---

### 2.3 `craftsmen/{craftsmanId}`

```jsonc
{
  "craftsmanId": "string",
  "userId": "string (uid, links to /users)",
  "fullName": "string",
  "profession": "كهربائي | سباك | نجار | بناء | ميكانيكي | other",
  "bio": "string",
  "yearsOfExperience": 8,

  "portfolioImageUrls": ["string", "string", "string"],   // bounded ~10 images, array is fine here

  "serviceArea": {
    "centerGeopoint": "GeoPoint",
    "centerGeohash": "string",
    "radiusKm": 10
  },

  "isAvailableNow": true,                // the "availability toggle" — craftsman flips this manually
  "availabilitySchedule": {              // optional structured hours, same shape as shop operatingHours
    "sunday": { "isAvailable": true, "from": "09:00", "to": "20:00" }
    // ...
  },

  "priceRangeLabel": "150 - 400 ج.م",    // free-text estimate, not a fixed price list

  "isApproved": false,                    // admin verification gate (important for trust — craftsmen enter homes)
  "isActive": true,

  "avgRating": 4.7,
  "reviewCount": 56,
  "completedJobsCount": 89,

  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

---

### 2.4 `orders/{orderId}`

This is the most complex document in the system. Designed for: multi-item carts, transparent pricing breakdown, full status audit trail, and queryability by all 3 participant roles (villager, vendor, driver).

```jsonc
{
  "orderId": "string",
  "orderNumber": "string (e.g. 'VM-20260621-0042')",   // human-friendly, generated by Cloud Function

  // --- Participants (denormalized for zero-join reads) ---
  "customerId": "string (uid)",
  "customerName": "string",
  "customerPhone": "string",

  "shopId": "string",
  "shopName": "string",
  "vendorId": "string (uid, shop owner)",

  "driverId": "string | null",           // assigned after vendor accepts, null while Pending
  "driverName": "string | null",

  // --- Items (embedded array — bounded, an order realistically has <50 line items) ---
  "items": [
    {
      "productId": "string",
      "productName": "string",            // snapshot at order time — NOT a live reference
      "imageUrl": "string",
      "unitPrice": 25.50,                 // snapshot — protects against future price changes
      "quantity": 3,
      "lineTotal": 76.50
    }
  ],

  // --- Pricing breakdown (every figure stored explicitly, never recalculated client-side post-hoc) ---
  "pricing": {
    "subtotal": 76.50,
    "deliveryFee": 10.00,
    "serviceFee": 2.00,                   // platform commission, if applicable
    "discountAmount": 0.00,
    "taxAmount": 0.00,                    // VAT placeholder, likely 0 for informal rural commerce
    "totalAmount": 88.50
  },

  // --- Payment ---
  "payment": {
    "method": "cash | wallet | gateway",  // extensible enum — "gateway" reserved for future Paymob/Stripe
    "status": "pending | paid | failed | refunded",
    "gatewayReference": "string | null",  // populated only when method == gateway
    "paidAt": "Timestamp | null"
  },

  // --- Delivery ---
  "delivery": {
    "type": "delivery | pickup",
    "dropoffGeopoint": "GeoPoint",
    "dropoffAddressLabel": "string",
    "distanceKm": 2.3,
    "estimatedMinutes": 18
  },

  // --- Status & audit trail ---
  "status": "pending | accepted | preparing | in_transit | delivered | cancelled",
  "statusHistory": [                      // append-only audit log, embedded (bounded — max ~6 entries/order)
    {
      "status": "pending",
      "timestamp": "Timestamp",
      "changedBy": "string (uid)",
      "note": "string | null"
    }
  ],
  "cancellation": {                       // null unless status == cancelled
    "reason": "string",
    "cancelledBy": "customer | vendor | system",
    "cancelledAt": "Timestamp"
  },

  "customerNote": "string",               // "من فضلك اطرق الباب، الجرس مكسور"

  "createdAt": "Timestamp",
  "updatedAt": "Timestamp",
  "acceptedAt": "Timestamp | null",
  "deliveredAt": "Timestamp | null"
}
```

**Critical design decisions explained:**
- **Items are an embedded array, not a subcollection.** An order's item list is read-only after creation, small, and always read in full alongside the order — a subcollection would mean 2 reads (order + items query) for every single screen that shows an order, doubling read cost for zero benefit.
- **Price snapshotting (`unitPrice`, `productName` inside `items`)** is mandatory, not optional. If a vendor edits the product price an hour after the order was placed, the historical order must NOT change. This also means **Cloud Functions must validate the price server-side at order-creation time** against the live product doc (Phase 4) — never trust a client-submitted price.
- **`statusHistory` embedded array** gives you a full audit trail without extra reads, capped naturally since an order only transitions through ~5-6 states max.

---

### 2.5 `chats/{threadId}` and subcollection `chats/{threadId}/messages/{messageId}`

**Thread ID convention:** deterministic, not random — `"{uid1}_{uid2}"` with UIDs sorted alphabetically before concatenation. This lets you `get()` a thread directly instead of querying for "does a thread between these two users already exist."

```jsonc
// chats/{threadId}
{
  "threadId": "string",
  "participantIds": ["uid1", "uid2"],     // array, used for the security rule + querying "my threads"
  "participantInfo": {                     // denormalized — avoids N+1 user lookups when rendering chat list
    "uid1": { "name": "string", "avatarUrl": "string", "role": "villager" },
    "uid2": { "name": "string", "avatarUrl": "string", "role": "vendor" }
  },
  "relatedOrderId": "string | null",       // optional — chat originating from an order context

  "lastMessage": {                          // denormalized for chat-list screen (avoids reading subcollection)
    "text": "string",
    "senderId": "string",
    "timestamp": "Timestamp",
    "type": "text | image"
  },
  "unreadCount": {                          // map keyed by uid — per-participant unread counter
    "uid1": 0,
    "uid2": 3
  },

  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

```jsonc
// chats/{threadId}/messages/{messageId}
{
  "messageId": "string",
  "senderId": "string (uid)",
  "type": "text | image | order_reference",
  "text": "string | null",
  "imageUrl": "string | null",
  "orderRef": "string | null",              // orderId, when type == order_reference

  "status": "sent | delivered | read",       // updated as the recipient's client/Cloud Function processes it
  "createdAt": "Timestamp"
}
```

**Why subcollection for messages:** A chat thread can have thousands of messages over its lifetime — this is the textbook unbounded-list case. The `lastMessage` and `unreadCount` denormalized fields on the parent `chats/{threadId}` doc mean the **chat list screen never reads a single message subcollection** — it only reads thread documents (1 query, N small docs), and only opening a specific thread pages through `messages`.

---

### 2.6 `reviews` — as `collectionGroup` subcollections

Reviews live under their target entity, NOT as a flat top-level collection:

```
shops/{shopId}/reviews/{reviewId}
craftsmen/{craftsmanId}/reviews/{reviewId}
```

```jsonc
{
  "reviewId": "string",
  "authorId": "string (uid)",
  "authorName": "string",
  "authorAvatarUrl": "string",
  "rating": 5,                              // integer 1-5
  "comment": "string",
  "relatedOrderId": "string | null",         // ties review to a verified completed order (prevents fake reviews)
  "vendorReply": {                           // optional — vendor can respond once
    "text": "string",
    "repliedAt": "Timestamp"
  },
  "createdAt": "Timestamp"
}
```

**Aggregation without reading all reviews:** `shops/{shopId}.avgRating` and `.reviewCount` are maintained by the `onReviewCreated` Cloud Function trigger (Phase 4) using a **Firestore transaction** that increments `reviewCount` and recalculates `avgRating` from a running sum field (`ratingSum`), so the parent doc never needs to scan the reviews subcollection to compute the average:

```
avgRating = ratingSum / reviewCount     // both maintained incrementally
```

This means `ratingSum` is actually a 5th field you should add to `shops` and `craftsmen` (`"ratingSum": 576` alongside `avgRating: 4.5` and `reviewCount: 128`) — listed here as an implementation note since it's invisible to the client but required for the increment-only update pattern.

**Querying "my reviews" across both shops and craftsmen:** use a `collectionGroup('reviews').where('authorId', '==', uid)` query — this is *why* `authorId` must be present on every review doc regardless of parent type.

---

### 2.7 Search Strategy (prefix search without a search service)

Firestore has no native full-text search. For a village-scale catalog (dozens of shops, hundreds of products — not Amazon-scale), a **prefix-search-via-lowercased-field** pattern is sufficient and avoids the cost/complexity of Algolia/Typesense:

```dart
// nameLower field + range query trick for "starts with" search
firestore
  .collectionGroup('products')
  .where('nameLower', isGreaterThanOrEqualTo: query.toLowerCase())
  .where('nameLower', isLessThan: '${query.toLowerCase()}\uf8ff')
  .limit(20)
```

This is why `shopNameLower` and `nameLower` fields exist on `shops` and `products` — kept in sync at write-time client-side (or via a Cloud Function `onWrite` trigger for safety against malicious clients writing mismatched casing). If the catalog grows materially beyond a few thousand products (multi-village expansion), revisit with **Algolia Firestore extension** or **Typesense** — flagged here as a deliberate scope cut, not an oversight.

---

### 2.8 Required Compound Indexes

`firestore.indexes.json` (deploy via `firebase deploy --only firestore:indexes`):

```json
{
  "indexes": [
    {
      "collectionGroup": "products",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "shopId", "order": "ASCENDING" },
        { "fieldPath": "isAvailable", "order": "ASCENDING" },
        { "fieldPath": "category", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "products",
      "queryScope": "COLLECTION_GROUP",
      "fields": [
        { "fieldPath": "isAvailable", "order": "ASCENDING" },
        { "fieldPath": "nameLower", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "shops",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "isApproved", "order": "ASCENDING" },
        { "fieldPath": "isActive", "order": "ASCENDING" },
        { "fieldPath": "category", "order": "ASCENDING" },
        { "fieldPath": "avgRating", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "craftsmen",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "isApproved", "order": "ASCENDING" },
        { "fieldPath": "profession", "order": "ASCENDING" },
        { "fieldPath": "isAvailableNow", "order": "ASCENDING" },
        { "fieldPath": "centerGeohash", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "orders",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "customerId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "orders",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "vendorId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "orders",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "driverId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "orders",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "reviews",
      "queryScope": "COLLECTION_GROUP",
      "fields": [
        { "fieldPath": "authorId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "chats",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "participantIds", "arrayConfig": "CONTAINS" },
        { "fieldPath": "updatedAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

**Index notes:**
- The `orders` index `[status ASC, createdAt ASC]` (no participant filter) is specifically for the **auto-cancellation scheduled function** (Phase 4) — it needs to scan all `pending` orders older than N minutes across the whole collection.
- The `products` `COLLECTION_GROUP` index supports the village-wide search bar (Section 2.7) hitting products across *all* shops simultaneously.
- Single-field indexes (e.g., `where('isActive', '==', true)` alone) are auto-created by Firestore and don't need to be declared — only **composite** (multi-field) queries need explicit entries here.
- Geohash range queries for proximity (Phase 3.3) use single-field `geohash` ascending indexes, also auto-created — no composite index needed unless you combine geohash range with another `where` filter, in which case add it following the same pattern as the `craftsmen` index above.

---

*(Continued in Phase 3 — Core Workflows & Business Logic)*
## PHASE 3 — CORE WORKFLOWS & BUSINESS LOGIC (CRUD)

### 3.1 Authentication: Firebase Phone Auth (OTP) + Auto User Document Creation

**Flow:** Phone entry → `verifyPhoneNumber` → OTP screen → `signInWithCredential` → check if `/users/{uid}` exists → create if not → route to role selection (first-time) or home (returning).

**`auth_remote_datasource.dart`:**
```dart
class AuthRemoteDataSource {
  final FirebaseAuth _auth;
  AuthRemoteDataSource(this._auth);

  String? _verificationId;

  Future<void> sendOtp({
    required String phoneNumber, // E.164: +20XXXXXXXXXX
    required void Function() onCodeSent,
    required void Function(FirebaseAuthException) onError,
    required void Function(PhoneAuthCredential) onAutoVerified,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) {
        // Android auto-retrieval — skip manual OTP entry when SMS is read automatically
        onAutoVerified(credential);
      },
      verificationFailed: onError,
      codeSent: (verificationId, resendToken) {
        _verificationId = verificationId;
        onCodeSent();
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<UserCredential> verifyOtp(String smsCode) async {
    if (_verificationId == null) {
      throw const AuthException('لم يتم إرسال رمز التحقق بعد');
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: smsCode,
    );
    return _auth.signInWithCredential(credential);
  }
}
```

**`auth_repository_impl.dart` — auto-creates the user document:**
```dart
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _authDs;
  final UserRemoteDataSource _userDs;

  AuthRepositoryImpl(this._authDs, this._userDs);

  @override
  Future<Result<AppUser, Failure>> verifyOtpAndSync(String smsCode) async {
    try {
      final credential = await _authDs.verifyOtp(smsCode);
      final firebaseUser = credential.user!;

      // Check if Firestore profile exists — Auth account creation does NOT imply Firestore doc exists
      var userDoc = await _userDs.getUser(firebaseUser.uid);

      if (userDoc == null) {
        // First-time sign-in: create the Firestore profile now
        final newUser = AppUserModel(
          uid: firebaseUser.uid,
          phoneNumber: firebaseUser.phoneNumber!,
          displayName: 'مستخدم جديد', // placeholder, edited in role-selection/profile-setup
          role: UserRole.unknown,      // forces redirect to /role-selection (Phase 1 router)
          isActive: true,
          isPhoneVerified: true,
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
        );
        await _userDs.createUser(newUser);
        userDoc = newUser;
      }

      // Register this device's FCM token regardless of new/returning
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await _userDs.addFcmToken(firebaseUser.uid, fcmToken);
      }

      return Result.success(userDoc);
    } on FirebaseAuthException catch (e) {
      return Result.failure(ErrorMapper.fromAuthException(e));
    }
  }
}
```

**Why the existence check matters:** Firebase Auth and Firestore are *separate systems*. A successful `signInWithCredential` only guarantees an Auth account — it says nothing about whether a corresponding `/users/{uid}` document exists. Skipping this check is the single most common bug in Phone-Auth Flutter apps (users hitting null-data crashes on their first launch). The check-then-create must also be **mirrored in Security Rules** (Phase 6) as a `create`-only allow rule scoped to `request.auth.uid == userId`, so a malicious client can't create a doc for a different UID.

---

### 3.2 Cart & Checkout: Local State → Firestore Transaction

**Cart lives entirely client-side (Hive-backed), never in Firestore**, until the moment of checkout. This is deliberate: carts are mutated extremely frequently (every tap), and syncing every quantity change to Firestore would be wasteful writes and a poor offline experience. Only the final, confirmed order touches Firestore.

**`cart_provider.dart` (Riverpod `Notifier`, Hive-backed):**
```dart
@riverpod
class CartNotifier extends _$CartNotifier {
  late Box<CartItemModel> _box;

  @override
  List<CartItem> build() {
    _box = Hive.box<CartItemModel>('cart');
    return _box.values.map((m) => m.toEntity()).toList();
  }

  void addItem(Product product, {int quantity = 1}) {
    final existing = _box.get(product.id);
    if (existing != null) {
      _box.put(product.id, existing.copyWith(quantity: existing.quantity + quantity));
    } else {
      _box.put(product.id, CartItemModel.fromProduct(product, quantity));
    }
    state = _box.values.map((m) => m.toEntity()).toList();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      _box.delete(productId);
    } else {
      final item = _box.get(productId);
      if (item != null) _box.put(productId, item.copyWith(quantity: quantity));
    }
    state = _box.values.map((m) => m.toEntity()).toList();
  }

  void clear() {
    _box.clear();
    state = [];
  }

  /// Guard: cart must contain items from exactly ONE shop at a time
  /// (multi-vendor carts add huge complexity to delivery/fee logic — explicitly out of scope for v1)
  bool canAddFromShop(String shopId) {
    if (state.isEmpty) return true;
    return state.first.shopId == shopId;
  }
}

@riverpod
double cartSubtotal(Ref ref) {
  final items = ref.watch(cartNotifierProvider);
  return items.fold(0.0, (sum, item) => sum + (item.unitPrice * item.quantity));
}
```

**Checkout — placing the order via a Firestore Transaction:**

The order write is NOT a simple `add()`. It must, in a single atomic transaction:
1. Re-read each product's current price and stock (never trust the client-cached cart price).
2. Validate stock availability.
3. Decrement `stockQuantity` on each product.
4. Write the new `orders/{orderId}` document with server-validated, snapshotted prices.

This is most safely done **inside a Cloud Function (callable)**, not directly from the client, because:
- Stock decrements across multiple products must be atomic with order creation — a client-side transaction *can* do this, but a malicious/tampered client could submit a transaction that skips the stock check entirely since Security Rules alone cannot easily express "decrement this counter by exactly the quantity in this array, validated against price." A callable function lets you run trusted server logic.
- Pricing must be computed from server-truth product docs, not client input.

**Client side — invoking the callable:**
```dart
// data/repositories/order_repository_impl.dart
class OrderRepositoryImpl implements OrderRepository {
  final FirebaseFunctions _functions;
  OrderRepositoryImpl(this._functions);

  @override
  Future<Result<String, Failure>> placeOrder(OrderDraft draft) async {
    try {
      final callable = _functions.httpsCallable('placeOrder');
      final response = await callable.call({
        'shopId': draft.shopId,
        'items': draft.items.map((i) => {
          'productId': i.productId,
          'quantity': i.quantity,
        }).toList(),
        'deliveryType': draft.deliveryType.name,
        'dropoffGeopoint': {
          'lat': draft.dropoffLocation.latitude,
          'lng': draft.dropoffLocation.longitude,
        },
        'dropoffAddressLabel': draft.addressLabel,
        'paymentMethod': draft.paymentMethod.name,
        'customerNote': draft.note,
      });
      final orderId = response.data['orderId'] as String;
      return Result.success(orderId);
    } on FirebaseFunctionsException catch (e) {
      return Result.failure(ErrorMapper.fromFunctionsException(e));
    }
  }
}
```

**Server side (Node.js callable — full implementation detail in Phase 4, signature shown here):**
```typescript
// functions/src/callable/placeOrder.ts
export const placeOrder = onCall(async (request) => {
  const { auth, data } = request;
  if (!auth) throw new HttpsError('unauthenticated', 'يجب تسجيل الدخول');

  return firestore.runTransaction(async (tx) => {
    const productRefs = data.items.map((i: any) =>
      firestore.doc(`shops/${data.shopId}/products/${i.productId}`)
    );
    const productSnaps = await Promise.all(productRefs.map((r: any) => tx.get(r)));

    let subtotal = 0;
    const snapshotItems = [];

    for (let i = 0; i < productSnaps.length; i++) {
      const snap = productSnaps[i];
      if (!snap.exists) throw new HttpsError('not-found', 'منتج غير موجود');
      const product = snap.data()!;
      const requestedQty = data.items[i].quantity;

      if (product.stockQuantity < requestedQty) {
        throw new HttpsError('failed-precondition', `الكمية غير متوفرة: ${product.name}`);
      }

      const unitPrice = product.discountPrice ?? product.price; // server-authoritative price
      subtotal += unitPrice * requestedQty;

      snapshotItems.push({
        productId: snap.id,
        productName: product.name,
        imageUrl: product.imageUrls?.[0] ?? null,
        unitPrice,
        quantity: requestedQty,
        lineTotal: unitPrice * requestedQty,
      });

      // Decrement stock atomically within the same transaction
      tx.update(productRefs[i], {
        stockQuantity: product.stockQuantity - requestedQty,
        isInStock: (product.stockQuantity - requestedQty) > 0,
      });
    }

    const shopSnap = await tx.get(firestore.doc(`shops/${data.shopId}`));
    const shop = shopSnap.data()!;
    const deliveryFee = data.deliveryType === 'delivery' ? shop.baseDeliveryFee : 0;
    const totalAmount = subtotal + deliveryFee;

    const orderRef = firestore.collection('orders').doc();
    tx.set(orderRef, {
      orderId: orderRef.id,
      orderNumber: generateOrderNumber(),
      customerId: auth.uid,
      shopId: data.shopId,
      shopName: shop.shopName,
      vendorId: shop.ownerId,
      driverId: null,
      items: snapshotItems,
      pricing: { subtotal, deliveryFee, serviceFee: 0, discountAmount: 0, taxAmount: 0, totalAmount },
      payment: { method: data.paymentMethod, status: 'pending', gatewayReference: null, paidAt: null },
      delivery: {
        type: data.deliveryType,
        dropoffGeopoint: new GeoPoint(data.dropoffGeopoint.lat, data.dropoffGeopoint.lng),
        dropoffAddressLabel: data.dropoffAddressLabel,
        distanceKm: haversineKm(shop.location.geopoint, data.dropoffGeopoint),
        estimatedMinutes: null,
      },
      status: 'pending',
      statusHistory: [{ status: 'pending', timestamp: FieldValue.serverTimestamp(), changedBy: auth.uid, note: null }],
      customerNote: data.customerNote ?? '',
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      acceptedAt: null,
      deliveredAt: null,
    });

    return { orderId: orderRef.id };
  });
});
```

**After successful order placement:** clear the local Hive cart (`ref.read(cartNotifierProvider.notifier).clear()`), then navigate to `/order/{orderId}` for live tracking.

---

### 3.3 Geolocation & Maps

**Packages:**
```yaml
dependencies:
  geolocator: ^13.0.2
  geocoding: ^3.0.0
  google_maps_flutter: ^2.10.0
  geoflutterfire_plus: ^0.0.32   # geohash query helper for Firestore proximity search
```

**`location_service.dart`:**
```dart
class LocationService {
  Future<Position> getCurrentLocation() async {
    final permission = await _ensurePermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw const LocationException('يجب السماح بالوصول للموقع لاستخدام هذه الميزة');
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<LocationPermission> _ensurePermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  double distanceKm(GeoPoint a, GeoPoint b) {
    final meters = Geolocator.distanceBetween(
      a.latitude, a.longitude, b.latitude, b.longitude,
    );
    return meters / 1000;
  }
}
```

**Nearby craftsmen query (geohash-bucketed, then precise-filtered client-side):**
```dart
// domain/usecases/get_nearby_craftsmen_usecase.dart
@riverpod
Future<List<Craftsman>> nearbyCraftsmen(
  Ref ref, {
  required GeoPoint center,
  required double radiusKm,
  String? professionFilter,
}) async {
  final firestore = ref.watch(firestoreProvider);

  // geoflutterfire_plus computes the set of geohash prefix bounds covering the radius
  final geoPoint = GeoFirePoint(center);
  final collection = firestore.collection('craftsmen');

  Query query = collection
      .where('isApproved', isEqualTo: true)
      .where('isAvailableNow', isEqualTo: true);

  if (professionFilter != null) {
    query = query.where('profession', isEqualTo: professionFilter);
  }

  final results = await GeoCollectionReference(collection).fetchWithinWithDistance(
    center: geoPoint,
    radiusInKm: radiusKm,
    field: 'serviceArea.centerGeohash',
    geopointFrom: (data) => (data['serviceArea']['centerGeopoint'] as GeoPoint),
    queryBuilder: (q) => query, // applies the role/availability filters above on top of the geo bounds
  );

  return results
      .map((doc) => CraftsmanModel.fromFirestore(doc.documentSnapshot).toEntity())
      .toList()
    ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm)); // precise client-side sort
}
```

**Why geohash + client filter, not a pure Firestore query:** Firestore range queries on a geohash field return all documents in the surrounding geohash "boxes," which is a **superset** that includes some false positives near the box edges (a known geohash limitation — the boxes are square-ish approximations of a circle). The library handles fetching the right set of boxes; you still must Haversine-filter and sort the results precisely client-side, which `fetchWithinWithDistance` does for you in one call.

**Delivery distance/fee calculation at checkout** uses the same `Geolocator.distanceBetween` Haversine helper, called server-side inside the `placeOrder` Cloud Function (shown in 3.2) so the fee can't be tampered with by a modified client claiming a shorter distance.

---

*(Continued in Phase 4 — Cloud Functions)*
## PHASE 4 — CLOUD FUNCTIONS (NODE.JS / TYPESCRIPT)

**Setup (`functions/package.json` essentials):**
```json
{
  "engines": { "node": "20" },
  "main": "lib/index.js",
  "dependencies": {
    "firebase-admin": "^12.6.0",
    "firebase-functions": "^6.1.0"
  },
  "devDependencies": {
    "typescript": "^5.6.3"
  }
}
```

We use **Firebase Functions v2** (`firebase-functions/v2`) throughout — better cold-start performance, concurrency control, and a unified `onCall`/`onDocumentWritten`/`onSchedule` API surface versus the legacy v1 SDK.

```typescript
// functions/src/index.ts
import { initializeApp } from 'firebase-admin/app';
initializeApp();

export { onReviewCreated } from './triggers/onReviewCreated';
export { onOrderStatusChanged } from './triggers/onOrderStatusChanged';
export { onUserWrite } from './triggers/onUserWrite';
export { autoCancelOrders } from './scheduled/autoCancelOrders';
export { placeOrder } from './callable/placeOrder'; // from Phase 3.2
```

---

### 4.1 Rating Aggregation Trigger

**Goal:** when a review is created under `shops/{shopId}/reviews/{reviewId}` OR `craftsmen/{id}/reviews/{reviewId}`, atomically update the parent's `avgRating`, `reviewCount`, `ratingSum` — without ever reading the full reviews subcollection.

```typescript
// functions/src/triggers/onReviewCreated.ts
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

const db = getFirestore();

export const onReviewCreated = onDocumentCreated(
  '{parentCollection}/{parentId}/reviews/{reviewId}',
  async (event) => {
    const { parentCollection, parentId } = event.params;

    // Guard: only apply to the two valid parent types — collectionGroup wildcards
    // match ANY top-level collection named differently, so we whitelist explicitly.
    if (!['shops', 'craftsmen'].includes(parentCollection)) return;

    const review = event.data?.data();
    if (!review) return;

    const rating: number = review.rating;
    const parentRef = db.collection(parentCollection).doc(parentId);

    await db.runTransaction(async (tx) => {
      const parentSnap = await tx.get(parentRef);
      if (!parentSnap.exists) return;

      const currentSum = parentSnap.data()?.ratingSum ?? 0;
      const currentCount = parentSnap.data()?.reviewCount ?? 0;

      const newSum = currentSum + rating;
      const newCount = currentCount + 1;

      tx.update(parentRef, {
        ratingSum: newSum,
        reviewCount: newCount,
        avgRating: Math.round((newSum / newCount) * 10) / 10, // 1 decimal place
        updatedAt: FieldValue.serverTimestamp(),
      });
    });
  }
);
```

**Note on deletions:** if you allow review deletion (e.g., admin moderation), add a mirrored `onDocumentDeleted` trigger that *decrements* `ratingSum`/`reviewCount` using the same transactional pattern. Not included by default since reviews are typically append-only/immutable in this product, with moderation handled via a `isHidden: true` flag instead of hard deletion (preserves the audit trail) — if you flag-hide a review, exclude `isHidden == true` reviews from the aggregate by checking the flag in the trigger before applying the delta.

---

### 4.2 Push Notifications — Order Status Updates

**Trigger:** fires on every write to `orders/{orderId}`, diffs `before.status` vs `after.status`, and sends a targeted FCM message to whichever party needs to act next.

```typescript
// functions/src/triggers/onOrderStatusChanged.ts
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { getFirestore } from 'firebase-admin/firestore';
import { sendFcmToUser } from '../utils/fcmSender';

const db = getFirestore();

const STATUS_MESSAGES: Record<string, (orderNumber: string) => { title: string; body: string; targetRole: 'customer' | 'vendor' | 'driver' }> = {
  accepted: (n) => ({ title: 'تم قبول طلبك', body: `الطلب ${n} قيد التجهيز الآن`, targetRole: 'customer' }),
  preparing: (n) => ({ title: 'جاري تجهيز طلبك', body: `الطلب ${n} قيد التحضير`, targetRole: 'customer' }),
  in_transit: (n) => ({ title: 'الطلب في الطريق', body: `الطلب ${n} في طريقه إليك الآن`, targetRole: 'customer' }),
  delivered: (n) => ({ title: 'تم التوصيل', body: `تم تسليم الطلب ${n} بنجاح`, targetRole: 'customer' }),
  cancelled: (n) => ({ title: 'تم إلغاء الطلب', body: `تم إلغاء الطلب ${n}`, targetRole: 'customer' }),
};

export const onOrderStatusChanged = onDocumentUpdated('orders/{orderId}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after) return;
  if (before.status === after.status) return; // only react to actual status transitions

  const orderNumber = after.orderNumber;

  // 1. Notify the customer for the standard lifecycle messages
  const config = STATUS_MESSAGES[after.status];
  if (config) {
    const { title, body } = config(orderNumber);
    await sendFcmToUser(after.customerId, { title, body, data: { type: 'order_update', orderId: event.params.orderId } });
  }

  // 2. New order placed (pending) -> notify the VENDOR to take action
  if (after.status === 'pending' && before.status === undefined) {
    await sendFcmToUser(after.vendorId, {
      title: 'طلب جديد!',
      body: `لديك طلب جديد رقم ${orderNumber}`,
      data: { type: 'new_order', orderId: event.params.orderId },
    });
  }

  // 3. Order accepted by vendor and marked ready -> notify available DRIVERS in range
  if (after.status === 'accepted' && after.delivery?.type === 'delivery' && !after.driverId) {
    const nearbyDriversSnap = await db.collection('users')
      .where('role', '==', 'driver')
      .where('driverProfile.isAvailable', '==', true)
      .limit(20)
      .get();

    const tokens = nearbyDriversSnap.docs.flatMap((d) => d.data().fcmTokens ?? []);
    if (tokens.length > 0) {
      await sendFcmToUser(null, {
        title: 'طلب توصيل متاح',
        body: `طلب جديد بانتظار سائق - ${orderNumber}`,
        data: { type: 'delivery_available', orderId: event.params.orderId },
      }, tokens);
    }
  }
});
```

**`fcmSender.ts` utility (handles multi-device fan-out and stale token cleanup):**
```typescript
// functions/src/utils/fcmSender.ts
import { getMessaging } from 'firebase-admin/messaging';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

const db = getFirestore();
const messaging = getMessaging();

interface NotificationPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
}

export async function sendFcmToUser(
  userId: string | null,
  payload: NotificationPayload,
  explicitTokens?: string[],
) {
  let tokens = explicitTokens;

  if (!tokens) {
    if (!userId) return;
    const userSnap = await db.collection('users').doc(userId).get();
    tokens = userSnap.data()?.fcmTokens ?? [];
  }
  if (!tokens || tokens.length === 0) return;

  const response = await messaging.sendEachForMulticast({
    tokens,
    notification: { title: payload.title, body: payload.body },
    data: payload.data ?? {},
    android: { priority: 'high' },
    apns: { headers: { 'apns-priority': '10' } },
  });

  // Clean up tokens that are no longer valid (uninstalled app, expired token)
  const staleTokens: string[] = [];
  response.responses.forEach((r, i) => {
    if (!r.success && (r.error?.code === 'messaging/registration-token-not-registered')) {
      staleTokens.push(tokens![i]);
    }
  });

  if (staleTokens.length > 0 && userId) {
    await db.collection('users').doc(userId).update({
      fcmTokens: FieldValue.arrayRemove(...staleTokens),
    });
  }
}
```

---

### 4.3 Auto-Cancellation — Scheduled Pub/Sub Function

**Goal:** any order stuck in `pending` (vendor hasn't accepted/rejected) for longer than a threshold (e.g., 15 minutes) gets auto-cancelled, freeing the customer to reorder elsewhere — critical in a rural context where a vendor might be away from their phone.

```typescript
// functions/src/scheduled/autoCancelOrders.ts
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { getFirestore, FieldValue, Timestamp } from 'firebase-admin/firestore';
import { sendFcmToUser } from '../utils/fcmSender';

const db = getFirestore();
const PENDING_TIMEOUT_MINUTES = 15;

export const autoCancelOrders = onSchedule('every 5 minutes', async () => {
  const cutoff = Timestamp.fromMillis(Date.now() - PENDING_TIMEOUT_MINUTES * 60 * 1000);

  // Uses the [status ASC, createdAt ASC] composite index from Phase 2.8
  const staleOrdersSnap = await db.collection('orders')
    .where('status', '==', 'pending')
    .where('createdAt', '<=', cutoff)
    .limit(100) // batch-process to respect function timeout, picks up stragglers next run
    .get();

  if (staleOrdersSnap.empty) return;

  const batch = db.batch();

  for (const doc of staleOrdersSnap.docs) {
    const order = doc.data();

    batch.update(doc.ref, {
      status: 'cancelled',
      cancellation: {
        reason: 'لم يتم الرد على الطلب من قبل المتجر',
        cancelledBy: 'system',
        cancelledAt: FieldValue.serverTimestamp(),
      },
      statusHistory: FieldValue.arrayUnion({
        status: 'cancelled',
        timestamp: Timestamp.now(), // arrayUnion cannot use serverTimestamp() inside the map
        changedBy: 'system',
        note: 'Auto-cancelled: vendor did not respond in time',
      }),
      updatedAt: FieldValue.serverTimestamp(),
    });

    // Restock the items that were decremented at order-creation time
    for (const item of order.items) {
      const productRef = db.doc(`shops/${order.shopId}/products/${item.productId}`);
      batch.update(productRef, {
        stockQuantity: FieldValue.increment(item.quantity),
        isInStock: true,
      });
    }
  }

  await batch.commit();

  // Notify customers after the batch commits successfully
  for (const doc of staleOrdersSnap.docs) {
    const order = doc.data();
    await sendFcmToUser(order.customerId, {
      title: 'تم إلغاء الطلب تلقائياً',
      body: `للأسف، لم يستجب المتجر للطلب ${order.orderNumber} في الوقت المناسب`,
      data: { type: 'order_auto_cancelled', orderId: doc.id },
    });
  }
});
```

**Important caveat on `arrayUnion` + `serverTimestamp()`:** Firestore disallows `FieldValue.serverTimestamp()` *inside* an object passed to `arrayUnion()` (it can't resolve a server value within an array element atomically). Use `Timestamp.now()` (function execution time, accurate enough for an audit log entry) instead, as shown above — this is a common Cloud Functions gotcha worth flagging explicitly since it fails silently as a *wrong type* error only at deploy/runtime, not at compile time.

---

### 4.4 Supporting Trigger: Role Custom Claims Sync

Referenced in Phase 1.4 — required so Security Rules can cheaply read `request.auth.token.role`:

```typescript
// functions/src/triggers/onUserWrite.ts
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { getAuth } from 'firebase-admin/auth';

export const onUserWrite = onDocumentWritten('users/{uid}', async (event) => {
  const after = event.data?.after.data();
  if (!after) return; // document deleted

  const before = event.data?.before.data();
  if (before?.role === after.role) return; // no role change, skip the Auth API call

  await getAuth().setCustomUserClaims(event.params.uid, { role: after.role });
});
```

**Critical client-side implication:** custom claims are baked into the ID token at the time it's issued/refreshed — they do **not** propagate instantly. After a role change (e.g., admin approves a vendor), the client must call `await FirebaseAuth.instance.currentUser?.getIdToken(true)` (force refresh) before the new role takes effect in Security Rules checks. Surface this as an explicit "بانتظار موافقة الإدارة... سيتم تفعيل حسابك قريباً" pending state in the vendor onboarding UI rather than silently failing writes.

---

*(Continued in Phase 5 — Offline-First & Error Handling)*
## PHASE 5 — OFFLINE-FIRST & ERROR HANDLING

This phase is the difference between an app that's merely "functional" and one that's actually usable in a rural Egyptian village with patchy 2G/3G coverage and frequent connectivity drops. Treat offline as the **default state to design for**, not an edge case to patch in later.

### 5.1 Firestore Offline Persistence Configuration

Firestore's offline cache is enabled by default on mobile, but the **default cache size (100MB) is too small** for an image-heavy multi-vendor catalog, and the default settings don't fully exploit what's available. Configure explicitly at app startup, before any other Firestore call:

```dart
// main.dart, before runApp()
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, // critical: village catalogs + chat history add up
  );

  await Hive.initFlutter();
  Hive.registerAdapter(CartItemModelAdapter());
  await Hive.openBox<CartItemModel>('cart');

  runApp(const ProviderScope(child: VillageMarketApp()));
}
```

**Why `CACHE_SIZE_UNLIMITED`:** the default 100MB cap means Firestore silently evicts older cached documents (LRU) once exceeded — in practice, a villager who browsed several shops yesterday may find half the product images and listings gone from cache today even with zero connectivity, which reads as "the app is broken." Disk space on rural budget Android phones is the real constraint here, not Firestore's cap — and Firestore's own document cache (text data, not images — those are handled separately in 5.2) rarely approaches gigabyte scale even for a fairly large catalog, since it's just JSON-like structured data.

**Reads-from-cache-first pattern for critical screens (shop list, product catalog):**

By default, Firestore tries network first and falls back to cache on failure/timeout — but on a *slow* (not fully dead) connection, this means a multi-second hang before falling back, since "slow" isn't the same trigger as "offline." For screens where stale-but-instant data is preferable to a spinner, explicitly prefer cache first, then reconcile:

```dart
@riverpod
class ShopListNotifier extends _$ShopListNotifier {
  @override
  Future<List<Shop>> build() async {
    final firestore = ref.watch(firestoreProvider);
    final query = firestore.collection('shops')
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true);

    // 1. Serve cache immediately if present — near-instant on a slow connection
    try {
      final cached = await query.get(const GetOptions(source: Source.cache));
      if (cached.docs.isNotEmpty) {
        // Emit cached data first without ending the build — schedule a background refresh
        Future.microtask(() => _refreshFromServer(query));
        return cached.docs.map((d) => ShopModel.fromFirestore(d).toEntity()).toList();
      }
    } catch (_) {
      // Cache miss (e.g., first launch) — fall through to network
    }

    // 2. No cache available — must hit network
    final serverSnap = await query.get(const GetOptions(source: Source.serverAndCache));
    return serverSnap.docs.map((d) => ShopModel.fromFirestore(d).toEntity()).toList();
  }

  Future<void> _refreshFromServer(Query query) async {
    try {
      final freshSnap = await query.get(const GetOptions(source: Source.server));
      state = AsyncData(freshSnap.docs.map((d) => ShopModel.fromFirestore(d).toEntity()).toList());
    } catch (_) {
      // Network refresh failed silently — user keeps seeing valid cached data, which is correct behavior
    }
  }
}
```

For screens needing **live updates** (order tracking, chat), use `.snapshots()` as normal — Firestore's realtime listener already transparently serves cached data instantly and patches in server updates as they arrive, with `metadata.isFromCache` available to show a subtle "syncing..." indicator if desired:

```dart
@riverpod
Stream<Order> watchOrder(Ref ref, String orderId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.doc('orders/$orderId')
      .snapshots(includeMetadataChanges: true)
      .map((snap) => OrderModel.fromFirestore(snap).toEntity());
}
```

### 5.2 Cached Network Images for the Product Catalog

**Package:** `cached_network_image: ^3.4.1`, backed by `flutter_cache_manager`'s default disk cache.

```dart
// core/widgets/cached_image.dart
class AppCachedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _placeholder();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 200),
      memCacheWidth: width != null ? (width! * 2).round() : null, // 2x for device pixel ratio, capped
      placeholder: (context, url) => _shimmerPlaceholder(),
      errorWidget: (context, url, error) => _placeholder(showRetryIcon: true),
      cacheManager: AppImageCacheManager.instance, // custom config below
    );
  }

  Widget _shimmerPlaceholder() => Container(
    width: width, height: height,
    color: AppColors.shimmerBase,
    child: const Center(child: SizedBox(
      width: 20, height: 20,
      child: CircularProgressIndicator(strokeWidth: 2),
    )),
  );

  Widget _placeholder({bool showRetryIcon = false}) => Container(
    width: width, height: height,
    color: AppColors.imagePlaceholderBg,
    child: Icon(
      showRetryIcon ? Icons.refresh : Icons.image_not_supported_outlined,
      color: AppColors.imagePlaceholderIcon,
    ),
  );
}
```

**Custom cache manager — extended retention for rural low-connectivity use:**
```dart
// core/services/app_image_cache_manager.dart
class AppImageCacheManager extends CacheManager {
  static const key = 'villageMarketImageCache';
  static final AppImageCacheManager instance = AppImageCacheManager._();

  AppImageCacheManager._() : super(
    Config(
      key,
      stalePeriod: const Duration(days: 30),     // keep images valid for a month — vendors don't change photos often
      maxNrOfCacheObjects: 1000,                  // generous cap for a village-scale catalog
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}
```

**Upload-side optimization (equally important — don't just cache large images, serve small ones):** when vendors upload product photos via the Storage upload flow, **compress and resize client-side before upload** using `flutter_image_compress`, targeting ~80KB per product thumbnail. This reduces both the vendor's upload data cost and every villager's download data cost — multiplied across however many times that image is viewed, this matters far more for rural data budgets than any client-side cache tuning.

```dart
Future<File> compressForUpload(File original) async {
  final targetPath = '${original.path}_compressed.jpg';
  final result = await FlutterImageCompress.compressAndGetFile(
    original.path,
    targetPath,
    quality: 70,
    minWidth: 800,
    minHeight: 800,
  );
  return File(result!.path);
}
```

### 5.3 Retry Mechanisms for Failed Calls

**`retry_policy.dart` — exponential backoff with jitter, used for Cloud Function calls and any non-stream Firestore write:**

```dart
// core/network/retry_policy.dart
class RetryPolicy {
  static Future<T> execute<T>(
    Future<T> Function() action, {
    int maxAttempts = 3,
    Duration baseDelay = const Duration(seconds: 1),
    bool Function(Object error)? retryIf,
  }) async {
    var attempt = 0;
    while (true) {
      attempt++;
      try {
        return await action();
      } catch (e) {
        final shouldRetry = retryIf?.call(e) ?? _defaultRetryableCheck(e);
        if (attempt >= maxAttempts || !shouldRetry) rethrow;

        final jitterMs = Random().nextInt(300);
        final delay = baseDelay * pow(2, attempt - 1) + Duration(milliseconds: jitterMs);
        await Future.delayed(delay);
      }
    }
  }

  static bool _defaultRetryableCheck(Object error) {
    if (error is FirebaseFunctionsException) {
      // Retry on transient server/network issues, NOT on business-logic rejections
      return ['unavailable', 'deadline-exceeded', 'internal'].contains(error.code);
    }
    if (error is FirebaseException) {
      return ['unavailable', 'deadline-exceeded', 'aborted'].contains(error.code);
    }
    if (error is SocketException || error is TimeoutException) return true;
    return false;
  }
}
```

**Usage — wrapping the checkout call from Phase 3.2:**
```dart
Future<void> submitOrder(Order draft) async {
  state = const AsyncLoading();
  try {
    final orderId = await RetryPolicy.execute(
      () => ref.read(orderRepositoryProvider).placeOrderRaw(draft),
      maxAttempts: 3,
      retryIf: (e) => e is FirebaseFunctionsException &&
          ['unavailable', 'deadline-exceeded'].contains(e.code), // NEVER retry 'failed-precondition' (out of stock)
    );
    state = AsyncData(orderId);
  } catch (e, st) {
    state = AsyncError(e, st);
  }
}
```

**Important nuance:** never blindly retry order placement on *any* failure. `failed-precondition` (out of stock) or `invalid-argument` are business-logic rejections — retrying them wastes the user's time and data and will fail identically every time. Only retry genuinely transient infrastructure errors (`unavailable`, `deadline-exceeded`). This distinction is encoded in `_defaultRetryableCheck` above and must be respected everywhere `RetryPolicy` is used.

### 5.4 Connectivity-Aware UI

```dart
// core/network/connectivity_service.dart
@riverpod
Stream<bool> isOnline(Ref ref) {
  return Connectivity().onConnectivityChanged.asyncMap((results) async {
    if (results.every((r) => r == ConnectivityResult.none)) return false;
    // connectivity_plus only confirms a network INTERFACE exists, not actual internet reachability —
    // do a lightweight real check, since rural WiFi/cell towers can be "connected" but not routed
    return _hasRealInternetAccess();
  });
}

Future<bool> _hasRealInternetAccess() async {
  try {
    final result = await InternetAddress.lookup('firestore.googleapis.com')
        .timeout(const Duration(seconds: 3));
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}
```

```dart
// core/widgets/offline_banner.dart — mounted once at the app shell level (Phase 1 ShellRoute)
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnlineAsync = ref.watch(isOnlineProvider);
    final isOffline = isOnlineAsync.valueOrNull == false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isOffline ? 36 : 0,
      color: AppColors.warningBg,
      child: isOffline
          ? const Center(
              child: Text('أنت غير متصل بالإنترنت - سيتم المزامنة عند عودة الاتصال',
                  style: TextStyle(fontSize: 13)),
            )
          : null,
    );
  }
}
```

**Design principle for the whole app:** every screen that writes data (checkout, chat send, review submission) must **optimistically update local UI state immediately**, queue the write, and only show an error state if the write *definitively* fails after retries — never block the UI waiting on a round-trip in a connectivity context where round-trips can take 10+ seconds. Firestore's own offline write queue handles this natively for direct Firestore writes (writes made offline are queued and auto-flushed on reconnect, with local listeners updating instantly) — but since checkout goes through a **callable Cloud Function** (Phase 3.2, by design, for server-side validation), that path does *not* get automatic offline queuing, and must show an explicit "سيتم إرسال الطلب عند توفر الاتصال" pending state with manual retry, backed by a local Hive-persisted "pending orders" queue that retries on reconnect (driven by the `isOnlineProvider` stream above).

---

*(Continued in Phase 6 — Firebase Security Rules)*
## PHASE 6 — FIREBASE SECURITY RULES

This is your **actual** security boundary (not the client-side route guards from Phase 1 — those are UX only). Every rule below assumes the `role` custom claim is synced via the `onUserWrite` trigger from Phase 4.4.

### 6.1 `firestore.rules`

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // ============ HELPER FUNCTIONS ============

    function isSignedIn() {
      return request.auth != null;
    }

    function isOwner(uid) {
      return isSignedIn() && request.auth.uid == uid;
    }

    function hasRole(role) {
      return isSignedIn() && request.auth.token.role == role;
    }

    function isActiveUser() {
      // Defense-in-depth: even if a claim is stale, block soft-banned accounts at the data layer too
      return isSignedIn() &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isActive == true;
    }

    // Vendor must own the specific shop referenced — checked via a get() on the shop doc
    function isShopOwner(shopId) {
      return isSignedIn() &&
        get(/databases/$(database)/documents/shops/$(shopId)).data.ownerId == request.auth.uid;
    }

    function isParticipant(participantIds) {
      return isSignedIn() && request.auth.uid in participantIds;
    }

    // Whitelist of fields a client is allowed to touch — prevents clients from writing
    // server-only aggregate fields like avgRating, reviewCount, stockQuantity directly.
    function onlyAffectsKeys(allowedKeys) {
      return request.resource.data.diff(resource.data).affectedKeys().hasOnly(allowedKeys);
    }

    // ============ USERS ============

    match /users/{userId} {
      allow read: if isSignedIn(); // public-ish profile data (name, shop link) needed broadly for display
      allow create: if isOwner(userId)
                    && request.resource.data.uid == userId
                    && request.resource.data.role == 'unknown'; // role escalation must go through admin/Cloud Function, never client-set on create
      allow update: if isOwner(userId)
                    && onlyAffectsKeys([
                         'displayName', 'profileImageUrl', 'fcmTokens', 'isOnline',
                         'lastSeenAt', 'location', 'addressBook', 'updatedAt'
                       ]); // role, isActive, vendorProfile.isApproved etc. are NEVER client-writable
      allow delete: if false; // soft-delete only, via isActive flag — never hard-delete user data
    }

    // ============ SHOPS ============

    match /shops/{shopId} {
      allow read: if true; // public catalog browsing — no auth required to browse
      allow create: if hasRole('vendor') && isActiveUser()
                    && request.resource.data.ownerId == request.auth.uid
                    && request.resource.data.isApproved == false; // vendors cannot self-approve
      allow update: if hasRole('vendor') && isShopOwner(shopId)
                    && onlyAffectsKeys([
                         'shopName', 'shopNameLower', 'description', 'logoUrl', 'coverImageUrl',
                         'category', 'location', 'operatingHours', 'isManuallyOverrideClosed',
                         'deliveryRadiusKm', 'minOrderAmount', 'baseDeliveryFee', 'updatedAt'
                       ]); // isApproved, avgRating, reviewCount, productCount are Cloud-Function-only
      allow update: if hasRole('admin')
                    && onlyAffectsKeys(['isApproved', 'isActive', 'updatedAt']); // admin approval gate
      allow delete: if false;

      // --- products subcollection ---
      match /products/{productId} {
        allow read: if true;
        allow create: if hasRole('vendor') && isShopOwner(shopId)
                      && request.resource.data.shopId == shopId;
        allow update: if hasRole('vendor') && isShopOwner(shopId)
                      && onlyAffectsKeys([
                           'name', 'nameLower', 'description', 'category', 'imageUrls',
                           'price', 'discountPrice', 'unit', 'isAvailable', 'updatedAt'
                         ]); // stockQuantity is ONLY mutated server-side (placeOrder Cloud Function)
        allow delete: if hasRole('vendor') && isShopOwner(shopId);
      }

      // --- reviews subcollection ---
      match /reviews/{reviewId} {
        allow read: if true;
        allow create: if isSignedIn() && isActiveUser()
                      && request.resource.data.authorId == request.auth.uid
                      && request.resource.data.rating is int
                      && request.resource.data.rating >= 1 && request.resource.data.rating <= 5
                      // must reference a real, delivered order belonging to this customer — prevents fake reviews
                      && exists(/databases/$(database)/documents/orders/$(request.resource.data.relatedOrderId))
                      && get(/databases/$(database)/documents/orders/$(request.resource.data.relatedOrderId)).data.customerId == request.auth.uid
                      && get(/databases/$(database)/documents/orders/$(request.resource.data.relatedOrderId)).data.status == 'delivered';
        allow update: if (
                        // author can edit their own text/rating shortly after posting — optional, tighten if undesired
                        isOwner(resource.data.authorId) && onlyAffectsKeys(['rating', 'comment'])
                      ) || (
                        // vendor can reply once
                        hasRole('vendor') && isShopOwner(shopId) && onlyAffectsKeys(['vendorReply'])
                      );
        allow delete: if hasRole('admin'); // moderation only
      }
    }

    // ============ CRAFTSMEN ============

    match /craftsmen/{craftsmanId} {
      allow read: if true;
      allow create: if hasRole('vendor') && isActiveUser() // craftsmen are modeled as a vendor sub-type
                    && request.resource.data.userId == request.auth.uid
                    && request.resource.data.isApproved == false;
      allow update: if isSignedIn() && resource.data.userId == request.auth.uid
                    && onlyAffectsKeys([
                         'fullName', 'bio', 'yearsOfExperience', 'portfolioImageUrls',
                         'serviceArea', 'isAvailableNow', 'availabilitySchedule',
                         'priceRangeLabel', 'updatedAt'
                       ]);
      allow update: if hasRole('admin') && onlyAffectsKeys(['isApproved', 'isActive', 'updatedAt']);
      allow delete: if false;

      match /reviews/{reviewId} {
        allow read: if true;
        allow create: if isSignedIn() && isActiveUser()
                      && request.resource.data.authorId == request.auth.uid
                      && request.resource.data.rating is int
                      && request.resource.data.rating >= 1 && request.resource.data.rating <= 5;
        allow update: if isOwner(resource.data.authorId) && onlyAffectsKeys(['rating', 'comment']);
        allow delete: if hasRole('admin');
      }
    }

    // ============ ORDERS ============
    // NOTE: orders are primarily CREATED via the placeOrder Cloud Function (Phase 3.2/4),
    // which runs with Admin SDK privileges and bypasses these rules entirely.
    // These rules govern direct client READS and the narrow set of client-initiated status UPDATES.

    match /orders/{orderId} {
      allow read: if isSignedIn() && (
                     resource.data.customerId == request.auth.uid ||
                     resource.data.vendorId == request.auth.uid ||
                     resource.data.driverId == request.auth.uid ||
                     hasRole('admin')
                   );

      allow create: if false; // ALL order creation goes through the placeOrder callable function only

      // Vendor: accept / reject / mark preparing
      allow update: if hasRole('vendor') && resource.data.vendorId == request.auth.uid
                    && resource.data.status == 'pending'
                    && request.resource.data.status in ['accepted', 'cancelled']
                    && onlyAffectsKeys(['status', 'statusHistory', 'cancellation', 'acceptedAt', 'updatedAt']);

      allow update: if hasRole('vendor') && resource.data.vendorId == request.auth.uid
                    && resource.data.status == 'accepted'
                    && request.resource.data.status == 'preparing'
                    && onlyAffectsKeys(['status', 'statusHistory', 'updatedAt']);

      // Driver: self-assign to an unclaimed accepted order, then progress to in_transit / delivered
      allow update: if hasRole('driver') && isActiveUser()
                    && resource.data.driverId == null
                    && resource.data.status == 'accepted'
                    && request.resource.data.driverId == request.auth.uid
                    && onlyAffectsKeys(['driverId', 'driverName', 'updatedAt']);

      allow update: if hasRole('driver') && resource.data.driverId == request.auth.uid
                    && resource.data.status in ['accepted', 'preparing']
                    && request.resource.data.status == 'in_transit'
                    && onlyAffectsKeys(['status', 'statusHistory', 'updatedAt']);

      allow update: if hasRole('driver') && resource.data.driverId == request.auth.uid
                    && resource.data.status == 'in_transit'
                    && request.resource.data.status == 'delivered'
                    && onlyAffectsKeys(['status', 'statusHistory', 'payment', 'deliveredAt', 'updatedAt']);

      // Customer: cancel only while still pending (can't cancel after vendor has started preparing)
      allow update: if isSignedIn() && resource.data.customerId == request.auth.uid
                    && resource.data.status == 'pending'
                    && request.resource.data.status == 'cancelled'
                    && onlyAffectsKeys(['status', 'statusHistory', 'cancellation', 'updatedAt']);

      allow delete: if false;
    }

    // ============ CHATS ============

    match /chats/{threadId} {
      allow read: if isParticipant(resource.data.participantIds);
      allow create: if isSignedIn()
                    && isParticipant(request.resource.data.participantIds)
                    && request.resource.data.participantIds.size() == 2;
      allow update: if isParticipant(resource.data.participantIds)
                    && onlyAffectsKeys(['lastMessage', 'unreadCount', 'updatedAt']);
      allow delete: if false;

      match /messages/{messageId} {
        allow read: if isParticipant(get(/databases/$(database)/documents/chats/$(threadId)).data.participantIds);
        allow create: if isParticipant(get(/databases/$(database)/documents/chats/$(threadId)).data.participantIds)
                      && request.resource.data.senderId == request.auth.uid;
        allow update: if isParticipant(get(/databases/$(database)/documents/chats/$(threadId)).data.participantIds)
                      && onlyAffectsKeys(['status']); // read-receipt updates only
        allow delete: if false;
      }
    }

    // ============ ADMIN-ONLY CATCH-ALL ============
    // Anything not explicitly matched above defaults to fully denied (Firestore's default-deny posture) —
    // no wildcard allow rule exists anywhere in this file, intentionally.
  }
}
```

**Key security patterns used throughout, worth internalizing:**

1. **`onlyAffectsKeys()`** is doing the heaviest lifting in this file. Without it, a rule like `allow update: if isShopOwner(shopId)` would let a vendor rewrite `avgRating` to `5.0` directly, bypassing the Cloud Function aggregation from Phase 4.1 entirely. Every update rule in this file enumerates the *exact* fields a given role/state is allowed to touch.
2. **`allow create: if false` on orders** is deliberate — it forces all order creation through the trusted server-side `placeOrder` Cloud Function (which runs with Admin SDK privileges and is not subject to these rules), guaranteeing price/stock validation can never be bypassed by a modified client calling Firestore directly.
3. **State-machine-shaped rules on orders** — each `allow update` block checks both `resource.data.status` (the *current* state) and `request.resource.data.status` (the *proposed next* state), so a driver can never jump an order straight from `accepted` to `delivered`, skipping `in_transit`.
4. **Reviews require a real, delivered order** (`relatedOrderId` validation against `/orders`) — this single rule is your entire anti-fake-review defense; without it, anyone could post unlimited 5-star (or 1-star competitor-sabotage) reviews with no purchase history.

### 6.2 `storage.rules`

```javascript
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {

    function isSignedIn() {
      return request.auth != null;
    }

    function isValidImage() {
      return request.resource.contentType.matches('image/.*')
             && request.resource.size < 5 * 1024 * 1024; // 5MB hard cap per file
    }

    // --- User profile photos: /profile_images/{uid}/avatar.jpg ---
    match /profile_images/{userId}/{fileName} {
      allow read: if true;
      allow write: if isSignedIn() && request.auth.uid == userId && isValidImage();
      allow delete: if isSignedIn() && request.auth.uid == userId;
    }

    // --- Shop logos & covers: /shops/{shopId}/branding/{fileName} ---
    match /shops/{shopId}/branding/{fileName} {
      allow read: if true;
      allow write: if isSignedIn()
                   && firestore.get(/databases/(default)/documents/shops/$(shopId)).data.ownerId == request.auth.uid
                   && isValidImage();
      allow delete: if isSignedIn()
                   && firestore.get(/databases/(default)/documents/shops/$(shopId)).data.ownerId == request.auth.uid;
    }

    // --- Product images: /shops/{shopId}/products/{productId}/{fileName} ---
    match /shops/{shopId}/products/{productId}/{fileName} {
      allow read: if true;
      allow write: if isSignedIn()
                   && firestore.get(/databases/(default)/documents/shops/$(shopId)).data.ownerId == request.auth.uid
                   && isValidImage();
      allow delete: if isSignedIn()
                   && firestore.get(/databases/(default)/documents/shops/$(shopId)).data.ownerId == request.auth.uid;
    }

    // --- Craftsman portfolio images: /craftsmen/{craftsmanId}/portfolio/{fileName} ---
    match /craftsmen/{craftsmanId}/portfolio/{fileName} {
      allow read: if true;
      allow write: if isSignedIn()
                   && firestore.get(/databases/(default)/documents/craftsmen/$(craftsmanId)).data.userId == request.auth.uid
                   && isValidImage();
      allow delete: if isSignedIn()
                   && firestore.get(/databases/(default)/documents/craftsmen/$(craftsmanId)).data.userId == request.auth.uid;
    }

    // --- Chat image attachments: /chats/{threadId}/{fileName} ---
    match /chats/{threadId}/{fileName} {
      allow read: if isSignedIn()
                  && request.auth.uid in firestore.get(/databases/(default)/documents/chats/$(threadId)).data.participantIds;
      allow write: if isSignedIn()
                   && request.auth.uid in firestore.get(/databases/(default)/documents/chats/$(threadId)).data.participantIds
                   && isValidImage();
      allow delete: if false; // chat attachments are immutable once sent
    }

    // Default deny — no path outside the above is writable or readable
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

**Note on `firestore.get()` inside Storage rules:** Storage Security Rules can cross-reference Firestore (as shown above, verifying shop/craftsman ownership before allowing an image upload) — this is a relatively underused but important capability; without it you'd have no way to verify "is this really the shop owner" from within Storage rules alone, since Storage has no concept of your app's `ownerId` field on its own.

**Testing recommendation before deploying either ruleset:** use the **Firebase Local Emulator Suite** (`firebase emulators:start`) with the `@firebase/rules-unit-testing` package to write automated rule tests (e.g., "vendor B cannot update vendor A's product," "customer cannot read another customer's order") — given your constrained local dev environment, this is best run inside GitHub Codespaces/Actions rather than locally, covered in Phase 8.

---

*(Continued in Phase 7 — UI/UX & Performance Optimization)*
## PHASE 7 — UI/UX & PERFORMANCE OPTIMIZATION

### 7.1 Accessibility Guidelines for Elderly / Non-Tech-Savvy Villagers

This audience profile changes default Material Design assumptions meaningfully. Treat the following as **hard constraints**, not nice-to-haves:

**Touch targets and typography:**
- Minimum tap target: **56×56dp**, not Material's default 48×48dp. Primary action buttons (place order, accept order, call) should be closer to 64dp tall.
- Base font size: **18sp minimum** for body text (vs Material default 14-16sp), with a user-adjustable text-scale setting exposed in Settings (`MediaQuery.textScalerOf` respected everywhere, never hardcoded `fontSize` that ignores system/in-app scaling).
- Avoid font weights below `w400` — thin/light weights are genuinely hard to read for users with age-related vision changes, especially in Arabic script at small sizes where diacritics and letter-joining matter more.
- High contrast by default: text-to-background contrast ratio ≥ 7:1 (exceeds even WCAG AAA's 4.5:1), not just "looks fine on a new OLED screen in a bright office" — test on an actual low-end LCD screen in direct sunlight, which is a real rural usage condition.

**Navigation simplicity:**
- **Maximum 4 items in the bottom navigation bar**, each with a label (never icon-only) — "الرئيسية / طلباتي / السلة / حسابي" for villagers. Icon-only nav relies on learned iconography conventions this audience hasn't necessarily internalized.
- **No swipe gestures as the only way to perform an action.** Every swipeable action (e.g., dismiss a cart item) needs a visible button fallback. Discoverability of gestures is poor for first-time smartphone users.
- **Avoid nested modal sheets / multi-step wizards beyond 3 steps.** Checkout should be: Cart review → Confirm address → Confirm order. Not a 6-screen wizard.
- **Persistent, obvious "back" affordance** on every screen — don't rely solely on the OS back gesture, since many budget Android phones in this context still use 3-button nav, and behavior must be consistent either way. Include an explicit `AppBar` leading back arrow always.

**Language and copy:**
- Use **Egyptian colloquial Arabic (العامية المصرية)** for buttons and instructions, not Modern Standard Arabic (الفصحى) — "احجز دلوقتي" reads naturally; "احجز الآن" reads like a government form. Reserve MSA for formal/legal text (terms of service).
- Avoid English loanwords/Latin script entirely in primary UI text where an Arabic equivalent exists and is commonly used (e.g., "السلة" not "الكارت", but "أوردر" is acceptable since it's genuinely more colloquially common than "طلب" in spoken Egyptian Arabic — use judgment per word, test with actual target users).
- Error messages must be actionable in plain language: not *"حدث خطأ (Error 400)"* but *"تأكد من اتصالك بالإنترنت وحاول مرة أخرى"*.

**Trust and confirmation patterns:**
- Any **destructive or financial action** (cancel order, confirm payment) requires an explicit confirmation dialog with the consequence spelled out in words, not just "هل أنت متأكد؟" — e.g., *"هل تريد إلغاء الطلب؟ لن تتمكن من التراجع عن هذا"*.
- Show **large, unmistakable order status** (a full-width colored banner: "تم القبول ✓" in green, "في الطريق 🚚" in blue) rather than a small text label — status should be readable from arm's length at a glance.
- Phone number / call-vendor buttons should be prominent — **a "اتصل بالتاجر" call button is often more trusted and used than chat** for this demographic; don't bury it in a sub-menu.

**Voice/visual redundancy where feasible:** consider category icons paired with text everywhere (not text-only category chips) — recognition beats recall for users less comfortable reading quickly.

### 7.2 Flutter Performance: Heavy Image Grids

**Product grid (`GridView.builder`, never `GridView.count` with a pre-built list):**

```dart
class ProductGrid extends ConsumerWidget {
  final String shopId;
  const ProductGrid({super.key, required this.shopId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(paginatedProductsProvider(shopId));

    return productsAsync.when(
      loading: () => const ProductGridSkeleton(), // shimmer skeleton, never a centered spinner for grid content
      error: (e, _) => ErrorView(onRetry: () => ref.invalidate(paginatedProductsProvider(shopId))),
      data: (state) => GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: state.products.length + (state.hasMore ? 1 : 0),
        // CRITICAL: itemExtent/cacheExtent kept modest — large cacheExtent pre-renders
        // many offscreen image widgets, spiking memory on low-RAM devices.
        cacheExtent: 400,
        itemBuilder: (context, index) {
          if (index >= state.products.length) {
            // Trigger next page fetch when the loading sentinel scrolls into view
            ref.read(paginatedProductsProvider(shopId).notifier).fetchNextPage();
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          return ProductCard(product: state.products[index]);
        },
      ),
    );
  }
}
```

**Why `GridView.builder` is mandatory, not optional:** it only builds/lays out widgets currently visible (plus `cacheExtent`), versus eagerly constructing every item upfront. For a shop catalog that can run into hundreds of products, this is the difference between smooth scrolling and a multi-second jank/OOM crash on a budget device with 2GB RAM — which is the realistic device profile for this user base.

**`ProductCard` image sizing — always decode at display size, never full resolution:**
```dart
class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: AppCachedImage(
              imageUrl: product.imageUrls.firstOrNull,
              // memCacheWidth inside AppCachedImage (Phase 5.2) ensures decode happens
              // at ~2x display size, not the original upload resolution — this is the
              // single biggest lever against scroll jank in image-heavy grids.
            ),
          ),
          // ... name, price
        ],
      ),
    );
  }
}
```

**Additional grid performance levers:**
- `const` constructors everywhere possible on static sub-widgets (price label styles, padding wrappers) — reduces rebuild cost on every scroll frame.
- Avoid `Opacity` widgets in list/grid items for show/hide effects (forces an offscreen compositing layer); prefer `Visibility` with `maintainState: true` or simply conditional rendering.
- Wrap the whole grid screen in `RepaintBoundary` if it sits beneath an animated app bar or other frequently-repainting sibling, to isolate repaints.

### 7.3 Pagination Using Firestore Cursors

```dart
// presentation/providers/paginated_products_provider.dart
class PaginatedProductsState {
  final List<Product> products;
  final bool hasMore;
  final bool isLoadingMore;
  final DocumentSnapshot? lastDoc;

  const PaginatedProductsState({
    this.products = const [],
    this.hasMore = true,
    this.isLoadingMore = false,
    this.lastDoc,
  });

  PaginatedProductsState copyWith({...}) { /* standard copyWith */ }
}

@riverpod
class PaginatedProducts extends _$PaginatedProducts {
  static const _pageSize = 20;

  @override
  Future<PaginatedProductsState> build(String shopId) async {
    return _fetchPage(shopId, startAfter: null);
  }

  Future<void> fetchNextPage() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    final nextPage = await _fetchPage(shopId, startAfter: current.lastDoc);

    state = AsyncData(nextPage.copyWith(
      products: [...current.products, ...nextPage.products],
    ));
  }

  Future<PaginatedProductsState> _fetchPage(String shopId, {DocumentSnapshot? startAfter}) async {
    final firestore = ref.read(firestoreProvider);
    Query query = firestore
        .collection('shops/$shopId/products')
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(_pageSize);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snap = await query.get();
    final products = snap.docs.map((d) => ProductModel.fromFirestore(d).toEntity()).toList();

    return PaginatedProductsState(
      products: products,
      hasMore: snap.docs.length == _pageSize, // a short page means we've hit the end
      isLoadingMore: false,
      lastDoc: snap.docs.isNotEmpty ? snap.docs.last : null,
    );
  }
}
```

**Why `startAfterDocument` cursors, not `offset()`:** Firestore's `.offset(n)` (rarely exposed in the Dart SDK anyway) still *reads and discards* the skipped documents server-side, so you're billed for them — cost scales linearly with how deep into the list the user has scrolled. Document-snapshot cursors (`startAfterDocument`) jump directly to the right position with no wasted reads regardless of page depth, which matters both for your Firestore bill and for response latency on a slow rural connection.

---

*(Continued in Phase 8 — Cloud Development & CI/CD Pipeline)*
## PHASE 8 — CLOUD DEVELOPMENT & CI/CD PIPELINE (LOW-SPEC HARDWARE)

### 8.1 Recommended Cloud Development Environment

Since your local machine cannot run Android Studio or the Flutter SDK, **GitHub Codespaces** is the recommended environment over Google Project IDX or VS Code for Web alone, for these specific reasons:

| Factor | GitHub Codespaces | Project IDX |
|---|---|---|
| Integration with this pipeline | Native — same GitHub repo, same Secrets, zero context-switching | Separate Google ecosystem, requires re-linking |
| Terminal access for `flutterfire configure`, `firebase deploy` | Full Linux terminal, unrestricted | Full Linux terminal, unrestricted |
| Persistence of installed SDKs across sessions | Yes, via prebuilt devcontainer + cached volume | Yes |
| Free tier | 60 core-hours/month free (personal accounts) | Free during current preview |
| Maturity/stability | Production-grade, GA since 2022 | Still labeled preview/evolving |

**Setup — `.devcontainer/devcontainer.json` (commit this to the repo root):**
```json
{
  "name": "Village Market Flutter Dev",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu-22.04",
  "features": {
    "ghcr.io/devcontainers/features/java:1": { "version": "17" }
  },
  "onCreateCommand": "bash .devcontainer/setup.sh",
  "customizations": {
    "vscode": {
      "extensions": [
        "Dart-Code.flutter",
        "Dart-Code.dart-code",
        "toba.vsfire"
      ]
    }
  },
  "forwardPorts": [],
  "hostRequirements": {
    "cpus": 4,
    "memory": "8gb"
  }
}
```

**`.devcontainer/setup.sh`:**
```bash
#!/usr/bin/env bash
set -e

# Install Flutter SDK (stable channel) into the Codespace
git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$HOME/flutter"
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> "$HOME/.bashrc"
export PATH="$PATH:$HOME/flutter/bin"

flutter precache
flutter config --no-analytics
flutter doctor

# Firebase CLI for `firebase deploy`, `flutterfire configure`
npm install -g firebase-tools

echo "✅ Codespace ready. Run 'flutter pub get' in the project root to begin."
```

With this committed, **every time you open the repo in a Codespace, you get a fully working `flutter` command, hot-reload via the VS Code Flutter extension (in a browser tab), and `firebase` CLI** — all running on GitHub's cloud compute, not your machine. You can run `flutter run -d web-server` inside the Codespace and use the forwarded port to interact with a live debug build directly in your browser for fast iteration, reserving the GitHub Actions pipeline below specifically for producing installable release APKs.

### 8.2 Production GitHub Actions Workflow

`.github/workflows/build-apk.yml`:

```yaml
name: Build Release APK

on:
  push:
    branches:
      - main
  workflow_dispatch:        # allows manual trigger from the Actions tab

jobs:
  build:
    name: Build & Sign Release APK
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up Java (Android Gradle requirement)
        uses: actions/setup-java@v4
        with:
          distribution: 'zulu'
          java-version: '17'

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.27.1'   # pin explicitly — never 'stable', for reproducible builds
          channel: 'stable'
          cache: true

      - name: Inject google-services.json
        env:
          GOOGLE_SERVICES_JSON: ${{ secrets.GOOGLE_SERVICES_JSON }}
        run: echo "$GOOGLE_SERVICES_JSON" | base64 -d > android/app/google-services.json

      - name: Inject Android Keystore
        env:
          ANDROID_KEYSTORE_BASE64: ${{ secrets.ANDROID_KEYSTORE_BASE64 }}
        run: echo "$ANDROID_KEYSTORE_BASE64" | base64 -d > android/app/upload-keystore.jks

      - name: Inject key.properties
        env:
          KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
          KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
          KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
        run: |
          cat <<EOF > android/key.properties
          storePassword=$KEYSTORE_PASSWORD
          keyPassword=$KEY_PASSWORD
          keyAlias=$KEY_ALIAS
          storeFile=upload-keystore.jks
          EOF

      - name: Install dependencies
        run: flutter pub get

      - name: Run code generation (Riverpod, freezed, json_serializable)
        run: dart run build_runner build --delete-conflicting-outputs

      - name: Run static analysis
        run: flutter analyze --no-fatal-infos

      - name: Run unit tests
        run: flutter test

      - name: Build Release APK
        run: flutter build apk --release --split-per-abi

      - name: Upload APK artifact
        uses: actions/upload-artifact@v4
        with:
          name: village-market-release-apk
          path: build/app/outputs/flutter-apk/*.apk
          retention-days: 30

      - name: Clean up sensitive files
        if: always()
        run: |
          rm -f android/app/google-services.json
          rm -f android/app/upload-keystore.jks
          rm -f android/key.properties
```

**Workflow walkthrough — what each stage does and why:**

1. **`subosito/flutter-action@v2`** is the standard community action for installing a pinned Flutter SDK version on the runner — pinning the version (not `channel: stable` alone) is what gives you **reproducible builds**: without a pin, a `stable` channel update between two pushes could silently change your build output or break compilation.
2. **Secret injection steps** decode Base64-encoded secrets back into the actual files Gradle expects on disk (`google-services.json`, the `.jks` keystore) — full mechanics in 8.3 below.
3. **`build_runner build`** is required because this architecture uses `riverpod_generator` (Phase 1.3) — generated `.g.dart` files are intentionally **not** committed to the repo (add `*.g.dart` to `.gitignore`... actually, for CI reliability, many teams *do* commit generated files to avoid this step entirely; this workflow assumes the cleaner non-committed approach, regenerating fresh on every build).
4. **`flutter analyze` and `flutter test` run before the build**, not after — this fails the pipeline fast on a broken commit rather than wasting ~5-8 minutes building an APK from code that doesn't even pass static analysis.
5. **`--split-per-abi`** produces separate smaller APKs per CPU architecture (`armeabi-v7a`, `arm64-v8a`, `x86_64`) instead of one bloated universal APK — directly relevant for your rural users, who will have **older/budget Android devices** (almost certainly `armeabi-v7a` or `arm64-v8a`, never `x86_64`) and limited mobile data to download the app in the first place. Smaller install size matters.
6. **The cleanup step runs `if: always()`** — even if the build fails partway through, the decoded secrets are wiped from the runner's disk before the job ends. (Note: GitHub Actions runners are ephemeral VMs destroyed after every job regardless, so this is defense-in-depth rather than strictly necessary — but it's correct practice and costs nothing.)

### 8.3 Securely Managing `google-services.json` and the Android Keystore

**The core principle:** GitHub Secrets store *plain strings*, but both files you need are *binary or structured files*. The standard, correct pattern is: **Base64-encode the file locally once, paste the resulting string as a GitHub Secret, then decode it back to a file inside the workflow** (exactly what the `echo "$SECRET" | base64 -d > path` steps above do).

**Step-by-step setup — do this once, from your Codespace terminal (since you have no local machine to do it from):**

**1. Generate the Android upload keystore** (if you don't already have one):
```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```
This prompts interactively for a store password, key password, and your name/organization details for the certificate. **Write down the store password and key password somewhere safe (a password manager) — losing this keystore or its password permanently breaks your ability to publish app updates to the same Play Store listing**, since Google requires update signatures to match the original.

**2. Base64-encode the keystore:**
```bash
base64 -w 0 upload-keystore.jks > keystore_base64.txt
cat keystore_base64.txt
```
Copy the entire single-line output.

**3. Base64-encode `google-services.json`** (downloaded from Firebase Console → Project Settings → Your Android App):
```bash
base64 -w 0 google-services.json > google_services_base64.txt
cat google_services_base64.txt
```
Copy this output too.

**4. Add the secrets in GitHub:** Navigate to your repository → **Settings → Secrets and variables → Actions → New repository secret**, and create exactly these four:

| Secret name | Value |
|---|---|
| `GOOGLE_SERVICES_JSON` | The full Base64 string from step 3 |
| `ANDROID_KEYSTORE_BASE64` | The full Base64 string from step 2 |
| `KEYSTORE_PASSWORD` | The store password you set in step 1 |
| `KEY_ALIAS` | `upload` (or whatever alias you chose) |
| `KEY_PASSWORD` | The key password you set in step 1 |

**5. Immediately delete the local plaintext copies** from your Codespace (`rm upload-keystore.jks google-services.json keystore_base64.txt google_services_base64.txt`) — Codespaces filesystems are not meant as permanent secret storage, and you don't want these floating around in shell history or a stray `git add .`.

**6. Confirm `.gitignore` excludes these patterns** (add if missing) so a future `git add .` can never accidentally commit them:
```gitignore
# Sensitive files — NEVER commit
android/app/google-services.json
android/app/upload-keystore.jks
android/key.properties
**/*.jks
**/*.keystore
```

**7. Configure `android/app/build.gradle` to read `key.properties`** (this file is generated fresh on every CI run by the workflow — it never exists in the repo itself):
```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config ...

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

**Why this is genuinely secure:** the Base64-encoded secret values are encrypted at rest by GitHub, only decrypted into the ephemeral runner's memory/disk during a workflow run, and **never appear in build logs** (GitHub Actions automatically redacts registered secret values from log output, even if a step's command would otherwise print them). The plaintext `google-services.json` and `.jks` file only exist transiently on a disposable cloud VM that's destroyed the moment the job finishes — at no point does either file touch your public GitHub repository's actual tracked file tree.

### 8.4 Downloading the Built APK

Once the workflow runs (automatically on every push to `main`, or manually via **Actions tab → Build Release APK → Run workflow**):

1. Go to your repository's **Actions** tab.
2. Click the most recent (or in-progress) **Build Release APK** run.
3. Scroll to the **Artifacts** section at the bottom of the run summary page.
4. Click **village-market-release-apk** to download a `.zip` containing the split APKs (`app-armeabi-v7a-release.apk`, `app-arm64-v8a-release.apk`, etc.).
5. Transfer the appropriate APK to a test Android device (via USB, a cloud drive link, or directly installing the `arm64-v8a` variant, which covers the vast majority of Android devices from the last ~6 years) to sideload and test.

Artifacts are retained for **30 days** (set via `retention-days: 30` in the workflow) before automatic deletion — adjust this value up to GitHub's 90-day maximum on the free tier if you want longer-lived build history, or push a new commit to regenerate before expiry.

**Recommended next step once this is stable:** once you're comfortable with this pipeline, extend it with a second job — `deploy-functions` — that runs `firebase deploy --only functions,firestore:rules,firestore:indexes,storage:rules` on pushes to `main`, using a `FIREBASE_TOKEN` or (preferably) a **Workload Identity Federation** service account secret, so your Cloud Functions and security rules deploy automatically alongside every app release rather than requiring a manual `firebase deploy` from a terminal.

---

## CLOSING NOTES

This blueprint is intentionally exhaustive — you do not need to implement all 4 roles, every Cloud Function, and every security rule on day one. A reasonable build order given everything above:

1. **Phase 1 scaffolding** (folder structure, Riverpod/GoRouter wiring, basic theme) + **Phase 8 CI pipeline** working end-to-end on an empty app first — confirm you can push a commit and download a working (if blank) signed APK before writing any real features.
2. **Auth + Users** (Phase 3.1) + matching Security Rules (Phase 6 `/users`).
3. **Shops + Products browsing** (read-only villager side) + Phase 6 rules for `/shops`, `/products`.
4. **Cart + Checkout + Orders** (Phase 3.2, Phase 4.2/4.3 Cloud Functions, Phase 6 `/orders` rules) — this is your core transaction loop; everything else is secondary to getting this right.
5. **Offline-first hardening** (Phase 5) — apply once the core loop works, not before, so you're hardening real behavior rather than guessing.
6. **Craftsmen, chat, reviews, driver role** — layer on roughly in that order of product priority.
7. **Admin panel** — can reasonably be deferred to last, or built as a minimal Flutter Web target sharing the same `domain`/`data` layers.

كل جزء في المستند ده مترابط مع الباقي — لو عايز نحفر أعمق في أي Phase بعينها (مثلاً نكتب الـ `freezed` models كاملة، أو نبني الـ `vendor_dashboard` screens بالتفصيل) قولي وهنكمل من هنا.
