# R8 / ProGuard rules for Recallr Flutter application
# Preserves Flutter, Firebase, Google Sign-In, ML Kit, and Record native plugins.

# Flutter Engine
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase Core & Firestore
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keepattributes *Annotation*,InnerClasses,EnclosingMethod,Signature

# Google Play Services & Auth
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Google ML Kit (Text Recognition / OCR)
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Record plugin (audio recorder)
-keep class com.llfbandit.record.** { *; }
-dontwarn com.llfbandit.record.**

# Image Picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# General JNI / Native method preservation
-keepclasseswithmembernames class * {
    native <methods>;
}

-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Google Play Integrity / Core (Firebase App Check)
-keep class com.google.android.play.core.integrity.** { *; }
-dontwarn com.google.android.play.core.integrity.**
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Retain line numbers and source file for Play Console symbolication
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Protobuf & gRPC (Cloud Firestore and Cloud Functions dependencies)
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**
-keep class io.grpc.** { *; }
-dontwarn io.grpc.**
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn kotlinx.coroutines.**
