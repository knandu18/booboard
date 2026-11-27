import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// -----------------------------------------------------------------------------------------------
// Release identity. ONE place for the applicationId.
// Final id (GitHub user knandu18), set 2026-11-27. Once an app is published under it, it must never
// change again. Change it only with tool/release/set_application_id.ps1, which rewrites this
// line and every other place listed in docs/release/RELEASING.md ("applicationId" section).
// The namespace (Kotlin package, R class, JNI names) stays app.booboard.keyboard for good.
// -----------------------------------------------------------------------------------------------
val booboardApplicationId = "io.github.knandu18.booboard"
val booboardNamespace = "app.booboard.keyboard"

// Pinned NDK. Flutter 3.50.0 defaults to the same version; the pin keeps it from moving with the SDK.
// Flutter version: tool/release/flutter-version.txt. Gradle: android/gradle/wrapper (9.5.0).
val booboardNdkVersion = "28.2.13676358"

// The Images engine (third_party/stable-diffusion.cpp) is not shipped yet: it is built only when asked for with
// `-P booboardImages=true` (or ORG_GRADLE_PROJECT_booboardImages=true). Without it the app reports Images as
// unsupported and the keyboard shows the coming-soon panel. Adds about 40 MB per ABI when on.
val booboardImagesEngine = (findProperty("booboardImages") as String?)?.toBoolean() == true

// -----------------------------------------------------------------------------------------------
// Release signing. Read from android/key.properties (git-ignored; keys: storeFile, storePassword,
// keyAlias, keyPassword) or from BOOBOARD_KEYSTORE_PATH, BOOBOARD_KEYSTORE_PASSWORD, BOOBOARD_KEY_ALIAS,
// BOOBOARD_KEY_PASSWORD. storeFile must be an absolute path outside the repository.
// With neither present, release builds fall back to the debug key and print a warning, so
// contributors and CI without secrets can still build. release.yml refuses debug-signed output.
// -----------------------------------------------------------------------------------------------
val signingProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

fun signingSetting(propertyKey: String, envKey: String): String? =
    (signingProperties.getProperty(propertyKey) ?: System.getenv(envKey))?.takeIf { it.isNotBlank() }

val releaseStoreFile = signingSetting("storeFile", "BOOBOARD_KEYSTORE_PATH")
val releaseStorePassword = signingSetting("storePassword", "BOOBOARD_KEYSTORE_PASSWORD")
val releaseKeyAlias = signingSetting("keyAlias", "BOOBOARD_KEY_ALIAS")
val releaseKeyPassword = signingSetting("keyPassword", "BOOBOARD_KEY_PASSWORD")
val hasReleaseSigning =
    listOf(releaseStoreFile, releaseStorePassword, releaseKeyAlias, releaseKeyPassword).all { it != null }

android {
    namespace = booboardNamespace
    compileSdk = flutter.compileSdkVersion
    ndkVersion = booboardNdkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // Two distributions of the same code. Only Gradle and resources differ (src/foss, src/play).
    //   foss: GitHub and F-Droid. The full build, signed-pack import, no Google libraries.
    //   play: Google Play. Same code; large data arrives as Play on-demand asset packs (Wave 5-C).
    // Until the asset-pack modules land, play behaves exactly like foss.
    // Large packs reach the play flavour as on-demand Play asset packs (bundle only; APK builds ignore this).
    assetPacks += listOf(":pack_dict_zh", ":pack_dict_ja", ":pack_translate_en_es")

    flavorDimensions += "distribution"
    productFlavors {
        create("foss") {
            dimension = "distribution"
        }
        create("play") {
            dimension = "distribution"
        }
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                storeFile = file(releaseStoreFile!!)
                storePassword = releaseStorePassword!!
                keyAlias = releaseKeyAlias!!
                keyPassword = releaseKeyPassword!!
            }
        }
    }

    defaultConfig {
        applicationId = booboardApplicationId
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26 // PBKDF2-SHA256, modern Keystore, contentMimeTypes
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        // Set the version with tool/release/bump_version.ps1 (it edits the pubspec version line).
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Images engine (stable-diffusion.cpp as libbooboard_images.so, source in third_party/, see
        // third_party/README.md). It is built only for arm64-v8a and x86_64: a 1.7 GB model cannot run on
        // armeabi-v7a, and the app already ships armeabi-v7a libraries for voice (sherpa-onnx) that must stay.
        // That is why this filter is the externalNativeBuild one: ndk.abiFilters would also drop those prebuilt
        // armeabi-v7a libraries from the APK.
        if (booboardImagesEngine) {
            externalNativeBuild {
                cmake {
                    abiFilters += listOf("arm64-v8a", "x86_64")
                }
            }
        }
    }

    if (booboardImagesEngine) {
        externalNativeBuild {
            cmake {
                path = file("src/main/cpp/CMakeLists.txt")
                version = "3.22.1"
            }
        }
    }

    // Vital lint on release builds crashes inside the lint tool (a JavaDoc parser mismatch while
    // scanning ExifDataCopier.java in a dependency; reproduced on the play flavour, AGP 9.3 / Kotlin 2.4).
    // That is a tool bug, not BooBoard code, and it blocks assemble*Release. Release builds skip vital
    // lint; run lint on the debug build instead. Re-enable when the lint tool is fixed.
    lint {
        checkReleaseBuilds = false
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            // R8 also strips android.util.Log.d/v/i (see proguard-rules.pro): no debug logging in shipped builds.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

// Loud warning when a release task runs without release keys. The APK is then debug-signed and must not be published.
gradle.taskGraph.whenReady {
    val releaseRequested = allTasks.any {
        (it.name.startsWith("assemble") || it.name.startsWith("bundle")) && it.name.contains("Release")
    }
    if (releaseRequested && !hasReleaseSigning) {
        logger.warn(
            "WARNING: no release signing configured (android/key.properties or BOOBOARD_KEYSTORE_* variables). " +
                "The release build is signed with the DEBUG key. Do not publish it; see docs/release/RELEASING.md.",
        )
    }
}

dependencies {
    // Play Asset Delivery (play flavour only; Play Core SDK terms, see docs/release/asset-packs.md). It talks to the
    // Play Store app over IPC and adds no network permission; its extra permissions are removed in src/play.
    "playImplementation"("com.google.android.play:asset-delivery:2.3.0")
    "playImplementation"("com.google.android.play:asset-delivery-ktx:2.3.0")

    // Inline autofill chip styling (UiVersions). Pure UI helpers, Apache-2.0, no network code.
    implementation("androidx.autofill:autofill:1.3.0")
    // Pigeon's @async host methods are generated as suspend functions. Already on the classpath
    // through AndroidX (same version); pinned so the generated bindings don't rely on that. Apache-2.0.
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")

    // ONNX Runtime (MIT): the one native inference runtime, shared by voice (sherpa-onnx, Wave 3-D) and
    // translation (Wave 3-T). Pinned to 1.28.0: 1.29+ adds an HTTP telemetry client, a startup provider,
    // INTERNET and ACCESS_NETWORK_STATE. Do not upgrade without checking the AAR manifest and classes.
    // No network code. Nothing else may bundle its own libonnxruntime.so.
    implementation("com.microsoft.onnxruntime:onnxruntime-android:1.28.0")

    testImplementation("junit:junit:4.13.2")
    // Real org.json for JVM tests (Android's stub throws "not mocked").
    testImplementation("org.json:json:20240303")
    testImplementation("com.microsoft.onnxruntime:onnxruntime:1.28.0")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
