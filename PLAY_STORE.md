# Android Build & Play Store Publishing

⚠️ **IMPORTANT:** Is environment me **Flutter SDK nahi hai** (Android SDK ab
install ho gaya hai — dekhein `ANDROID_SDK_TERMUX.md`). **APK ya AAB abhi build
nahi kiya gaya.** Sabse aasan raasta niche wala **GitHub Actions** hai.

---

## 0. ⭐ Recommended: GitHub Actions se build (x86_64 cloud)

Ye sabse easy hai — aapko local Flutter install ki zarurat nahi.

### 0.1 GitHub repo banayein aur code push karein
```bash
cd zahid_academy_app
git init
git add .
git commit -m "Zahid Academy app: Flutter + Firebase + verified payments"
git branch -M main
git remote add origin https://github.com/<USERNAME>/zahid-academy.git
git push -u origin main
```

### 0.2 Workflow already ready hai
`.github/workflows/build-android.yml` — ye automatically:
- Flutter stable + JDK 17 + Android SDK 35 setup karta hai
- `android/` folder na ho to `flutter create` se banata hai
- applicationId `com.zahid.academy`, INTERNET permission inject karta hai
- **APK** aur **AAB** dono build karta hai
- artifacts upload karta hai

### 0.3 Build chalayein
GitHub repo → **Actions** tab → **Build Android APK & AAB** → **Run workflow**.
~5-10 minute baad artifacts download ho jayenge:
- `zahid-academy-apk` → `app-release.apk` (testing ke liye)
- `zahid-academy-aab` → `app-release.aab` (Play Store ke liye)

### 0.4 Optional secrets (Settings → Secrets and variables → Actions → New secret)

| Secret | Kya hai |
|---|---|
| `KEYSTORE_BASE64` | `base64 -w0 zahid-upload-key.jks` ka output |
| `KEYSTORE_PASSWORD` | keystore password |
| `KEY_ALIAS` | key alias |
| `KEY_PASSWORD` | key password |
| `GOOGLE_SERVICES_JSON` | `android/app/google-services.json` ka base64 |
| `FIREBASE_OPTIONS_DART` | real `lib/firebase_options.dart` ka base64 |

Secrets na dene par app **LOCAL DEMO mode** me banega (Firebase ke bina) aur
release **unsigned/debug-signed** hoga — Play Store ke liye secrets zaroori hain.

### 0.5 Direct GitHub Release (optional)
```bash
git tag v1.2.0
git push origin v1.2.0
```
Tag push karte hi workflow APK + AAB ko GitHub Release par attach kar deta hai.

---

## 1. Pehle Firebase configure karein (warning: abhi placeholder hai)

`lib/firebase_options.dart` me fake keys hain. Real project ke liye:

```bash
# Firebase CLI login
firebase login

# Flutter project me Firebase add karein (Android package select karein)
flutterfire configure
```

Ye command:
- `firebase_options.dart` ko real values se overwrite karti hai
- `android/app/google-services.json` create karti hai

Firebase Console me:
1. **Authentication → Sign-in method → Email/Password → Enable**
2. **Firestore Database → Create database**
3. **Storage → Get started**
4. **Rules** tab me `firebase/firestore.rules` aur `firebase/storage.rules` ki contents paste karke **Publish** karein
5. Firestore me `users/{adminUid}` document banayein:
   ```json
   { "uid": "<uid>", "email": "admin@zahid.com", "displayName": "Admin", "role": "admin" }
   ```
   (Pehle app se us email se register karein, phir Firestore me `role: "admin"` set karein.)

---

## 2. Android configuration

`android/app/build.gradle` (aha newer Flutter me `app/build.gradle.kts`):

```gradle
defaultConfig {
    applicationId "com.zahid.academy"   // <- apna package name
    minSdkVersion 21
    targetSdkVersion 34
    versionCode 3
    versionName "1.2.0"
}
```

`android/app/src/main/AndroidManifest.xml` me `<manifest>` ke andar:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

`<application>` tag me agar cleartext local testing chahiye to:
```xml
android:usesCleartextTraffic="true"
```
(Production me HTTPS hi use karein.)

App icon: `android/app/src/main/res/mipmap-*/ic_launcher.png` ko apne icon se replace karein
(ya `flutter_launcher_icons` package use karein).

---

## 3. Dependencies aur check

```bash
flutter pub get
flutter analyze        # saare errors fix karein
flutter test
```

---

## 4. APK (testing ke liye)

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

Debug/testing ke liye:
```bash
flutter build apk --debug
```

---

## 5. Signed AAB (Google Play ke liye)

### 5.1 Upload key banayein (ek dafa hi)
```bash
keytool -genkey -v -keystore ~/zahid-upload-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias zahid-upload
```

### 5.2 `android/key.properties` banayein (git me commit NA karein)
```properties
storePassword=<password>
keyPassword=<password>
keyAlias=zahid-upload
storeFile=/absolute/path/to/zahid-upload-key.jks
```

### 5.3 `android/app/build.gradle` me signing配置
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

### 5.4 Build
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

---

## 6. Play Store upload

1. https://play.google.com/console → **Create app**
2. App name: **Zahid Architecture Academy**, language English (Urdu/Arabic later)
3. **App content** form bharein (privacy policy URL zaroori hai)
4. **Production → Create new release → Upload AAB**
5. Release notes likhein → **Review release → Start rollout**
6. Data safety form: Firebase Auth/Firestore/Storage ka use declare karein

---

## 7. Test checklist (release se pehle)

- [ ] Login / registration
- [ ] Admin role sirf admin ko dikhe
- [ ] Payment request pending dikhe
- [ ] Sirf admin approve kare → tabhi premium unlock
- [ ] Reject hone par access na mile
- [ ] PDF / video / image / DWG / DXF / 3D Max upload + publish
- [ ] Published content app me automatic dikhe
- [ ] Search / sort / filter / preview / download
- [ ] 7-day trial countdown + expiry
- [ ] WhatsApp button configured number par khule
- [ ] EN / UR / AR + RTL layout
- [ ] Low-end Android device par test

---

## 8. Abhi kya missing hai (honest status)

- ❌ APK / AAB **abhi build nahi kiye** (yahan Flutter SDK nahi hai)
- ✅ GitHub Actions workflow **ready** — upar Step 0 follow karke build karein
- ❌ Real Firebase project **connected nahi** (placeholder options / secret set nahi)
- ❌ App icon / signing keystore **configured nahi**
- ❌ Real device testing **nahi hui**
- ✅ Android SDK (Termux), source code, security rules aur publishing steps **ready hain**
