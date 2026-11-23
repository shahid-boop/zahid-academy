# Android SDK — Termux (aarch64) Installation Report

## ✅ Installed (Nov 23 2026)

| Component | Version / path |
|---|---|
| Java JDK | OpenJDK 21 (`$PREFIX/lib/jvm/java-21-openjdk`) |
| Android cmdline-tools | 11076708 (`sdkmanager` v12.0) → `~/android-sdk/cmdline-tools/latest` |
| Android platform-tools | 37.0.3 → `~/android-sdk/platform-tools` |
| Android platform 34 | `~/android-sdk/platforms/android-34` |
| Android platform 35 | `~/android-sdk/platforms/android-35` |
| Build-tools 34.0.0 | `~/android-sdk/build-tools/34.0.0` |
| Build-tools 35.0.0 | `~/android-sdk/build-tools/35.0.0` |
| Native adb / apksigner / d8 | Termux packages `android-tools`, `apksigner`, `d8` |
| QEMU user-mode x86_64 | `qemu-user-x86-64` |
| x86_64 sysroot (glibc + libgcc) | `~/android-sdk/qemu-sysroot` |

**Total SDK size:** ~750 MB. Location: `~/android-sdk`.

---

## ⚙️ Environment (already appended to `~/.bashrc`)

```bash
export ANDROID_HOME="$HOME/android-sdk"
export ANDROID_SDK_ROOT="$HOME/android-sdk"
export QEMU_SYSROOT="$HOME/android-sdk/qemu-sysroot"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/35.0.0:$PATH"
```

New terminal (ya `source ~/.bashrc`) me available commands:

```bash
sdkmanager --version          # 12.0
sdkmanager --list             # available packages
adb version                   # native Termux adb (37.0.0)
aapt2 version                 # qemu-wrapped (2.19)
zipalign                      # qemu-wrapped
apksigner --version           # native (0.9)
```

---

## 🔧 aarch64 compatibility note

Google ke Android binary tools (`aapt2`, `zipalign`, `adb`, `fastboot`, `aidl`, ...).
sirf **x86_64 ELF** me aate hain — Termux (aarch64) par direct nahi chalte.
Isliye:

- x86_64 binaries ko `*.x86_64` me rename kiya gaya
- unki jagah **shell wrappers** rakhe gaye jo `qemu-x86_64 -L ~/android-sdk/qemu-sysroot <binary>.x86_64 "$@"` chalati hain
- `adb` / `fastboot` ke wrappers native Termux binaries par forward karte hain

Puura test:
```
aapt2 version     ✅ Android Asset Packaging Tool (aapt) 2.19-11948202
zipalign          ✅ Zip alignment utility
qemu adb version  ✅ Android Debug Bridge 1.0.41
```

---

## ⚠️ Limitations (honest)

1. **Flutter SDK abhi bhi installed nahi hai.** Android SDK se akela APK nahi banega.
   Flutter officially linux-x86_64 hi ship karta hai; aarch64/Termux par
   community arm64 build ya qemu ke through chalana padega (alag kaam).
2. **Android Emulator nahi** — yahan Android system image run karna possible nahi.
   Real device ko `adb` se connect karke test kar sakte hain.
3. **Gradle build abhi verify nahi kiya** — Flutter SDK ke bina `flutter build apk`
   chalana possible nahi tha. Build-tools wrappers/qemu se chalne ki ummeed hai,
   lekin guaranteed nahi.
4. **NDK installed nahi** — plugins jo native code use karte hain (kuch Firebase
   modules) ke liye `sdkmanager "ndk;27.2.12479018"` chahie ho sakta hai.

---

## 📌 Useful commands

```bash
# licenses accept (ek dafa)
yes | sdkmanager --licenses

# aur package install
sdkmanager "platforms;android-36" "build-tools;36.0.0"

# installed packages
sdkmanager --list_installed

# real device check
adb devices
```

---

## 🎯 Next step for actual APK

1. Flutter SDK (arm64-compatible) install karein / ya kisi Linux x86_64 machine ya
   CI (GitHub Actions) par build karein — **yahi recommended hai**.
2. `flutter doctor -v` me Android SDK path confirm karein (`~/android-sdk`).
3. `flutter pub get && flutter build apk --release`.
4. Ya `PLAY_STORE.md` me diye gaye AAB steps follow karein.
