import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    // Use BufferedReader with UTF-8 and strip BOM if present (PowerShell writes BOM by default).
    // Properties.load(InputStream) reads ISO-8859-1 and would corrupt the first key with a BOM prefix.
    keystorePropertiesFile.bufferedReader(Charsets.UTF_8).use { reader ->
        reader.mark(4)
        if (reader.read() != 0xFEFF) reader.reset()   // skip UTF-8 BOM if present
        keystoreProperties.load(reader)
    }
}

android {
    namespace = "com.lambac.coffeeroastery"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.lambac.coffeeroastery"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keyStorePath = keystoreProperties.getProperty("storeFile")
                ?: throw GradleException(
                    "Release signing error: 'storeFile' not found in android/key.properties."
                )
            // Resolve relative to the app module directory (android/app/), not the root project
            val resolvedKeystore = project.file(keyStorePath)
            if (!resolvedKeystore.exists()) {
                throw GradleException(
                    "Release signing error: Keystore not found at '${resolvedKeystore.absolutePath}'. " +
                    "Release builds must NEVER fall back to debug signing."
                )
            }
            storeFile = resolvedKeystore
            storePassword = keystoreProperties.getProperty("storePassword")
                ?: throw GradleException("Release signing error: 'storePassword' not found in android/key.properties.")
            keyAlias = keystoreProperties.getProperty("keyAlias")
                ?: throw GradleException("Release signing error: 'keyAlias' not found in android/key.properties.")
            keyPassword = keystoreProperties.getProperty("keyPassword")
                ?: throw GradleException("Release signing error: 'keyPassword' not found in android/key.properties.")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
