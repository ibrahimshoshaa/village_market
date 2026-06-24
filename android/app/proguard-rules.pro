# Keep Firebase / Firestore model classes from being stripped, since they're
# reflectively deserialized. Expand this list as you add fromFirestore/
# toMap model classes under lib/features/*/data/models/.

-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Riverpod / generated code is pure Dart and unaffected by ProGuard, but
# the Flutter engine + plugin registrant classes must be kept:
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
# Play Core split install classes (not used, but referenced by Flutter embedding)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }