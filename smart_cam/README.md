# Smart Cam - AI Camera Application

[![Flutter](https://img.shields.io/badge/Flutter-3.19+-blue.svg)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android-green.svg)](https://www.android.com)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## 📖 Project Description

**Smart Cam** is an AI-powered smart camera application that provides real-time shooting suggestions and composition guidance through large language model analysis.

### ✨ Core Features

#### Real-time AI Assistance
- **Real-time Scene Analysis**: Automatically detects scene stability and triggers AI analysis
- **Shooting Suggestions**: Provides exposure, focus, white balance suggestions and composition guidance
- **Multi-model Support**: Flexibly integrates GPT-4o, Claude, Qwen-VL and other LLM providers
- **Smart Throttling**: Re-analyzes only when scenes change significantly, saving data and battery
- **Photo Editing Recommendations**: Provides post-processing parameters and filter suggestions after taking photos

#### Photo Management (New in v1.1.0)
- **Local Photo Storage**: Photos are automatically saved to app storage with metadata
- **Photo Gallery**: Browse all taken photos in a beautiful grid layout
- **Photo Details**: View full photo with complete AI analysis results
- **Thumbnail Generation**: Automatic 200x200 thumbnails for fast browsing
- **Persistent Metadata**: All photo data persists across app restarts

#### Camera Controls (New in v1.1.0)
- **Flash Control**: Three modes - Off / Auto / On, default to Off
- **Quick Gallery Access**: Latest photo thumbnail on camera screen
- **Camera Settings**: Save camera settings (flash mode, etc.) with each photo
- **Bug Fixes**: Fixed frequent flash flickering issue

#### Platform Support
- **Cross-platform Architecture**: Android first, with iOS expansion capability

### 🎯 Use Cases

- Photography beginners learning professional shooting techniques
- Quick optimal shooting parameters while traveling
- Optimization suggestions for specific scenes (portrait, landscape, food)
- Post-processing parameter reference

---

## 🛠️ Local Development Environment Requirements

### System Requirements

| OS | Minimum Version | Recommended Version |
|---------|---------|---------|
| Windows | 10 (64-bit) | 11 (64-bit) |
| macOS | 10.15 (Catalina) | 12+ (Monterey/Ventura) |
| Linux | Ubuntu 18.04+ | Ubuntu 22.04+ |

### Software Dependencies

| Tool | Minimum Version | Recommended Version | Purpose |
|-----|---------|---------|------|
| **Flutter SDK** | 3.19.0 | 3.22.0+ | Cross-platform framework |
| **Dart SDK** | 3.3.0 | 3.4.0+ | Programming language |
| **Android Studio** | Hedgehog (2023.1.1) | Koala (2024.1.2)+ | IDE & Emulator |
| **Android SDK** | API 21 | API 34 | Development toolkit |
| **Gradle** | 8.0 | 8.7+ | Build tool |
| **Git** | 2.x | Latest stable | Version control |

---

## 📁 Project Structure

```
smart_cam/
├── android/              # Android platform specific files
│   ├── app/
│   │   ├── build.gradle
│   │   └── src/main/
│   │       ├── AndroidManifest.xml
│   │       ├── kotlin/   # Native Kotlin code
│   │       └── res/      # Android resources
│   ├── build.gradle
│   ├── settings.gradle
│   └── gradle.properties
├── ios/                  # iOS platform specific files
│   └── Runner/
├── lib/                  # Dart source code
│   ├── main.dart         # Application entry point
│   ├── core/             # Core utilities and config
│   │   ├── config/
│   │   │   └── app_config.dart
│   │   └── utils/
│   │       └── logger.dart
│   └── features/         # Feature modules
│       ├── analysis/     # AI analysis feature
│       │   ├── domain/
│       │   ├── data/
│       │   └── presentation/
│       ├── camera/       # Camera functionality
│       │   └── presentation/
│       │       ├── camera_service.dart
│       │       └── pages/
│       │           └── camera_page.dart
│       ├── photo/        # Photo management (New)
│       │   ├── domain/
│       │   │   └── photo_metadata.dart
│       │   └── presentation/
│       │       ├── photo_storage_service.dart
│       │       └── pages/
│       │           ├── photo_gallery_page.dart
│       │           └── photo_detail_page.dart
│       └── settings/     # App settings
│           ├── domain/
│           └── presentation/
├── test/                 # Test files
│   ├── unit/             # Unit tests
│   └── widget/           # Widget tests
├── assets/               # Static assets
│   ├── images/
│   └── fonts/
├── pubspec.yaml          # Flutter dependencies
└── analysis_options.yaml # Dart analyzer configuration
```

---

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following:
- Flutter SDK installed (3.19.0 or higher)
- Android Studio or VS Code with Flutter extensions
- Android SDK and emulator or physical device

### 1. Clone the repository

```bash
git clone <repository-url>
cd smart_cam
```

### 2. Configure Flutter mirror (China users only)

If you're in China, configure Flutter to use mirror servers for faster downloads:

```bash
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
```

To make this permanent, add these lines to your `~/.zshrc` or `~/.bashrc`:

```bash
echo 'export PUB_HOSTED_URL=https://pub.flutter-io.cn' >> ~/.zshrc
echo 'export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn' >> ~/.zshrc
source ~/.zshrc
```

### 3. Install dependencies

```bash
flutter pub get
```

### 4. Run the application

```bash
# Connect a device or start an emulator
flutter devices

# Run the app
flutter run
```

### 5. Build for release

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release
```

---

## 🧪 Running Tests

```bash
# Run all tests
flutter test

# Run unit tests
flutter test test/unit/

# Run widget tests
flutter test test/widget/
```

---

## 📦 Building

### Android APK

```bash
flutter build apk --release
```

### Android App Bundle

```bash
flutter build appbundle --release
```

---

## 📝 Additional Documentation

- [Design Document](../AI_CAMERA_DESIGN.md) - Complete architecture and feature design
- [Backend API](BACKEND_API.md) - API documentation
- [Android Setup](ANDROID_SETUP.md) - Detailed Android setup guide
- [Implementation Summary](IMPLEMENTATION_SUMMARY.md) - Technical implementation details

---

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- All contributors to this project
