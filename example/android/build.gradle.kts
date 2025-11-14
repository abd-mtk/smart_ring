allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            val localMavenRepo = file("${rootProject.projectDir}/../../android/local-maven-repo")
            url = uri("file://${localMavenRepo.absolutePath}")
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
