plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.moneyfy"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.moneyfy"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val releaseKeystore = System.getenv("MONEYFY_ANDROID_KEYSTORE")
    signingConfigs {
        if (releaseKeystore != null) {
            create("distribution") {
                storeFile = file(releaseKeystore)
                storePassword = System.getenv("MONEYFY_ANDROID_PASSWORD")
                keyAlias = "moneyfy"
                keyPassword = storePassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(
                if (releaseKeystore == null) "debug" else "distribution"
            )
        }
    }
}

flutter {
    source = "../.."
}
