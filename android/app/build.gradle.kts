plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// 1. Carichiamo le chiavi dal file esterno per sicurezza
val keystoreProperties = java.util.Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.magihair.magi_hair_off"
    compileSdk = 35 // FORZATO A 35 PER GOOGLE PLAY
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.magihair.magi_hair_off"

        minSdk = flutter.minSdkVersion
        targetSdk = 35 // FORZATO A 35 (Richiesto da Google Play nel 2025)

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // 2. Definiamo la configurazione di firma per la Release
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            // 3. ORA USA LA CHIAVE DI RILASCIO, NON QUELLA DI DEBUG
            signingConfig = signingConfigs.getByName("release")

            // Consigliato per lo store: riduce la dimensione e offusca il codice
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

// ==========================================================
// FIX PER ERRORE DIPENDENZE ANDROID
// ==========================================================
configurations.all {
    resolutionStrategy {
        force("androidx.browser:browser:1.8.0")
        force("androidx.core:core-ktx:1.15.0")
        force("androidx.core:core:1.15.0")
    }
}