# Firebase App Check — Production Implementation & Security Operations Guide
## Lambac Coffee Roastery Mobile Ordering, Communication & Analytics System

---

## 1. Executive Summary & Architecture

Firebase App Check protects **Lambac Coffee Roastery** backend cloud resources (Cloud Firestore, Cloud Storage, and Firebase Authentication) from unauthorized clients, replay attacks, script-kiddie scrapers, and malicious tampering. 

It accomplishes this by requiring clients to attest device and app authenticity through native platform attestation providers:

| Platform | Production Provider | Development / Testing Provider | Status |
| :--- | :--- | :--- | :--- |
| **Android** | Google Play Integrity API | `AndroidDebugProvider` | Configured |
| **iOS / iPadOS** | Apple App Attest (with DeviceCheck Fallback) | `AppleDebugProvider` | Configured |
| **macOS** | Apple App Attest (with DeviceCheck Fallback) | `AppleDebugProvider` | Configured |
| **Web** | Google reCAPTCHA v3 / Enterprise | reCAPTCHA debug token | Configured |
| **Windows / Linux Desktop** | Gracefully bypassed for local toolchains | Bypassed (unsupported native SDK) | Handled |

> [!IMPORTANT]
> **Defense-in-Depth Principle:**
> Firebase App Check is **NOT** a replacement for:
> 1. **Firebase Authentication:** Does not verify *who* the user is.
> 2. **Firestore Security Rules:** Does not evaluate record ownership, RBAC permissions, or data schemas.
> 3. **Cloud Storage Rules:** Does not check file size boundaries or MIME types.
> 
> App Check acts as an exterior security gate (attesting that requests originate from an authentic Lambac Coffee Roastery application binary on a verified physical device), while Security Rules and Auth act as the interior vault locks.

---

## 2. Project & Application Identifiers

The Lambac Coffee Roastery project resources registered in Firebase:

| Attribute | Identifier |
| :--- | :--- |
| **Firebase Project ID** | `lambac-coffee-roastery` |
| **Android Package / Application ID** | `com.example.lambac_app` |
| **Android App ID** | `1:122572066362:android:f7fa36af4f79a6ce5a6f03` |
| **iOS Bundle Identifier** | `com.example.lambacApp` |
| **iOS App ID** | `1:122572066362:ios:20b5792d1c491b305a6f03` |
| **Web App ID** | `1:122572066362:web:fe445d4fa528c6735a6f03` |
| **Storage Bucket** | `lambac-coffee-roastery.firebasestorage.app` |

---

## 3. Implementation Details

### 3.1 Startup Flow & Activation Timing

App Check is initialized immediately following `Firebase.initializeApp()` in `lib/main.dart` and **BEFORE** any Firestore remote data sources, Auth calls, or UI rendering pipelines start:

```
[main()]
   │
   ▼
[WidgetsFlutterBinding.ensureInitialized()]
   │
   ▼
[Firebase.initializeApp()]
   │
   ▼
[AppConfig.fromEnvironment()]
   │
   ▼
[AppCheckService.initialize()]  <── Activates Play Integrity / App Attest / reCAPTCHA
   │                                   Enables token auto-refresh
   ▼
[Remote Datasource Initializations] <── All outgoing Firestore calls carry attested tokens
   │
   ▼
[runApp(ProviderScope(...))]
```

### 3.2 Service Implementation (`lib/core/services/app_check_service.dart`)

The `AppCheckService` singleton manages attestation lifecycle:
- **Compile-time Release Guard:** Automatically inspects `kReleaseMode`. Debug providers cannot be selected in release builds.
- **Token Auto-Refresh:** Automatically invokes `setTokenAutoRefreshEnabled(true)`. Because App Check tokens typically expire in 1 hour, auto-refresh prevents customer carts, Barista POS registers, or Admin analytics dashboards from experiencing sudden attestation drops during long operational sessions.
- **Desktop/Testing Resilience:** Safely recognizes Windows and Linux desktop runtime environments without crashing the Flutter application zone.

---

## 4. Firebase Console Configuration Guide

To enable verification on Firebase Console:

### 4.1 Android Setup (Play Integrity API)

1. Open **Firebase Console** → Project `lambac-coffee-roastery`.
2. Navigate to **Build** → **App Check** → **Apps** tab.
3. Locate Android app: `com.example.lambac_app`.
4. Click **Play Integrity**:
   - If using Google Play App Signing:
     - Open **Google Play Console** → Select Lambac app → **Release** → **Setup** → **App Integrity**.
     - Link your Google Play project directly to Firebase.
     - Copy the **SHA-256 fingerprint** of the App Signing Key and Upload Key into **Project Settings** → **Android Apps** in Firebase Console.
   - Set **Token TTL**: 1 hour (default recommended).
5. Click **Save**.

### 4.2 Apple Setup (App Attest & DeviceCheck)

1. Navigate to **App Check** → **Apps** → select iOS app `com.example.lambacApp`.
2. Click **App Attest**:
   - Provide your **Apple Developer Team ID** (10-character alphanumeric ID from developer.apple.com).
   - Enter your **Key ID** and upload the private key file (`.p8`) generated in the Apple Developer portal with **DeviceCheck / App Attest** enabled.
3. Set **Token TTL**: 1 hour.
4. Click **Save**.

### 4.3 Web Setup (reCAPTCHA v3 / Enterprise)

1. Navigate to [Google reCAPTCHA Admin Console](https://www.google.com/recaptcha/admin).
2. Create a new **reCAPTCHA v3** key:
   - Add domains: `lambac-coffee-roastery.web.app`, `lambac-coffee-roastery.firebaseapp.com`, and `localhost` (for staging/testing).
   - Copy the generated **Site Key** and **Secret Key**.
3. In Firebase Console → **App Check** → **Apps** → Web app:
   - Select **reCAPTCHA v3**.
   - Paste the **reCAPTCHA Secret Key**.
4. Pass the Site Key during build:
   ```bash
   flutter build web --dart-define=RECAPTCHA_SITE_KEY=<YOUR_RECAPTCHA_SITE_KEY>
   ```

---

## 5. Development & Testing Workflow

### 5.1 Local Android Debug Provider

When running in `kDebugMode` on an Android emulator or test device:
1. Launch the app in debug mode: `flutter run`
2. Search Android Logcat or IDE console for:
   ```
   D/DebugAppCheckProvider: Enter this debug secret into the allow list in the Firebase Console for your project: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
   ```
3. In Firebase Console:
   - Navigate to **App Check** → **Apps** → **Android**.
   - Click the 3 dots menu `⋮` → **Manage debug tokens**.
   - Click **Add debug token**, paste the UUID secret, and give it a label (e.g., `Dev-Pixel-Emulator-1`).

### 5.2 Local iOS Debug Provider

When running in Xcode / iOS Simulator:
1. Launch app in debug mode on iOS Simulator.
2. In Xcode console or terminal logs, locate:
   ```
   [Firebase/AppCheck][I-FAA001001] Firebase App Check Debug Token: YYYYYYYY-YYYY-YYYY-YYYY-YYYYYYYYYYYY
   ```
3. Add the token under **App Check** → **Apps** → **iOS** → **Manage debug tokens**.

### 5.3 Automated CI/CD Testing

In continuous integration (GitHub Actions, GitLab CI):
- Set a permanent debug token secret in CI environment variables.
- Run tests using Flutter's test runner. The unit test suite in `test/core/services/app_check_service_test.dart` runs with mockable providers, verifying provider resolution and token stream propagation with zero network dependencies.

---

## 6. Staged Enforcement Rollout Strategy

Enforcing App Check immediately without a monitoring phase will break existing users who haven't updated or clients with attestation misconfigurations. **Follow this 3-stage rollout procedure:**

```
┌────────────────────────────────┐
│   Phase 1: Monitoring Mode     │  Deploy app with App Check activated.
│        (2 to 4 Weeks)          │  Enforcement toggled OFF in Firebase Console.
└───────────────┬────────────────┘
                │
                ▼
┌────────────────────────────────┐
│   Phase 2: Metric Validation   │  Observe App Check dashboard in Firebase Console.
│     (Target: >99% Verified)    │  Confirm verified traffic approaches 100%.
└───────────────┬────────────────┘
                │
                ▼
┌────────────────────────────────┐
│   Phase 3: Staged Enforcement  │  Enable enforcement one product at a time:
│      (One product at a time)   │  1. Cloud Firestore -> Enforce
└────────────────────────────────┘  2. Cloud Storage -> Enforce
                                    3. Firebase Auth -> Enforce
```

### Phase 1: Monitoring Mode (Current State)
- The app client transmits App Check tokens with every request.
- In Firebase Console, enforcement remains **Unenforced**.
- All requests (verified and unverified) are allowed through, but Firebase logs attestation statistics.

### Phase 2: Monitoring Metrics Verification
In Firebase Console → **App Check**:
1. Check the **Cloud Firestore** metrics graph:
   - **Verified requests:** Legitimate traffic from genuine app instances.
   - **Outdated client requests:** Legitimate traffic from old app versions without App Check.
   - **Unverified requests:** Unknown origins, emulator requests without debug tokens, or scrapers.
2. Ensure **Verified requests** reach **99%+** of active daily requests before proceeding.

### Phase 3: Service-by-Service Enforcement
1. **Cloud Firestore:** Click **Enforce** → Confirm.
   - Verify customer ordering, menu browsing, chat, and admin dashboards.
2. **Cloud Storage:** Click **Enforce** → Confirm.
   - Verify product image loading and customer chat receipt uploads.
3. **Firebase Authentication:** Click **Enforce** → Confirm.
   - Verify customer and barista sign-in and registration workflows.

---

## 7. Troubleshooting & Verification Matrix

| Symptom | Cause | Solution |
| :--- | :--- | :--- |
| `FirebaseException: [app-check/fetch-status-error]` | Device cannot connect to attestation service (Google Play / Apple) | Verify device has active network and Google Play Services / iOS 14+ installed. |
| `[app-check/invalid-token]` in debug mode | Debug token not registered in Firebase Console | Copy UUID from logcat/console into Firebase Console under "Manage debug tokens". |
| Firestore queries failing after enforcement | App Check not initialized before Firestore queries | Verify `AppCheckService.initialize()` is called immediately after `Firebase.initializeApp()`. |
| Web app failing attestation | Missing or incorrect reCAPTCHA site key | Verify `RECAPTCHA_SITE_KEY` in `.env` or `--dart-define` matches the key registered in Firebase Console. |
| Play Integrity attestation failing in release APK | SHA-256 fingerprint mismatch | Ensure SHA-256 fingerprint from Google Play Console (or release keystore) is registered under Android App in Firebase Console. |
| Desktop unit tests failing | Desktop platforms lack native App Check C++ binaries | `AppCheckService` automatically handles unsupported desktop platforms gracefully without crashing. |
