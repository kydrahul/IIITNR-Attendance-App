# Flutter-specific ProGuard rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Mobile Scanner (QR)
-keep class com.google.mlkit.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Local Auth / Biometric
-keep class androidx.biometric.** { *; }

# Keep enums
-keepclassmembers enum * { *; }

# Keep Parcelables
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}

# Suppress warnings for Play Core classes (not used since we're not on Play Store)
# Flutter engine references these but they are not required for APK distribution
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
