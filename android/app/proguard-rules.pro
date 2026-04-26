# Flutter engine & embedding
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

-dontwarn io.flutter.embedding.**

# Firebase – keep reflection targets used by the SDKs
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Firebase Auth
-keep class com.google.firebase.auth.** { *; }

# Firebase App Check / Play Integrity
-keep class com.google.firebase.appcheck.** { *; }
-keep class com.google.android.play.core.integrity.** { *; }
-dontwarn com.google.android.play.core.**

# Google Play Billing (in_app_purchase)
-keep class com.android.billingclient.** { *; }
-dontwarn com.android.billingclient.**

# flutter_secure_storage (uses Android Keystore via JCA)
-keep class androidx.security.crypto.** { *; }
-dontwarn androidx.security.crypto.**

# Prevent stripping of classes accessed via reflection in release
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
