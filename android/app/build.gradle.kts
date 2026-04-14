plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

fun sanitizePackagedResources(project: Project) {
    val packagedResDir = project.layout.buildDirectory.dir("intermediates/packaged_res").get().asFile
    if (!packagedResDir.exists()) {
        return
    }

    packagedResDir
        .walkTopDown()
        .filter { file ->
            file.isFile && Regex(""".+ \d+\.(png|xml|webp)$""").matches(file.name)
        }
        .forEach { file ->
            project.logger.lifecycle("Deleting invalid generated resource ${file.absolutePath}")
            file.delete()
        }
}

android {
    namespace = "org.taigidict.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                val storeFilePath = keystoreProperties.getProperty("storeFile")
                check(!storeFilePath.isNullOrBlank()) {
                    "android/key.properties is missing storeFile"
                }
                storeFile = file(storeFilePath)
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "org.taigidict.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

tasks.matching { task ->
    task.name.startsWith("package") && task.name.endsWith("Resources")
}.configureEach {
    doLast {
        sanitizePackagedResources(project)
    }
}

tasks.matching { task ->
    task.name.startsWith("parse") && task.name.endsWith("LocalResources")
}.configureEach {
    doFirst {
        sanitizePackagedResources(project)
    }
}
