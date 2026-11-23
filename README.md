# Zahid Architecture Academy — Flutter (Full App v1.2.1)

Real functionality ke saath poori app: Firebase Auth/Firestore/Storage, admin upload
system, **verified** payments (pending/approved/rejected), 7-day trial, EN/UR/AR + RTL,
search/sort/filter/preview/downloads.

> ⚠️ Ye **Flutter code** hai, FlutterFlow project nahi. FlutterFlow alag low-code
> platform hai; is code ko FlutterFlow me import nahi kiya ja sakta.

---

## 📥 Downloads (BUILD READY ✅)

**GitHub Repository:** https://github.com/shahid-boop/zahid-academy

**Latest Release (v1.2.1):** https://github.com/shahid-boop/zahid-academy/releases/tag/v1.2.1

| File | Direct download |
|---|---|
| 📦 **APK** (testing ke liye) | https://github.com/shahid-boop/zahid-academy/releases/download/v1.2.1/app-release.apk |
| 📦 **AAB** (Play Store ke liye) | https://github.com/shahid-boop/zahid-academy/releases/download/v1.2.1/app-release.aab |

**CI Run (successful):** https://github.com/shahid-boop/zahid-academy/actions/runs/45156953853

> ℹ️ Ye build **GitHub Actions** par banaya gaya hai (Flutter 3.50.1, JDK 17,
> Android SDK 35/36). **Firebase secrets aur signing keystore set nahi hain**,
> isliye ye **LOCAL DEMO / debug-signed** build hai. Signed + Firebase-connected
> build ke liye `PLAY_STORE.md` me diye gaye secrets set karke workflow dobara chalayein.

---

## 📁 Structure

```
lib/
├── main.dart                     # app, theme, RTL, bottom nav + drawer
├── app_scope.dart                # state access (InheritedNotifier)
├── firebase_options.dart         # ⚠️ PLACEHOLDER - flutterfire configure se replace
├── models/                       # AppFile, AppUser, PaymentRequest, DownloadRecord
├── data/app_data.dart            # local fallback + Recent Lessons (exact 3 items)
├── services/
│   ├── firebase_service.dart     # safe init (config na ho to local demo)
│   ├── auth_service.dart         # register/login/profile/role
│   ├── content_repository.dart   # Firestore content stream + admin upload
│   ├── payment_service.dart      # requests + screenshot + admin review
│   ├── app_state.dart            # trial, premium (sirf approved se), UI state
│   ├── storage_service.dart
│   └── launcher_service.dart
├── l10n/strings.dart             # EN / UR / AR
├── widgets/                      # file_tile, payment_dialog
└── screens/                      # home, library, courses, profile, admin,
                                  # favorites, history, settings
firebase/                         # firestore.rules + storage.rules
PLAY_STORE.md                     # APK/AAB + publishing steps
```

---

## ✅ Implemented (master prompt ke mutabiq)

### UI
- Android-first navy/orange/white/grey theme, responsive
- Home: header (avatar + welcome), notification bell with badge, hamburger drawer,
  7-day trial banner, **category grid** (PDF Lessons, Videos, Pictures Gallery,
  Naqshay Maps, 3D Max Files, DWG Files, DXF Files), **Recent Lessons** with
  exact 3 items (AutoCAD Floor Plan DWG, 3D Max Interior, House Map 5 Marla DXF)
  each showing **title, date, size, type**
- Library page: search, sorting (name/date/size), type filters, downloads, previews
- Courses, Profile, Admin pages
- Bottom nav: Home / Library / Courses / Profile (+ Admin for admins)

### Backend
- Firebase Auth (register/login/profile/sign out)
- Firestore: `users`, `contents`, `payments`
- Firebase Storage: content files + payment screenshots
- Admin: upload PDF / video / image / DWG / DXF / 3D Max, publish/unpublish,
  payment approve/reject
- Published content app me automatically dikh jata hai (stream)

### Trust & Payments (fake verification REMOVED)
- ❌ Ab koi "Payment Done → instant unlock" button nahi hai
- ✅ Har payment ek **pending** request banata hai (reference + screenshot)
- ✅ Sirf admin approve/reject karta hai
- ✅ **Approved** request hi 30 din ka premium access deti hai
- ✅ Firestore rules client ko khud approve hone se rokte hain

### Trial & Support
- 7-day trial, start date, days-left counter, expiry, in-app notifications
- WhatsApp: configurable number + predefined message
- JazzCash / EasyPaisa: configurable numbers, instructions, reference, screenshot

### Languages
- English, Urdu, Arabic with **RTL layout** (Arabic par automatically RTL)

---

## 🚀 Setup

1. `flutter pub get`
2. Firebase setup ( zaroori ):
   ```bash
   firebase login
   flutterfire configure
   ```
   Detail: [PLAY_STORE.md](PLAY_STORE.md) Step 1.
3. Firebase Console me Email/Password auth, Firestore, Storage enable karein.
4. `firebase/firestore.rules` aur `firebase/storage.rules` publish karein.
5. Apne admin user ka Firestore document me `role: "admin"` set karein.
6. Settings me WhatsApp / JazzCash / EasyPaisa numbers aur optional Download Base URL save karein.
7. `flutter run`

> Firebase configure na karne par app **LOCAL DEMO mode** me chal jayegi
> (login/admin/payments unavailable, baaki UI kaam karegi) — crash nahi karegi.

---

## 🔐 Security note

Client-side admin check convenience ke liye hai; **asli guarantee Firestore rules**
me hai (`allow update: if isAdmin() && status in ['approved','rejected']`).
Production me payment approve ko **Cloud Function + Admin SDK** me shift karna
aur screenshot ka manual review rakhna best practice hai.

---

## 📦 Build & Publishing

Poori step-by-step guide: **[PLAY_STORE.md](PLAY_STORE.md)**

**Build status:** ✅ APK + AAB GitHub Actions par successfully build ho gaye
(run `45156953853`) aur GitHub Release `v1.2.1` par upload ho gaye — upar direct
download links diye gaye hain. Local environment me Flutter SDK nahi hai, isliye
build cloud par kiya gaya.

---

## 🧪 Testing checklist
PLAY_STORE.md me diya gaya hai (login, admin, payments, uploads, trial, RTL, etc.).

---

## 🔜 Remaining / known limitations
- Real Firebase project abhi connected nahi (placeholder config)
- Screenshot admin manual review karta hai (OCR auto-verify nahi)
- OS push notifications nahi — in-app notification center hai
- Trial/payment "30 din" fixed hai; server-side expiry Cloud Function se better hoga
- Real device testing pending (APK/AAB build ✅ ho gaya — upar direct links)
