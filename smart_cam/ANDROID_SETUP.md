# Android Setup Guide

## Prerequisites

1. **Android Studio** installed with Flutter plugin
2. **Android SDK** (API level 21 or higher)
3. **Flutter SDK** 3.5.0 or higher

## Step-by-Step Setup

### 1. Create Android Project Structure

Since we're starting without `flutter create`, you need to set up the Android project:

```bash
cd smart_cam

# Option A: Let Flutter generate Android project
flutter create --platforms=android .

# This will:
# - Create android/ directory with full project structure
# - Generate MainActivity.kt
# - Set up Gradle build files
# - Configure AndroidManifest.xml with camera permissions
```

### 2. Verify Android Manifest Permissions

Ensure `android/app/src/main/AndroidManifest.xml` includes:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-feature android:name="android.hardware.camera" android:required="true"/>
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false"/>
```

### 3. Update build.gradle

In `android/app/build.gradle`, verify:

```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "com.smartcam.smart_cam"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
}
```

### 4. Install Dependencies

```bash
flutter pub get
```

### 5. Run on Device/Emulator

```bash
# List available devices
flutter devices

# Run on connected device
flutter run

# Or specify device
flutter run -d <device_id>
```

## Troubleshooting

### Camera Permission Issues

If camera doesn't work:
1. Check AndroidManifest.xml has CAMERA permission
2. For Android 12+, ensure runtime permission handling
3. Test on physical device (emulator camera support varies)

### Build Errors

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build apk
```

### Missing Kotlin/Java Files

The Flutter framework will auto-generate:
- `MainActivity.kt` or `MainActivity.java`
- Application class
- Plugin registrations

## Next Steps

After basic setup works:

1. **Test Camera**: Verify camera preview displays
2. **Configure API**: Add your AI provider API key in Settings
3. **Test Analysis**: Point camera at a scene and wait for suggestions
4. **Take Photos**: Test photo capture and edit suggestions

## Development Tips

- Use `flutter run --verbose` for detailed logs
- Check Logcat for Android-specific issues
- Hot reload works for UI changes (`r` in terminal)
- Full restart needed for native code changes (`R` in terminal)
