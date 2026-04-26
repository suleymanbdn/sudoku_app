import java.io.File
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Play Store versionCode must match pubspec "version: x.y.z+CODE" — do not rely on
// android/local.properties (stale if you build only from Android Studio).
fun loadPubspecVersion(projectRoot: File): Pair<Int, String> {
    val pubspec = projectRoot.resolve("pubspec.yaml")
    check(pubspec.isFile) { "pubspec.yaml not found: ${pubspec.absolutePath}" }
    val line = pubspec.readLines().firstOrNull { l ->
        val t = l.trimStart()
        t.startsWith("version:") && !t.startsWith("#")
    } ?: error("No version: line in pubspec.yaml")
    val raw = line.substringAfter("version:").trim().substringBefore("#").trim()
    check("+" in raw) { "pubspec version must be name+code (e.g. 1.0.4+5), got: $raw" }
    val name = raw.substringBefore("+").trim()
    val code = raw.substringAfter("+").trim().toIntOrNull()
        ?: error("Invalid versionCode after '+': $raw")
    return code to name
}

val (pubVersionCode, pubVersionName) =
    loadPubspecVersion(rootProject.projectDir.parentFile)

android {
    namespace = "com.sudokubulmaca.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.sudokubulmaca.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = pubVersionCode
        versionName = pubVersionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")!!
                keyPassword = keystoreProperties.getProperty("keyPassword")!!
                storePassword = keystoreProperties.getProperty("storePassword")!!
                storeFile = file(keystoreProperties.getProperty("storeFile")!!)
            }
        }
    }

    buildTypes {
        release {
            check(keystorePropertiesFile.exists()) {
                "Release build requires key.properties — do not use debug signing for production."
            }
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}
