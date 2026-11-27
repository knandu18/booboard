pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.3.1" apply false
    id("org.jetbrains.kotlin.android") version "2.4.20" apply false
}

include(":app")

// Play on-demand asset packs (docs/release/asset-packs.md). Only the play flavour's bundle uses them.
include(":pack_dict_zh", ":pack_dict_ja", ":pack_translate_en_es")
project(":pack_dict_zh").projectDir = file("asset_packs/pack_dict_zh")
project(":pack_dict_ja").projectDir = file("asset_packs/pack_dict_ja")
project(":pack_translate_en_es").projectDir = file("asset_packs/pack_translate_en_es")
