import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val mapsSecrets = Properties().apply {
    val secretsFile = rootProject.file("maps-secrets.properties")
    if (secretsFile.isFile) {
        secretsFile.inputStream().use(::load)
    }
}
val googleMapsAndroidApiKey = mapsSecrets.getProperty(
    "GOOGLE_MAPS_ANDROID_SDK_API_KEY",
    "",
)

val signingProperties = Properties().apply {
    val propertiesFile = rootProject.file("key.properties")
    if (propertiesFile.isFile) {
        propertiesFile.inputStream().use(::load)
    }
}
fun signingValue(propertyName: String, environmentName: String): String? =
    signingProperties.getProperty(propertyName)
        ?: System.getenv(environmentName)

val releaseStoreFile = signingValue(
    "storeFile",
    "CHILLGO_UPLOAD_KEYSTORE",
)
val releaseStorePassword = signingValue(
    "storePassword",
    "CHILLGO_UPLOAD_STORE_PASSWORD",
)
val releaseKeyAlias = signingValue(
    "keyAlias",
    "CHILLGO_UPLOAD_KEY_ALIAS",
)
val releaseKeyPassword = signingValue(
    "keyPassword",
    "CHILLGO_UPLOAD_KEY_PASSWORD",
)
val hasReleaseSigning = listOf(
    releaseStoreFile,
    releaseStorePassword,
    releaseKeyAlias,
    releaseKeyPassword,
).all { !it.isNullOrBlank() }
val requiresReleaseSigning = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}
if (requiresReleaseSigning && !hasReleaseSigning) {
    throw GradleException(
        "Release signing is required. Configure android/key.properties " +
            "or the CHILLGO_UPLOAD_* environment variables.",
    )
}

android {
    namespace = "com.chillgo.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.chillgo.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["GOOGLE_MAPS_ANDROID_API_KEY"] =
            googleMapsAndroidApiKey
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(releaseStoreFile!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.15.0"))
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-storage")
}

flutter {
    source = "../.."
}
