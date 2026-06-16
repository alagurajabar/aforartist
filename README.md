# A for Artist

 lets anyone turn their smartphone camera into a canvas.
Point the device at any surface, tap the on‑screen controls, and paint or draw directly in the augmented‑reality view. The app uses on‑device machine‑learning to detect objects and track the scene, so your sketches stay anchored as you move. No special hardware is required—just a modern Android or iOS phone. Perfect for quick visual brainstorming, teaching, or just having fun with AR‑enabled art.

---

 Features

- **Real‑time AR camera view** with smooth overlay controls.
- **Object detection** using on‑device ML models.
- **Interactive controls panel** for toggling detection, switching cameras, and adjusting settings.
- **Cross‑platform** support for Android (pre‑configured build scripts) and iOS.
- **Modular architecture** – core services (e.g., `BillingService`) are isolated for easy extension.
- **Hot‑reload friendly** – full Flutter hot‑reload workflow for rapid iteration.

---

##  Requirements

| Requirement | Version / Details |
|-------------|-------------------|
| **Flutter SDK** | >= 3.22.0 (tested with 3.22.1) |
| **Dart** | >= 3.5.0 |
| **Android SDK** | API 33 (Android 13) – required for `android/app/build.gradle` |
| **Xcode** (iOS) | 15.0+ (if building for iOS) |
| **Device** | Android phone/tablet with camera support (iOS device optional) |
| **Dependencies** | Managed via `pubspec.yaml` – see the file for the full list |

> **Note**: The project uses a PowerShell script (`build_android.ps1`) to streamline Android builds.

---

##  Installation & Setup

1. **Clone the repository**
   ```bash
   git clone <repo‑url>
   cd trace_ar
   ```
2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```
3. **Configure Android SDK** (if not already set)
   - Ensure `ANDROID_HOME` points to your SDK directory.
   - Accept Android licenses:
     ```bash
     flutter doctor --android-licenses
     ```
4. **Run the app**
   ```bash
   flutter run
   ```
   - Connect a device or start an emulator.
5. **Build for Android** (optional)
   ```powershell
   ./build_android.ps1
   ```
   This script assembles a signed APK using the Gradle wrapper.

---

##  Usage

- Launch the app on a device.
- Tap the **Controls Panel** (bottom‑right) to:
  - Enable/disable object detection.
  - Switch between front and rear cameras.
  - Adjust detection confidence thresholds.
- Billing services are ready for integration – see `lib/core/services/billing_service.dart` for the API.

---

##  Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository.
2. Create a feature branch:
   ```bash
   git checkout -b feature/your‑feature
   ```
3. Make your changes and ensure the app still builds.
4. Run tests (if any) and format the code:
   ```bash
   flutter format .
   ```
5. Open a pull request describing your changes.

---

##  License

Distributed under the **MIT License**. See `LICENSE` for more information.

---

##  Additional Resources

- Flutter documentation: https://flutter.dev/docs
- ARCore (Android) guide: https://developers.google.com/ar
- Dart language tour: https://dart.dev/guides
