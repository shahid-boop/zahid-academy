#!/usr/bin/env python3
"""
Flutter ke 'flutter create --platforms=android' se banaye gaye Android project ko
CI ke liye configure karta hai:

  1. applicationId set karta hai (com.zahid.academy)
  2. INTERNET permission inject karta hai
  3. Optional release signing (env me keystore details ho to)

Groovy (build.gradle) aur Kotlin DSL (build.gradle.kts) dono support karta hai.
"""
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
APP = ROOT / "android" / "app"
MANIFEST = APP / "src" / "main" / "AndroidManifest.xml"

APP_ID = os.environ.get("ANDROID_APPLICATION_ID", "com.zahid.academy").strip()
KEYSTORE = os.environ.get("ANDROID_KEYSTORE_FILE", "").strip()
STORE_PASS = os.environ.get("ANDROID_STORE_PASSWORD", "").strip()
KEY_ALIAS = os.environ.get("ANDROID_KEY_ALIAS", "").strip()
KEY_PASS = os.environ.get("ANDROID_KEY_PASSWORD", "").strip()

SIGNING = bool(KEYSTORE and STORE_PASS and KEY_ALIAS and KEY_PASS)


def fail(msg: str) -> None:
    print(f"configure_android: ERROR: {msg}", file=sys.stderr)
    sys.exit(1)


def set_application_id(text: str, path: Path) -> str:
    if path.name.endswith(".kts"):
        new, n = re.subn(r'applicationId\s*=\s*"[^"]+"', f'applicationId = "{APP_ID}"', text)
    else:
        new, n = re.subn(r'applicationId\s+["\'][^"\']+["\']', f'applicationId "{APP_ID}"', text)
    if n == 0:
        print(f"configure_android: WARNING: applicationId not found in {path}")
    else:
        print(f"configure_android: applicationId -> {APP_ID}")
    return new


def set_sdk_versions(text: str) -> str:
    text = re.sub(r'minSdkVersion\s+\d+', 'minSdkVersion 21', text)
    text = re.sub(r'minSdk\s*=\s*\d+', 'minSdk = 21', text)
    text = re.sub(r'targetSdkVersion\s+\d+', 'targetSdkVersion 35', text)
    text = re.sub(r'targetSdk\s*=\s*\d+', 'targetSdk = 35', text)
    # Flutter 3.5x ke plugins (file_picker / lifecycle) ko compileSdk >= 36 chahiye.
    text = re.sub(r'compileSdkVersion\s+\d+', 'compileSdkVersion 36', text)
    text = re.sub(r'compileSdk\s*=\s*\d+', 'compileSdk = 36', text)
    text = re.sub(r'compileSdk\s+\d+', 'compileSdk 36', text)
    return text


def add_signing(text: str, path: Path) -> str:
    if not SIGNING:
        print("configure_android: no keystore secrets -> release build stays unsigned/debug-signed")
        return text

    if path.name.endswith(".kts"):
        block = (
            '    signingConfigs {\n'
            '        create("release") {\n'
            '            storeFile = file(System.getenv("ANDROID_KEYSTORE_FILE")!!)\n'
            '            storePassword = System.getenv("ANDROID_STORE_PASSWORD")\n'
            '            keyAlias = System.getenv("ANDROID_KEY_ALIAS")\n'
            '            keyPassword = System.getenv("ANDROID_KEY_PASSWORD")\n'
            '        }\n'
            '    }\n'
        )
        text = text.replace('signingConfig = signingConfigs.getByName("debug")', "")
        # Pehle release block me assignment karo, USKE BAAD signingConfigs block insert karo
        # (warna regex naye block ke 'release' se match ho jata hai).
        text = re.sub(
            r'(getByName\("release"\)\s*\{)',
            r'\1\n            signingConfig = signingConfigs.getByName("release")',
            text,
            count=1,
        )
        if 'signingConfigs {' not in text:
            text = text.replace('buildTypes {', block + '    buildTypes {', 1)
    else:
        block = (
            '    signingConfigs {\n'
            '        release {\n'
            '            storeFile file(System.getenv("ANDROID_KEYSTORE_FILE"))\n'
            '            storePassword System.getenv("ANDROID_STORE_PASSWORD")\n'
            '            keyAlias System.getenv("ANDROID_KEY_ALIAS")\n'
            '            keyPassword System.getenv("ANDROID_KEY_PASSWORD")\n'
            '        }\n'
            '    }\n'
        )
        text = text.replace('signingConfig signingConfigs.debug', "")
        # Pehle release block me assignment karo, USKE BAAD signingConfigs block insert karo.
        text = re.sub(
            r'(release\s*\{)',
            r'\1\n            signingConfig signingConfigs.release',
            text,
            count=1,
        )
        if 'signingConfigs {' not in text:
            text = text.replace('buildTypes {', block + '    buildTypes {', 1)

    print("configure_android: release signing configured")
    return text


def patch_build_file() -> None:
    candidates = [APP / "build.gradle", APP / "build.gradle.kts"]
    path = next((p for p in candidates if p.exists()), None)
    if path is None:
        fail(f"app build file not found in {APP}")
    text = path.read_text(encoding="utf-8")
    text = set_application_id(text, path)
    text = set_sdk_versions(text)
    text = add_signing(text, path)
    path.write_text(text, encoding="utf-8")
    print(f"configure_android: patched {path}")


def patch_manifest() -> None:
    if not MANIFEST.exists():
        fail(f"manifest not found: {MANIFEST}")
    text = MANIFEST.read_text(encoding="utf-8")
    perm = '<uses-permission android:name="android.permission.INTERNET"/>'
    if perm not in text:
        text, n = re.subn(r'(<manifest\b[^>]*>)', r'\1\n    ' + perm, text, count=1)
        if n == 0:
            fail("could not inject INTERNET permission")
        MANIFEST.write_text(text, encoding="utf-8")
        print("configure_android: INTERNET permission added")
    else:
        print("configure_android: INTERNET permission already present")


if __name__ == "__main__":
    patch_build_file()
    patch_manifest()
    print("configure_android: done")
