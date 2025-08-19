import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services") // Add Firebase plugin
    id("dev.flutter.flutter-gradle-plugin")
}


val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.rohitarer00.nexabill"
    compileSdk = 35//flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // Ensure NDK version is set properly
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.rohitarer00.nexabill"
        minSdk = 23 // Update minSdkVersion to match Firebase requirements
        targetSdk = 35//flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            // signingConfig = signingConfigs.getByName("debug")
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false // TEMP disable R8 to see if it builds
        isShrinkResources = false
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
        }
    }
}

// Firebase SDK dependencies
dependencies {
    // Import the Firebase BoM (Bill of Materials)
    implementation(platform("com.google.firebase:firebase-bom:33.10.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.razorpay:checkout:1.6.33")
    implementation("com.guardsquare:proguard-annotations:7.2.2")

    // Add required Firebase services (e.g., Authentication, Firestore, etc.)
    implementation("com.google.firebase:firebase-auth-ktx")      // Firebase Authentication
    implementation("com.google.firebase:firebase-firestore-ktx") // Firestore Database
    implementation("com.google.firebase:firebase-messaging-ktx") // Push Notifications (optional)
    implementation("androidx.compose.material3:material3:1.1.2")
    implementation("com.google.android.material:material:1.11.0")
}

flutter {
    source = "../.."
}
