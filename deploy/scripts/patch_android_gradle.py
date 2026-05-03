"""Patch the Flutter-generated android/app/build.gradle(.kts) to read signing
config from android/key.properties and apply it to the release build type.

Idempotent — re-running on an already-patched file is a no-op."""

import sys
from pathlib import Path

SENTINEL = "// >>> sharework release signing"

KOTLIN_BLOCK = """
// >>> sharework release signing
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = java.util.Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { rootProject.file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
// <<< sharework release signing
"""

GROOVY_BLOCK = """
// >>> sharework release signing
def keystorePropertiesFile = rootProject.file("key.properties")
def keystoreProperties = new Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? rootProject.file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
// <<< sharework release signing
"""


def main(path: str) -> None:
    p = Path(path)
    text = p.read_text()
    if SENTINEL in text:
        print(f"[patch] {p} already patched — skipping.")
        return
    block = KOTLIN_BLOCK if p.suffix == ".kts" else GROOVY_BLOCK
    p.write_text(text + "\n" + block)
    print(f"[patch] appended release signing block to {p}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("usage: patch_android_gradle.py <path-to-build.gradle[.kts]>", file=sys.stderr)
        sys.exit(2)
    main(sys.argv[1])
