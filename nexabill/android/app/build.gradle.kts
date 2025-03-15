plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services") // Add Firebase plugin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.nexabill"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // Ensure NDK version is set properly
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.nexabill"
        minSdk = 23 // Update minSdkVersion to match Firebase requirements
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// Firebase SDK dependencies
dependencies {
    // Import the Firebase BoM (Bill of Materials)
    implementation(platform("com.google.firebase:firebase-bom:33.10.0"))

    // Add required Firebase services (e.g., Authentication, Firestore, etc.)
    implementation("com.google.firebase:firebase-auth-ktx")      // Firebase Authentication
    implementation("com.google.firebase:firebase-firestore-ktx") // Firestore Database
    implementation("com.google.firebase:firebase-messaging-ktx") // Push Notifications (optional)
}

flutter {
    source = "../.."
}
