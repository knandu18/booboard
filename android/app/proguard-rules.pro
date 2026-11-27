# BooBoard release shrinker rules. The Flutter Gradle plugin adds the Flutter engine's own keep rules.

# Privacy: no debug/verbose/info logging in shipped builds. R8 removes the calls and their
# argument construction, so nothing typed can ever reach logcat through these levels.
# (Warnings and errors stay; BooBoard only logs events, sizes and timings, never text.)
-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int d(...);
    public static int i(...);
}

# Pigeon-generated bridge: message classes are built reflection-free, but keep them readable in
# stack traces and safe from over-eager optimisation of the channel codec.
-keep class app.booboard.keyboard.bridge.** { *; }

# The system instantiates these by name from the manifest.
-keep class app.booboard.keyboard.ime.BooBoardImeService { *; }
-keep class app.booboard.keyboard.SettingsActivity { *; }
-keep class app.booboard.keyboard.BooBoardApplication { *; }

# Wave 3: native inference. JNI looks these classes, fields and methods up by name.
-keep class com.k2fsa.sherpa.onnx.** { *; }
-keep class ai.onnxruntime.** { *; }

# Images: JNI looks the bridge up by name, and the native engine calls SdProgressListener.onProgress by name.
-keep class app.booboard.keyboard.images.SdNative { *; }
-keep interface app.booboard.keyboard.images.SdProgressListener { *; }
-keepclassmembers class * implements app.booboard.keyboard.images.SdProgressListener { public void onProgress(int, int, int); }

# Play flavour: WorkManager (pulled in by Play Asset Delivery) creates its Room database by reflection
# (WorkDatabase_Impl). Without these rules R8 strips the constructor and the app crashes at start-up
# ("Failed to create an instance of class androidx.work.impl.WorkDatabase"). Harmless in the foss build.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { <init>(); }
