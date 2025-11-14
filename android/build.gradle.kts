// Top-level Gradle build file

plugins {
    // ❌ Do NOT set AGP version here (Flutter already provides it)
    id("com.android.application") apply false

    // Flutter Gradle plugin
    id("dev.flutter.flutter-gradle-plugin") apply false

    // Google Services plugin
    id("com.google.gms.google-services") apply false

    // Kotlin plugin (version managed by Flutter too)
    kotlin("android") apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Keep Flutter custom build directory
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
