# TraceAR - Build, Setup, and Deployment Guide

This guide details the configurations, dependencies, and steps necessary to build, compile, test, and release the TraceAR mobile application on Android and iOS.

---

## 1. Project Requirements & Dependencies

To compile and launch the app, ensure your workstation meets these prerequisites:
- **Flutter SDK**: `>= 3.0.0`
- **Dart SDK**: `>= 3.0.0 < 4.0.0`
- **CocoaPods** (for iOS builds): `1.11.0` or higher
- **Android Studio / Xcode**: Latest versions containing Android SDK 33+ and iOS SDK 15+.

Run `flutter pub get` in the root of the project to retrieve all packages listed in `pubspec.yaml`.

---

## 2. Firebase Backend Setup

TraceAR implements Firebase for Auth, Cloud Sync, and Analytics.

### A. Console Setup
1. Create a project in the [Firebase Console](https://console.firebase.google.com/).
2. Enable **Firebase Authentication** and turn on the **Email/Password**, **Google**, and **Apple** providers.
3. Enable **Cloud Firestore** in Production Mode and apply the rules in [firestore.rules](file:///C:/Users/sasankan/.gemini/antigravity-ide/scratch/trace_ar/firestore.rules).
4. Enable **Cloud Storage** and apply the rules in [storage.rules](file:///C:/Users/sasankan/.gemini/antigravity-ide/scratch/trace_ar/storage.rules).

### B. Client SDK Configuration
- **Android**: 
  - Register Android app: `com.tracear.app`.
  - Download `google-services.json` and place it in the `android/app/` directory.
- **iOS**:
  - Register iOS app: `com.tracear.app`.
  - Download `GoogleService-Info.plist` and drag it into your Xcode project structure under `Runner/`.

---

## 3. Android Native Configurations (ARCore)

TraceAR requires **ARCore** on Android. Devices must support Google Play Services for AR to run the AR Anchoring view.

### A. Manifest Config
The permissions and metadata are pre-configured in [AndroidManifest.xml](file:///C:/Users/sasankan/.gemini/antigravity-ide/scratch/trace_ar/android/app/src/main/AndroidManifest.xml).
- `uses-feature android:name="android.hardware.camera.ar" android:required="true"` blocks installations on devices without hardware camera AR support.
- Change `android:required="false"` in the feature tags if you wish to allow standard 2D Screen Overlay tracing on devices without physical AR capabilities.

### B. App Gradle Configuration
In `android/app/build.gradle`:
```groovy
defaultConfig {
    applicationId "com.tracear.app"
    minSdkVersion 24 // ARCore requires minimum SDK 24
    targetSdkVersion 33
    versionCode 1
    versionName "1.0.0"
}
```

### C. Release Build & Publishing
1. Generate an Upload Keystore:
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Configure `android/key.properties` with keystore password/aliases.
3. Build App Bundle (AAB):
   ```bash
   flutter build appbundle --release
   ```
4. Upload the generated `.aab` file located in `build/app/outputs/bundle/release/` to the Google Play Console under Internal Testing / Production channels.

---

## 4. iOS Native Configurations (ARKit)

TraceAR uses **ARKit** on iOS, which requires hardware A9 processors or newer.

### A. Info.plist Setup
Info.plist is configured with:
- `NSCameraUsageDescription`: Required for accessing camera feeds.
- `NSPhotoLibraryUsageDescription`: Required to load images from the local library.
- `UIRequiredDeviceCapabilities`: Set to `arkit` to restrict the App Store download to ARKit-compatible models (iPhone 6s and newer).

### B. Podfile Configuration
In `ios/Podfile`, set the global platform to iOS 11.0:
```ruby
platform :ios, '11.0'
```

### C. Release Build & App Store Publishing
1. Open the project in Xcode: `open ios/Runner.xcworkspace`.
2. Select the **Runner** root target and configure **Signing & Capabilities**.
3. Choose your Apple Developer Team and create an App Store provisioning profile.
4. Clean and compile target build:
   ```bash
   flutter build ipa --release
   ```
5. Open Xcode Organizer, select the generated archive, validate it, and upload the build directly to App Store Connect / TestFlight.

---

## 5. In-App Purchase Setup

### A. Google Play Console Setup
1. Open the Google Play Console -> Products -> In-App Products.
2. Click **Create Subscription**.
3. Set the Product ID to `tracear_premium_monthly` (as referenced in [billing_service.dart](file:///C:/Users/sasankan/.gemini/antigravity-ide/scratch/trace_ar/lib/core/services/billing_service.dart)).
4. Configure billing details, weekly/monthly pricing plans, and set the status to **Active**.

### B. App Store Connect Setup
1. Open App Store Connect -> Apps -> TraceAR -> Subscriptions.
2. Create a Subscription Group and add a new Auto-Renewable Subscription.
3. Define Product ID: `tracear_premium_monthly`.
4. Add localization tags, price tiers, and submit for review along with a screenshot of the premium purchase page.

---

## 6. Code Optimization: Offline Isolates

To guarantee zero latency on the camera viewport (retaining target 60 FPS rendering), all pixel manipulation algorithms for sketch filtering run in separate Dart **Isolates** using:
```dart
Future<String> path = await compute(_processInBackground, params);
```
This spawns a worker thread at the CPU layer, preventing visual stutter or frames freezing on the main thread when users load dense images or adjust tolerances.
For devices lacking hardware AR chips or in indoor settings where plane detection remains difficult, users can seamlessly toggle the **2D Screen Overlay** mode, which employs standard Flutter matrix transformations to scale, translate, rotate, and mirror stencils smoothly.
