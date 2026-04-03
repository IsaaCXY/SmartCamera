# Smart Cam - AI Camera Application

[![Flutter](https://img.shields.io/badge/Flutter-3.19+-blue.svg)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android-green.svg)](https://www.android.com)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## 📖 Project Description

**Smart Cam** is an AI-powered smart camera application that provides real-time shooting suggestions and composition guidance through large language model analysis.

### ✨ Core Features

- **Real-time Scene Analysis**: Automatically detects scene stability and triggers AI analysis
- **Shooting Suggestions**: Provides exposure, focus, white balance suggestions and composition guidance
- **Multi-model Support**: Flexibly integrates GPT-4o, Claude, Qwen-VL and other LLM providers
- **Smart Throttling**: Re-analyzes only when scenes change significantly, saving data and battery
- **Photo Editing Recommendations**: Provides post-processing parameters and filter suggestions after taking photos
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
├── src/                  # Dart source code
│   ├── main.dart         # Application entry point
│   ├── core/             # Core utilities and config
│   │   ├── config/
│   │   └── utils/
│   └── features/         # Feature modules
│       ├── analysis/     # AI analysis feature
│       ├── camera/       # Camera functionality
│       └── settings/     # App settings
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

### 1. Clone the repository

```bash
git clone <repository-url>
cd smart_cam
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run the application

```bash
flutter run
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
