# AI Camera - 智能拍照助手

[![Flutter](https://img.shields.io/badge/Flutter-3.19+-blue.svg)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android-green.svg)](https://www.android.com)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## 📖 项目描述

**AI Camera** 是一款基于大模型的智能拍照应用，通过实时分析取景框内容，为用户提供专业的拍摄参数建议和构图指导。

### ✨ 核心功能

- **实时场景分析**: 自动检测场景稳定性，智能触发 AI 分析
- **拍摄建议**: 提供曝光、对焦、白平衡等参数建议及构图指导
- **多模型支持**: 灵活接入 GPT-4o、Claude、Qwen-VL 等多种大模型服务商
- **智能节流**: 仅在场景大幅变化时重新分析，节省流量和电量
- **修图推荐**: 拍照后提供后期处理参数和滤镜建议
- **跨平台架构**: 优先支持 Android，预留 iOS 扩展能力

### 🎯 适用场景

- 摄影新手学习专业拍摄技巧
- 旅行时快速获得最佳拍摄参数
- 特定场景（人像、风景、美食）的优化建议
- 后期修图参数参考

---

## 🛠️ 本地开发环境要求

### 系统要求

| 操作系统 | 最低版本 | 推荐版本 |
|---------|---------|---------|
| Windows | 10 (64-bit) | 11 (64-bit) |
| macOS | 10.15 (Catalina) | 12+ (Monterey/Ventura) |
| Linux | Ubuntu 18.04+ | Ubuntu 22.04+ |

### 软件依赖

| 工具 | 最低版本 | 推荐版本 | 用途 |
|-----|---------|---------|------|
| **Flutter SDK** | 3.19.0 | 3.22.0+ | 跨平台框架 |
| **Dart SDK** | 3.3.0 | 3.4.0+ | 编程语言 |
| **Android Studio** | Hedgehog (2023.1.1) | Koala (2024.1.2)+ | IDE & 模拟器 |
| **Android SDK** | API 21 | API 34 | 开发工具包 |
| **Gradle** | 8.0 | 8.7+ | 构建工具 |
| **Git** | 2.x | 最新稳定版 | 版本控制 |

### 硬件要求

- **内存**: 最低 8GB，推荐 16GB+
- **存储**: 至少 5GB 可用空间（含模拟器）
- **处理器**: 支持虚拟化的多核 CPU

---

## 🚀 环境准备步骤

### 步骤 1: 安装 Flutter SDK

#### Windows/macOS/Linux 通用方法

```bash
# 1. 下载 Flutter SDK
# 访问 https://docs.flutter.dev/get-started/install 下载对应系统的稳定版

# 2. 解压到合适位置（示例）
# Windows: C:\src\flutter
# macOS/Linux: ~/development/flutter

# 3. 将 Flutter 添加到系统 PATH
# Windows (PowerShell):
[Environment]::SetEnvironmentVariable("Path", "$env:Path;C:\src\flutter\bin", [System.EnvironmentVariableTarget]::User)

# macOS/Linux (~/.bashrc 或 ~/.zshrc):
export PATH="$PATH:$HOME/development/flutter/bin"

# 4. 验证安装
flutter --version
```

#### 使用 Flutter Version Manager (推荐)

```bash
# 安装 fvm
dart pub global activate fvm

# 初始化项目使用的 Flutter 版本
fvm install 3.22.0
fvm use 3.22.0

# 验证
fvm flutter --version
```

### 步骤 2: 安装 Android 开发环境

#### 2.1 安装 Android Studio

1. 下载并安装 [Android Studio](https://developer.android.com/studio)
2. 启动 Android Studio，完成初始设置
3. 打开 **Settings/Preferences** → **Languages & Frameworks** → **Android SDK**

#### 2.2 配置 Android SDK

```bash
# 通过命令行安装必要的组件
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
sdkmanager "emulator" "system-images;android-34;google_apis;x86_64"

# 创建模拟器（可选）
avdmanager create avd -n Pixel_7_API_34 -k "system-images;android-34;google_apis;x86_64" -d pixel_7
```

#### 2.3 接受许可证

```bash
flutter doctor --android-licenses
# 按提示输入 'y' 接受所有许可证
```

### 步骤 3: 验证开发环境

```bash
# 运行诊断工具
flutter doctor -v
```

**期望输出示例：**

```
[✓] Flutter (Channel stable, 3.22.0, on macOS 14.5, locale zh-CN)
[✓] Android toolchain - develop for Android devices (Android SDK version 34.0.0)
[✓] Xcode - develop for iOS and macOS (if on macOS)
[✓] Chrome - develop for the web
[✓] Android Studio (version 2024.1)
[✓] VS Code (version 1.90.0)
[✓] Connected device (1 available)
[✓] Network resources

• No issues found!
```

### 步骤 4: 克隆项目并安装依赖

```bash
# 1. 进入项目目录
cd smart_cam

# 2. 如果使用 fvm 管理 Flutter 版本
fvm use

# 3. 获取 Flutter 依赖
flutter pub get

# 4. 检查项目配置
flutter doctor
```

### 步骤 5: 配置后端 API（可选，用于测试）

1. 复制配置文件模板：
```bash
cp lib/config/api_config.example.dart lib/config/api_config.dart
```

2. 编辑 `lib/config/api_config.dart`，填入你的 API 密钥：

```dart
class ApiConfig {
  static const String defaultProvider = 'openai'; // 或 'anthropic', 'qwen'
  
  static const Map<String, String> apiKeys = {
    'openai': 'YOUR_OPENAI_API_KEY',
    'anthropic': 'YOUR_ANTHROPIC_API_KEY',
    'qwen': 'YOUR_QWEN_API_KEY',
  };
  
  static const String baseUrl = 'http://localhost:8000'; // 本地开发
  // static const String baseUrl = 'https://your-production-api.com'; // 生产环境
}
```

---

## ▶️ 运行项目

### 在真机上运行

1. **启用开发者选项**（Android 手机）:
   - 设置 → 关于手机 → 连续点击"版本号"7 次
   - 设置 → 开发者选项 → 开启"USB 调试"

2. **连接设备**:
```bash
# 查看连接的设备
flutter devices

# 期望输出:
# Connected devices:
# Pixel 7 (mobile) • ABC123XYZ • android-arm64 • Android 14 (API 34)
```

3. **运行应用**:
```bash
flutter run
```

### 在模拟器上运行

```bash
# 列出可用模拟器
flutter emulators

# 启动模拟器
flutter emulators --launch <emulator_id>

# 直接运行应用到模拟器
flutter run
```

### 运行模式

```bash
# Debug 模式（默认，支持热重载）
flutter run

# Release 模式（性能优化，用于测试）
flutter run --release

# Profile 模式（性能分析）
flutter run --profile

# 指定设备
flutter run -d <device-id>

# 查看详细日志
flutter run -v
```

---

## 🧪 测试与调试

### 运行测试

```bash
# 运行所有测试
flutter test

# 运行特定测试文件
flutter test test/analysis_service_test.dart

# 生成覆盖率报告
flutter test --coverage
```

### 调试技巧

```bash
# 查看应用日志
flutter logs

# 清除构建缓存
flutter clean
flutter pub get

# 检查代码格式
flutter format .

# 静态分析
flutter analyze
```

---

## 📁 项目结构

```
smart_cam/
├── lib/
│   ├── main.dart                 # 应用入口
│   ├── config/                   # 配置文件
│   │   ├── api_config.dart       # API 配置
│   │   └── app_config.dart       # 应用配置
│   ├── models/                   # 数据模型
│   │   ├── analysis_result.dart  # 分析结果
│   │   ├── camera_params.dart    # 相机参数
│   │   └── app_settings.dart     # 应用设置
│   ├── services/                 # 业务服务
│   │   ├── analysis_service.dart # AI 分析服务
│   │   ├── api_adapter.dart      # API 适配器（多模型支持）
│   │   └── camera_service.dart   # 相机服务
│   ├── providers/                # 状态管理
│   │   ├── camera_provider.dart  # 相机状态
│   │   └── analysis_provider.dart# 分析状态
│   ├── screens/                  # 页面
│   │   ├── camera_screen.dart    # 拍照页
│   │   └── settings_screen.dart  # 设置页
│   ├── widgets/                  # 可复用组件
│   │   ├── camera_preview.dart   # 预览组件
│   │   ├── overlay_display.dart  # 覆盖层显示
│   │   └── settings_tile.dart    # 设置项
│   └── utils/                    # 工具类
│       ├── logger.dart           # 日志工具
│       └── stability_detector.dart# 稳定性检测
├── android/                      # Android 原生代码
├── ios/                          # iOS 原生代码（待实现）
├── test/                         # 测试文件
├── README.md                     # 本文档
└── AI_CAMERA_DESIGN.md          # 详细设计文档
```

---

## 🔗 相关资源

- [详细设计文档](AI_CAMERA_DESIGN.md)
- [Flutter 官方文档](https://docs.flutter.dev)
- [CameraX 文档](https://developer.android.com/training/camerax)
- [Provider 状态管理](https://pub.dev/packages/provider)

---

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

---

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

---

## 📞 联系方式

如有问题或建议，请通过以下方式联系：

- 📧 Email: your-email@example.com
- 💬 Issues: [GitHub Issues](https://github.com/your-repo/ai-camera/issues)

---

**🎉 祝您开发愉快！**
