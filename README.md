# سوق القرية (Village Market) — Project Scaffold

This repository is the **Phase 1 scaffold** described in `ARCHITECTURE.md` (the
full engineering blueprint — read it first if you haven't). Folder structure,
Riverpod/GoRouter wiring, theme, Firebase Security Rules, Cloud Functions, and
the CI/CD pipeline are all pre-built. **You cannot run `flutter` commands on
your local machine** (per the original constraint), so the very first real
step happens inside a cloud environment — follow this exactly, in order.

---

## ⚠️ What's already done vs. what you must do

**Already done (in this repo):**
- Full `lib/` feature-first folder structure (Phase 1.2), with working
  placeholder screens so the app **compiles and runs** immediately.
- Riverpod + GoRouter wired end-to-end with role-based route guards (Phase 1.4).
- `firestore.rules`, `storage.rules`, `firestore.indexes.json` — copy-exact
  from Phase 6/2.8 of the blueprint, ready to deploy.
- All 7 Cloud Functions (Phase 4) written in TypeScript, ready to deploy.
- `.github/workflows/build-apk.yml` — the full CI pipeline (Phase 8.2).
- `.devcontainer/` — GitHub Codespaces auto-installs Flutter on container start.

**You must still do (cannot be done without the Flutter SDK / a real Firebase project):**
1. Open this repo in a GitHub Codespace (installs Flutter automatically).
2. Run `flutter create .` in the project root — this generates the
   `android/`, `ios/`, `web/`, `linux/`, `windows/`, `macos/` platform folders
   that Flutter needs but that can't be hand-written sensibly. **It will NOT
   overwrite `lib/`, `pubspec.yaml`, or any file already in this repo** unless
   you pass `--overwrite` (don't).
3. **Merge** (don't blindly overwrite) `android/app/build.gradle.kts` and
   `android/build.gradle.kts` — this repo already contains hand-written
   versions with the Firebase + signing config from Phase 8.3 pre-added. If
   `flutter create .` generates its own versions, diff them against what's
   here and merge the Firebase/signing blocks in.
4. Create a real Firebase project at https://console.firebase.google.com,
   then run `flutterfire configure` to generate the real `firebase_options.dart`
   (currently a placeholder with `REPLACE_ME` values) and pull down
   `google-services.json` for local dev.
5. Run `flutter pub get`, then `dart run build_runner build --delete-conflicting-outputs`
   to generate the `.g.dart` files for the `@riverpod` providers already
   written in this scaffold (`app_router.dart`, `firebase_service.dart`).
6. Follow Phase 8.3 of `ARCHITECTURE.md` exactly to set up the 5 GitHub
   Secrets (`GOOGLE_SERVICES_JSON`, `ANDROID_KEYSTORE_BASE64`,
   `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`) before your first push —
   the workflow will fail without them.

---

## Step-by-step bootstrap (run inside your Codespace terminal)

```bash
# 1. Confirm Flutter is installed (the devcontainer setup.sh does this on container creation)
flutter doctor

# 2. Generate the missing platform folders (android/, ios/, etc.)
#    This is safe — it will not touch lib/ or pubspec.yaml.
flutter create . --org com.villagemarket --project-name village_market

# 3. Install Firebase CLI + FlutterFire CLI (devcontainer setup.sh already installs firebase-tools)
dart pub global activate flutterfire_cli

# 4. Log into Firebase (opens a browser — Codespaces forwards this correctly)
firebase login

# 5. Create your Firebase project first at console.firebase.google.com, THEN:
flutterfire configure --project=<your-firebase-project-id>
#    Select Android + iOS when prompted. This OVERWRITES lib/firebase_options.dart
#    with real values and drops google-services.json into android/app/.

# 6. Install Dart/Flutter dependencies
flutter pub get

# 7. Generate Riverpod provider code (.g.dart files)
dart run build_runner build --delete-conflicting-outputs

# 8. Confirm it builds
flutter analyze
flutter run -d web-server --web-port=8080
#    Open the forwarded port 8080 in your browser to see the running app.

# 9. Install Cloud Functions dependencies
cd functions && npm install && cd ..

# 10. Deploy Firestore/Storage rules + indexes + functions (after firebase login above)
firebase deploy --only firestore:rules,firestore:indexes,storage:rules,functions
```

---

## Recommended build order

See the **Closing Notes** section at the end of `ARCHITECTURE.md` for the
full reasoning. Short version:

1. ✅ This scaffold + a green CI run producing a downloadable (blank) signed APK.
2. Auth (Phase 3.1) — replace the stub `authStateProvider` with real
   `FirebaseAuth.instance.authStateChanges()` wiring.
3. Shops + Products browsing (read-only).
4. Cart + Checkout + Orders — the core transaction loop.
5. Offline-first hardening (Phase 5).
6. Craftsmen, chat, reviews, driver role.
7. Admin panel (can be deferred to last).

---

## File map — where the blueprint content lives in this repo

| Blueprint section | File(s) in this repo |
|---|---|
| Phase 1.2 folder structure | `lib/` (full tree, with `.gitkeep` in still-empty dirs) |
| Phase 1.3 Riverpod conventions | `lib/core/services/firebase_service.dart`, `lib/app/router/app_router.dart` |
| Phase 1.4 routing + guards | `lib/app/router/*.dart`, `lib/app/shells/*.dart` |
| Phase 1.5 localization | `l10n.yaml`, `lib/l10n/app_ar.arb`, `lib/l10n/app_en.arb` |
| Phase 2 schema | _(reference only — see `ARCHITECTURE.md`; no schema files needed, Firestore is schemaless)_ |
| Phase 2.8 indexes | `firestore.indexes.json` |
| Phase 3 workflows | `lib/features/auth/`, `lib/features/cart/`, `lib/features/geolocation/` *(stubs — implement per blueprint)* |
| Phase 4 Cloud Functions | `functions/src/**/*.ts` (all 7 functions, fully written) |
| Phase 5 offline-first | `lib/core/network/`, `lib/core/widgets/` *(stubs — implement per blueprint)* |
| Phase 6 security rules | `firestore.rules`, `storage.rules` |
| Phase 7 UI/UX | `lib/app/theme/*.dart` (elder-friendly sizing already applied) |
| Phase 8 CI/CD | `.github/workflows/build-apk.yml`, `.devcontainer/` |
