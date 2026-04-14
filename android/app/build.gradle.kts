plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
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
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

tasks.withType<JavaCompile>().configureEach {
    exclude("io/flutter/plugins/GeneratedPluginRegistrant.java")
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
