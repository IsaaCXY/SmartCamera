# AI 智能拍照应用设计文档

## 1. 项目概述

### 1.1 产品定位
一款基于大模型视觉能力的智能拍照应用，核心功能是在拍照取景框内实时给出拍摄参数和构图建议，并在拍照完成后提供修图参数和滤镜建议。

### 1.2 目标平台
- **优先**: Android
- **后续**: iOS
- **技术路线**: Flutter 跨平台框架

### 1.3 核心价值
- 实时场景识别与拍摄指导
- AI 驱动的构图与参数建议
- 拍照后智能修图方案推荐
- 支持多后端大模型服务商自由切换

---

## 2. 原型设计

### 2.1 界面结构

#### 2.1.1 拍照页 (Camera Screen)
```
┌─────────────────────────────────┐
│  [设置]                    [切换相机] │
│                                 │
│         ┌─────────────┐         │
│         │             │         │
│         │   相机预览   │         │
│         │             │         │
│         │  [建议覆盖层] │         │
│         │  • ISO: 100 │         │
│         │  • 快门: 1/500│        │
│         │  • 建议: 调整角度│       │
│         └─────────────┘         │
│                                 │
│         [分析状态指示器]          │
│                                 │
│   [闪光灯] [图库] [快门] [更多]   │
└─────────────────────────────────┘
```

**关键元素**:
- **相机预览区**: 全屏显示实时画面
- **建议覆盖层**: 半透明浮层，显示拍摄参数和建议文字
- **分析状态指示器**: 显示"检测中"/"稳定"/"分析中"/"完成"状态
- **控制按钮**:
  - **闪光灯**: 循环切换 关闭/自动/开启，默认关闭
  - **图库**: 显示最近照片缩略图，点击进入图库页面
  - **快门**: 拍照并保存到本地存储
  - **设置**: 进入设置页面

#### 2.1.2 设置页 (Settings Screen)
```
┌─────────────────────────────────┐
│  ← 返回        设置              │
├─────────────────────────────────┤
│  后端配置                        │
│  ├─ API Provider: [OpenAI ▼]   │
│  ├─ API Key: ****************  │
│  ├─ Endpoint: [自定义]          │
│  └─ [测试连接]                  │
├─────────────────────────────────┤
│  分析设置                        │
│  ├─ 自动分析: [✓]               │
│  ├─ 稳定性阈值: [中等 ▼]        │
│  ├─ 更新频率: 场景变化时         │
│  └─ 最大请求间隔: [5 秒]          │
├─────────────────────────────────┤
│  显示设置                        │
│  ├─ 建议文字大小: [中 ▼]        │
│  ├─ 主题: [跟随系统 ▼]          │
│  └─ 语言: [中文 ▼]              │
├─────────────────────────────────┤
│  关于                            │
│  ├─ 版本号: 1.0.0              │
│  └─ 隐私政策                    │
└─────────────────────────────────┘
```

### 2.2 用户流程

#### 2.2.1 拍照和分析流程

```
启动应用
   ↓
拍照页 (默认)
   ↓
[后台运行] 实时场景稳定性检测
   ↓
场景稳定？──否──→ 继续检测
   ↓是
调用大模型 API (带节流控制)
   ↓
显示分析结果 (参数 + 建议)
   ↓
用户调整构图？──是──→ 检测到大幅变化 → 重新分析
   ↓否
用户点击快门
   ↓
拍照并保存到本地存储
   ├─ 生成缩略图 (200x200)
   ├─ 保存元数据 (JSON)
   └─ 关联 AI 分析结果
   ↓
显示拍摄成功对话框
   ├─ 显示照片 ID 和时间
   └─ 显示 AI 修图建议
   ↓
用户选择
   ├─ [OK] → 返回拍照页
   └─ [查看照片] → 进入照片详情页
```

#### 2.2.2 照片查看流程

```
从拍照页点击图库缩略图
   ↓
进入照片列表页
   ├─ 网格布局展示所有照片
   ├─ 每张照片显示缩略图和时间
   └─ 有 AI 分析的照片显示标记
   ↓
用户点击照片
   ↓
进入照片详情页
   ├─ 全屏显示照片 (支持缩放)
   ├─ 显示拍摄信息 (时间、参数)
   ├─ 显示完整的 AI 分析结果
   │   ├─ 💡 拍摄建议
   │   ├─ 📷 相机参数
   │   ├─ 🎨 滤镜建议
   │   └─ 🔧 修图参数
   └─ 操作按钮
       ├─ [分享] - 即将推出
       └─ [删除] - 删除照片和元数据
   ↓
用户操作
   ├─ [返回] → 回到列表页
   └─ [删除] → 确认后删除并返回
```

---

## 3. 技术栈

### 3.1 前端技术栈

| 组件 | 技术选型 | 版本 | 说明 |
|------|---------|------|------|
| **框架** | Flutter | 3.19+ | 跨平台 UI 框架 |
| **状态管理** | Provider | 6.1+ | 轻量级响应式状态管理 |
| **相机引擎** | camera | 0.10.5+ | 相机功能封装 |
| **图像处理** | image | 4.1.7+ | 缩略图生成和图像处理 |
| **存储路径** | path_provider | 2.1.2+ | 获取应用文档目录 |
| **路径处理** | path | 1.8.3+ | 文件路径操作 |
| **HTTP 客户端** | http | 1.2.0+ | API 请求 |
| **日志系统** | logger | 2.2.0+ | 结构化日志输出 |

### 3.2 后端技术栈 (参考实现)

| 组件 | 技术选型 | 说明 |
|------|---------|------|
| **框架** | FastAPI | Python 异步 Web 框架 |
| **大模型接入** | LangChain | 统一多模型接口 |
| **支持的模型** | GPT-4o, Claude 3, Qwen-VL, Gemini | 可扩展 |
| **图像处理** | Pillow | 图片预处理 |
| **部署** | Docker + Nginx | 容器化部署 |

### 3.3 开发环境要求

- **Flutter SDK**: 3.19.0+
- **Dart**: 3.3.0+
- **Android Studio**: Hedgehog+
- **Android SDK**: API 21+ (最低), API 33+ (推荐)
- **Gradle**: 8.0+

---

## 4. 架构设计

### 4.1 整体架构图

```
┌─────────────────────────────────────────────────────────┐
│                      Presentation Layer                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │
│  │ CameraScreen│  │SettingsScreen│  │PhotoGalleryPage│   │
│  │             │  │              │  │PhotoDetailPage│    │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘      │
│         │                │                │              │
│  ┌──────▼────────────────▼────────────────▼──────┐      │
│  │              State Management (Provider)       │      │
│  │  - CameraState  - AnalysisState                │      │
│  │  - SettingsState  - PhotoStorageState          │      │
│  └─────────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│                      Business Logic Layer                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │
│  │CameraService│  │AnalysisService│ │PhotoStorageService││
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘      │
│         │                │                │              │
│  ┌──────▼──────┐  ┌──────▼──────┐  ┌──────▼──────┐      │
│  │StabilityDetector│ │APIAdapter │  │ThumbnailGen │      │
│  └─────────────┘  └──────┬──────┘  └─────────────┘      │
│                          │                               │
│                 ┌────────▼────────┐                      │
│                 │ Model Providers │                      │
│                 │ - OpenAI        │                      │
│                 │ - Claude        │                      │
│                 │ - Qwen          │                      │
│                 │ - Custom        │                      │
│                 └─────────────────┘                      │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│                      Platform Layer                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │
│  │  Android    │  │    iOS      │  │   Web       │      │
│  │  (CameraX)  │  │ (AVFoundation)│  │ (getUserMedia)│   │
│  │  FlashMode  │  │  FlashMode  │  │              │      │
│  └─────────────┘  └─────────────┘  └─────────────┘      │
└─────────────────────────────────────────────────────────┘
```

### 4.2 分层职责

#### 4.2.1 Presentation Layer (表现层)
- **职责**: UI 渲染、用户交互、状态展示
- **组件**: Screens, Widgets, Themes
- **特点**: 无业务逻辑，纯展示和事件触发

#### 4.2.2 Business Logic Layer (业务逻辑层)
- **职责**: 核心业务处理、状态管理、服务协调
- **组件**: Services, Repositories, Managers
- **特点**: 可测试、可复用、平台无关

#### 4.2.3 Platform Layer (平台层)
- **职责**: 原生功能调用、硬件访问
- **组件**: Platform Channels, Native Plugins
- **特点**: 平台特定代码隔离

### 4.3 目录结构

```
lib/
├── main.dart                     # 应用入口
├── core/
│   ├── config/
│   │   └── app_config.dart       # 应用配置常量
│   └── utils/
│       └── logger.dart           # 日志工具
├── features/
│   ├── camera/
│   │   ├── presentation/
│   │   │   ├── camera_service.dart      # 相机服务
│   │   │   └── pages/
│   │   │       └── camera_page.dart     # 拍照页
│   ├── analysis/
│   │   ├── domain/
│   │   │   ├── analysis_result.dart     # 分析结果模型
│   │   │   └── analysis_repository.dart # 分析仓库接口
│   │   ├── data/
│   │   │   └── analysis_api_repository.dart # API 分析实现
│   │   └── presentation/
│   │       └── analysis_service.dart    # 分析服务
│   ├── photo/                     # 照片管理模块 (新增)
│   │   ├── domain/
│   │   │   └── photo_metadata.dart      # 照片元数据模型
│   │   └── presentation/
│   │       ├── photo_storage_service.dart # 照片存储服务
│   │       └── pages/
│   │           ├── photo_gallery_page.dart  # 照片列表页
│   │           └── photo_detail_page.dart   # 照片详情页
│   └── settings/
│       ├── domain/
│       │   └── app_settings.dart      # 设置数据模型
│       └── presentation/
│           ├── settings_service.dart  # 设置服务
│           └── pages/
│               └── settings_page.dart  # 设置页
└── pubspec.yaml                  # 依赖配置
```

---

## 5. 代码设计

### 5.1 核心类设计

#### 5.1.1 数据模型 (Models)

```dart
// 分析结果模型
class AnalysisResult {
  final String shootingAdvice;        // 拍摄建议
  final Map<String, dynamic> cameraParams;     // 相机参数
  final List<String> filterSuggestions; // 滤镜建议
  final Map<String, dynamic> editParams;   // 修图参数

  // 工厂方法从 JSON 创建
  factory AnalysisResult.fromJson(Map<String, dynamic> json);

  // 转换为 JSON
  Map<String, dynamic> toJson();
}

// 照片元数据模型 (新增)
class PhotoMetadata {
  final String id;                    // 唯一标识 (格式: photo_YYYYMMDD_HHMMSS_seq)
  final String originalPath;          // 原图路径
  final String thumbnailPath;         // 缩略图路径 (200x200)
  final DateTime capturedAt;          // 拍摄时间
  final AnalysisResult? analysisResult; // AI 分析结果
  final Map<String, dynamic>? cameraSettings; // 相机设置 (闪光灯等)

  // 从 JSON 创建
  factory PhotoMetadata.fromJson(Map<String, dynamic> json);

  // 转换为 JSON
  Map<String, dynamic> toJson();
}
```

#### 5.1.2 服务层 (Services)

```dart
// 照片存储服务 (新增)
class PhotoStorageService extends ChangeNotifier {
  List<PhotoMetadata> _photos = [];

  // 初始化存储目录和加载元数据
  Future<void> initialize();

  // 保存照片并返回元数据
  Future<PhotoMetadata> savePhoto(
    XFile photo,
    AnalysisResult? analysisResult, {
    Map<String, dynamic>? cameraSettings,
  });

  // 获取所有照片（按时间倒序）
  List<PhotoMetadata> get photos;

  // 根据 ID 获取照片
  PhotoMetadata? getPhotoById(String id);

  // 删除照片
  Future<void> deletePhoto(String id);

  // 获取总存储大小
  Future<int> getTotalStorageSize();

  // 清空所有照片（谨慎使用）
  Future<void> clearAllPhotos();

  // 私有方法：生成缩略图
  Future<String> _generateThumbnail(String originalPath);

  // 私有方法：加载/保存元数据 JSON
  Future<void> _loadMetadata();
  Future<void> _saveMetadata();
}

// 相机服务
class CameraService extends ChangeNotifier {
  CameraController? _controller;
  FlashMode _flashMode = FlashMode.off;

  // 初始化相机，设置默认闪光灯为关闭
  Future<void> initialize();

  // 设置闪光灯模式 (新增)
  Future<void> setFlashMode(FlashMode mode);

  // 获取当前闪光灯模式
  FlashMode get flashMode;

  // 拍照并保存到存储服务（修改）
  Future<PhotoMetadata?> takePhoto(
    PhotoStorageService storageService, {
    AnalysisResult? analysisResult,
  });

  // 捕获帧用于分析
  Future<Uint8List?> captureFrameForAnalysis();

  // 计算帧差异用于稳定性检测
  double calculateFrameDifference(Uint8List current, Uint8List previous);
}

// 分析服务 - 核心业务逻辑
class AnalysisService {
  final ApiAdapter _apiAdapter;
  final StabilityDetector _stabilityDetector;

  // 单次分析
  Future<AnalysisResult> analyzeScene(Uint8List image);

  // 持续监测 (自动触发)
  void startMonitoring(Stream<Uint8List> imageStream);
  void stopMonitoring();
  
  // 获取修图建议
  Future<EditingParams> getEditingSuggestions(Uint8List photo);
}

// API 适配器 - 支持多后端
abstract class ApiAdapter {
  Future<AnalysisResult> analyze(ImageData image);
  Future<EditingParams> suggestEditing(ImageData photo);
}

// 具体实现：OpenAI
class OpenAIAdapter implements ApiAdapter { ... }

// 具体实现：Claude
class ClaudeAdapter implements ApiAdapter { ... }

// 具体实现：Qwen
class QwenAdapter implements ApiAdapter { ... }

// 工厂方法：根据配置返回对应适配器
ApiAdapter createAdapter(ApiConfig config);
```

#### 5.1.3 状态管理 (Providers)

```dart
// 相机状态
class CameraProvider extends ChangeNotifier {
  CameraController? _controller;
  bool _isReady = false;
  bool _isTakingPhoto = false;
  
  // 公开状态
  bool get isReady => _isReady;
  bool get isTakingPhoto => _isTakingPhoto;
  
  // 初始化相机
  Future<void> initialize();
  
  // 拍照
  Future<XFile?> takePhoto();
  
  // 释放资源
  Future<void> dispose();
}

// 分析状态
class AnalysisProvider extends ChangeNotifier {
  AnalysisStatus _status = AnalysisStatus.idle;
  AnalysisResult? _currentResult;
  String? _errorMessage;
  
  // 状态枚举
  enum AnalysisStatus { idle, detecting, analyzing, completed, error }
  
  // 触发分析
  Future<void> triggerAnalysis(Uint8List image);
  
  // 重置
  void reset();
}
```

### 5.2 关键算法设计

#### 5.2.1 场景稳定性检测

```dart
class StabilityDetector {
  Uint8List? _lastFrame;
  DateTime? _lastStableTime;
  
  // 检测当前帧是否稳定
  bool isStable(Uint8List currentFrame) {
    if (_lastFrame == null) {
      _lastFrame = currentFrame;
      return false;
    }
    
    // 计算直方图差异
    double difference = calculateHistogramDifference(
      _lastFrame!, 
      currentFrame
    );
    
    // 差异小于阈值则认为稳定
    bool stable = difference < STABILITY_THRESHOLD;
    
    if (stable) {
      _lastStableTime = DateTime.now();
    }
    
    _lastFrame = currentFrame;
    return stable;
  }
  
  // 判断是否需要重新分析 (场景大幅变化)
  bool shouldReanalyze(Uint8List currentFrame) {
    if (_lastFrame == null) return true;
    
    double difference = calculateHistogramDifference(
      _lastFrame!, 
      currentFrame
    );
    
    // 差异大于重新分析阈值
    return difference > REANALYZE_THRESHOLD;
  }
  
  // 简化版直方图差异计算 (实际可使用更高效的算法)
  double calculateHistogramDifference(
    Uint8List frame1, 
    Uint8List frame2
  ) {
    // 采样部分像素点计算平均差异
    int sampleSize = 100;
    int totalDiff = 0;
    
    for (int i = 0; i < sampleSize; i++) {
      int index = (i * frame1.length ~/ sampleSize);
      totalDiff += (frame1[index] - frame2[index]).abs();
    }
    
    return totalDiff / sampleSize;
  }
}
```

#### 5.2.2 智能节流策略

```dart
class ThrottledAnalyzer {
  DateTime? _lastAnalyzeTime;
  bool _isAnalyzing = false;
  
  // 最小分析间隔 (毫秒)
  static const int MIN_INTERVAL = 5000;
  
  // 尝试触发分析
  Future<AnalysisResult?> tryAnalyze(
    Uint8List image,
    Future<AnalysisResult> Function(Uint8List) analyzeFn
  ) async {
    // 正在分析中，跳过
    if (_isAnalyzing) {
      Logger.d('分析进行中，跳过本次请求');
      return null;
    }
    
    // 检查时间间隔
    if (_lastAnalyzeTime != null) {
      int elapsed = DateTime.now().difference(_lastAnalyzeTime!).inMilliseconds;
      if (elapsed < MIN_INTERVAL) {
        Logger.d('距离上次分析仅${elapsed}ms，跳过');
        return null;
      }
    }
    
    // 执行分析
    _isAnalyzing = true;
    try {
      var result = await analyzeFn(image);
      _lastAnalyzeTime = DateTime.now();
      return result;
    } finally {
      _isAnalyzing = false;
    }
  }
}
```

### 5.3 扩展性设计

#### 5.3.1 新增大模型服务商

只需实现 `ApiAdapter` 接口:

```dart
class NewModelAdapter implements ApiAdapter {
  final String baseUrl;
  final String apiKey;
  
  @override
  Future<AnalysisResult> analyze(ImageData image) async {
    // 实现特定模型的 API 调用逻辑
    // ...
  }
  
  @override
  Future<EditingParams> suggestEditing(ImageData photo) async {
    // 实现修图建议逻辑
    // ...
  }
}

// 在工厂方法中注册
ApiAdapter createAdapter(ApiConfig config) {
  switch (config.provider) {
    case 'openai': return OpenAIAdapter(config);
    case 'claude': return ClaudeAdapter(config);
    case 'qwen': return QwenAdapter(config);
    case 'newmodel': return NewModelAdapter(config); // 新增
    default: throw Exception('未知提供商');
  }
}
```

#### 5.3.2 新增平台支持

通过 Flutter 的 Platform Channel 机制:

```dart
// 定义平台接口
abstract class PlatformCamera {
  Future<void> initialize();
  Future<Uint8List> captureFrame();
  Future<void> release();
}

// Android 实现
class AndroidCamera implements PlatformCamera { ... }

// iOS 实现 (待实现)
class IOSCamera implements PlatformCamera { ... }

// 工厂方法
PlatformCamera createPlatformCamera() {
  if (Platform.isAndroid) {
    return AndroidCamera();
  } else if (Platform.isIOS) {
    return IOSCamera(); // 待实现
  }
  throw Exception('不支持的平台');
}
```

---

## 6. 核心流程设计

### 6.1 启动流程

```
main()
  ↓
初始化日志系统
  ↓
加载本地配置 (SharedPreferences)
  ↓
创建 Services 单例
  ↓
初始化 Providers
  ↓
启动 MaterialApp
  ↓
导航到拍照页
  ↓
自动初始化相机
```

### 6.2 实时分析流程

```
[定时任务] 每 200ms 捕获预览帧
  ↓
StabilityDetector.isStable(frame)
  ↓
不稳定 → 更新状态为"检测中" → 等待下一帧
  ↓
稳定且超过最小间隔
  ↓
更新状态为"分析中"
  ↓
ThrottledAnalyzer.tryAnalyze()
  ↓
调用 AnalysisService.analyzeScene()
  ↓
选择配置的 API Adapter
  ↓
压缩图片 (降低分辨率减少流量)
  ↓
发送 HTTP POST 请求
  ↓
接收 JSON 响应
  ↓
解析为 AnalysisResult
  ↓
更新 AnalysisProvider 状态
  ↓
UI 自动刷新显示建议
  ↓
等待场景变化 (大幅移动)
  ↓
检测到变化 → 重新开始流程
```

### 6.3 拍照及后期流程

```
用户点击快门按钮
  ↓
CameraProvider.takePhoto()
  ↓
暂停预览和分析 (避免干扰)
  ↓
调用原生相机拍照
  ↓
保存照片到本地
  ↓
恢复预览
  ↓
自动截取刚拍的照片
  ↓
调用 AnalysisService.getEditingSuggestions()
  ↓
发送到大模型获取修图建议
  ↓
显示结果页:
  - 照片预览
  - 修图参数 (曝光、对比度、饱和度等)
  - 滤镜推荐
  - [编辑] [保存] [分享] 按钮
```

### 6.4 错误处理流程

```
任何异步操作
  ↓
try-catch 包裹
  ↓
发生异常
  ↓
记录详细日志 (包含堆栈)
  ↓
更新状态为 Error
  ↓
显示友好错误提示 (非技术术语)
  ↓
提供重试选项
  ↓
如果是网络错误，检查连接状态
  ↓
如果是 API 错误，检查配置有效性
```

---

## 7. 待完成项

### 7.1 MVP 已完成功能 ✓

#### 基础功能
- [x] Flutter 项目基础架构搭建
- [x] 相机预览和控制 (Android)
- [x] 场景稳定性检测算法
- [x] 多后端 API 适配器框架
- [x] 分析结果数据模型
- [x] 设置页面和配置管理
- [x] 建议覆盖层 UI
- [x] 状态管理和通知机制
- [x] 日志系统和错误处理
- [x] 基础文档

#### 照片管理功能 (新增)
- [x] **PhotoMetadata 数据模型** - 照片元数据管理
- [x] **PhotoStorageService** - 照片存储服务
  - 照片保存到应用文档目录
  - 自动生成 200x200 缩略图
  - JSON 元数据持久化
  - 照片列表查询和管理
- [x] **照片列表页面** (PhotoGalleryPage)
  - 3 列网格布局展示
  - 显示拍摄时间和 AI 分析标识
  - 空状态提示
- [x] **照片详情页面** (PhotoDetailPage)
  - 全屏照片查看（支持缩放）
  - 完整的 AI 分析结果展示
  - 拍摄信息（时间、参数）
  - 删除和分享功能
- [x] **拍照页增强**
  - 快门按钮旁显示最新照片缩略图
  - 点击缩略图进入图库
  - 拍照成功后显示详情入口

#### 相机控制功能 (新增)
- [x] **闪光灯控制**
  - 三种模式：关闭 / 自动 / 开启
  - 默认设置为关闭状态
  - 循环切换按钮，图标正确显示
  - 解决频繁闪烁问题
- [x] **相机服务增强**
  - 集成 PhotoStorageService
  - 拍照后自动保存并关联 AI 分析结果
  - 保存相机设置（闪光灯模式等）

#### 数据持久化 (新增)
- [x] **本地存储**
  - 照片文件存储
  - 缩略图存储
  - 元数据 JSON 存储
  - 应用重启后数据持久化
- [x] **存储管理**
  - 总存储大小统计
  - 批量删除功能
  - 存储空间监控

### 7.2 短期优化 (1-2 周)

- [ ] **性能优化**
  - [ ] 图像压缩算法优化 (WebP 格式)
  - [ ] 异步帧处理避免阻塞 UI
  - [ ] 内存泄漏检测和修复
  
- [ ] **用户体验**
  - [ ] 添加动画过渡效果
  - [ ] 优化建议文字排版和可读性
  - [ ] 添加震动反馈
  - [ ] 支持横竖屏切换
  
- [ ] **测试覆盖**
  - [ ] 单元测试 (Services, Utils)
  - [ ] Widget 测试 (关键组件)
  - [ ] 集成测试 (完整流程)
  - [ ] 真机测试 (不同 Android 版本)

### 7.3 中期功能 (1-2 月)

- [ ] **iOS 平台支持**
  - [ ] AVFoundation 相机实现
  - [ ] iOS 特定权限处理
  - [ ] 适配 iPhone 刘海屏和灵动岛
  
- [ ] **高级分析功能**
  - [ ] 支持更多场景类型 (人像、风景、夜景等)
  - [ ] 实时人脸检测和美化建议
  - [ ] 物体识别和追踪
  - [ ] 光线条件分析和闪光灯建议
  
- [ ] **修图集成**
  - [ ] Android: 调用第三方修图 APP (Snapseed, Lightroom)
  - [ ] iOS: 调用系统编辑器的参数预设
  - [ ] 内置简易编辑器 (基础调整)
  - [ ] 一键应用推荐参数
  
- [ ] **后端优化**
  - [ ] 流式响应支持 (逐步显示建议)
  - [ ] 缓存常见场景结果
  - [ ] 批量请求优化
  - [ ] 监控和日志分析

### 7.4 长期规划 (3-6 月)

- [ ] **端侧智能**
  - [ ] 集成 TensorFlow Lite 模型
  - [ ] 离线场景分类
  - [ ] 端侧预筛选减少 API 调用
  
- [ ] **社交和分享**
  - [ ] 拍摄参数水印
  - [ ] 前后对比图生成
  - [ ] 分享到社交媒体
  - [ ] 用户作品社区
  
- [ ] **个性化**
  - [ ] 用户偏好学习
  - [ ] 自定义建议模板
  - [ ] 历史数据分析
  - [ ] 摄影技巧推送
  
- [ ] **商业化**
  - [ ] 高级滤镜订阅
  - [ ] 专业参数解锁
  - [ ] 云端存储同步
  - [ ] 企业定制版本

### 7.5 技术债务

- [ ] 代码重构机会
  - [ ] 提取公共 Widget 组件
  - [ ] 统一错误处理中间件
  - [ ] 优化依赖注入方式
  
- [ ] 文档完善
  - [ ] API 接口详细文档
  - [ ] 开发者贡献指南
  - [ ] 用户手册
  
- [ ] 安全加固
  - [ ] API Key 加密存储
  - [ ] 网络请求证书绑定
  - [ ] 隐私数据脱敏

---

## 8. 附录

### 8.1 后端 API 规范

#### 8.1.1 场景分析接口

**请求**:
```http
POST /api/v1/analyze
Content-Type: multipart/form-data

{
  "image": <binary>,
  "mode": "shooting",  // shooting | editing
  "context": {
    "time": "2024-01-01T12:00:00Z",
    "location": "outdoor",
    "user_level": "beginner"
  }
}
```

**响应**:
```json
{
  "success": true,
  "data": {
    "scene_type": "sunset_landscape",
    "params": {
      "iso": 100,
      "shutter_speed": "1/500",
      "aperture": "f/8",
      "exposure_compensation": "-0.3",
      "white_balance": "cloudy",
      "focus_mode": "single"
    },
    "suggestions": [
      "降低曝光以保留天空细节",
      "使用三分法构图，将地平线放在下三分之一处",
      "寻找前景物体增加层次感"
    ],
    "confidence": 0.92
  },
  "message": "分析成功"
}
```

#### 8.1.2 修图建议接口

**请求**:
```http
POST /api/v1/suggest-editing
Content-Type: multipart/form-data

{
  "image": <binary>,
  "original_params": {...},  // 可选，拍摄时的参数
  "style_preference": "natural"  // natural | vibrant | moody
}
```

**响应**:
```json
{
  "success": true,
  "data": {
    "adjustments": {
      "exposure": "+0.3",
      "contrast": "+10",
      "highlights": "-20",
      "shadows": "+15",
      "whites": "+5",
      "blacks": "-10",
      "saturation": "+8",
      "vibrance": "+12",
      "temperature": "+5",
      "tint": "-2"
    },
    "filters": [
      {"name": "Golden Hour", "intensity": 0.6},
      {"name": "Clarity Boost", "intensity": 0.4}
    ],
    "steps": [
      "先调整曝光和高光，恢复天空细节",
      "提升阴影和黑色色阶，增强暗部层次",
      "微调白平衡使色调更温暖",
      "应用轻度金色时刻滤镜"
    ]
  }
}
```

### 8.2 性能指标目标

| 指标 | 目标值 | 测量方式 |
|------|--------|----------|
| 冷启动时间 | < 2 秒 | 点击图标到相机预览显示 |
| 稳定性检测延迟 | < 100ms | 帧捕获到状态更新 |
| API 响应时间 (P95) | < 3 秒 | 请求发送到结果接收 |
| 内存占用 | < 150MB | 运行时峰值内存 |
| 电量消耗 | < 5%/小时 | 连续使用测试 |
| 崩溃率 | < 0.1% | 线上监控 |

### 8.3 兼容性矩阵

| Android 版本 | 支持程度 | 备注 |
|-------------|---------|------|
| API 21 (5.0) | ⚠️ 基础支持 | 部分新功能不可用 |
| API 24 (7.0) | ✓ 完全支持 | 推荐最低版本 |
| API 29 (10.0) | ✓ 完全支持 | 优化最佳 |
| API 33 (13.0) | ✓ 完全支持 | 最新特性 |

| 设备类型 | 支持程度 | 备注 |
|---------|---------|------|
| 手机 | ✓ 完全支持 | 主要目标设备 |
| 平板 | ✓ 支持 | 布局自适应 |
| 折叠屏 | ⚠️ 部分支持 | 需优化展开态布局 |

---

## 9. 新增功能详细说明 (v1.1.0)

### 9.1 照片存储系统

#### 9.1.1 存储架构

```
应用文档目录/
├── photos/                           # 原始照片
│   └── photo_20260407_143022_001.jpg
├── thumbnails/                       # 缩略图 (200x200)
│   └── photo_20260407_143022_001_thumb.jpg
└── metadata.json                     # 照片元数据索引
```

#### 9.1.2 照片 ID 生成规则

- **格式**: `photo_YYYYMMDD_HHMMSS_seq`
- **示例**: `photo_20260407_143022_001`
- **组成部分**:
  - `photo`: 固定前缀
  - `20260407`: 拍摄日期 (YYYYMMDD)
  - `143022`: 拍摄时间 (HHMMSS)
  - `001`: 序列号 (3位数字，自动递增)

#### 9.1.3 元数据结构

```json
[
  {
    "id": "photo_20260407_143022_001",
    "originalPath": "/data/photos/photo_20260407_143022_001.jpg",
    "thumbnailPath": "/data/thumbnails/photo_20260407_143022_001_thumb.jpg",
    "capturedAt": "2026-04-07T14:30:22.123Z",
    "analysisResult": {
      "shooting_advice": "建议降低曝光补偿以保留天空细节",
      "camera_params": {
        "iso": 100,
        "shutter_speed": "1/500"
      },
      "filter_suggestions": ["自然", "鲜艳"],
      "edit_params": {
        "exposure": -0.3,
        "contrast": 10
      }
    },
    "cameraSettings": {
      "flash_mode": "FlashMode.off"
    }
  }
]
```

### 9.2 闪光灯控制系统

#### 9.2.1 闪光灯模式

| 模式 | 图标 | 说明 | 适用场景 |
|------|------|------|----------|
| **关闭** | `Icons.flash_off` | 不使用闪光灯 | 日光、明亮环境 |
| **自动** | `Icons.flash_auto` | 根据光线自动决定 | 日常拍摄 |
| **开启** | `Icons.flash_on` | 强制使用闪光灯 | 逆光、暗光环境 |

#### 9.2.2 实现细节

```dart
// 初始化时默认关闭
await _controller!.setFlashMode(FlashMode.off);

// 用户循环切换模式
FlashMode.off → FlashMode.auto → FlashMode.always → FlashMode.off

// 拍照时保存闪光灯状态
cameraSettings: {
  'flash_mode': _flashMode.toString()
}
```

### 9.3 图库功能

#### 9.3.1 照片列表页 (PhotoGalleryPage)

**布局**: 3 列网格布局
**功能**:
- 显示所有已拍摄照片的缩略图
- 每张照片显示拍摄时间
- 有 AI 分析的照片显示蓝色星星图标
- 点击照片进入详情页
- 空状态友好提示

**时间显示规则**:
- 今天: 显示时间 (如: 14:30)
- 昨天: 显示 "Yesterday"
- 7 天内: 显示 "X days ago"
- 其他: 显示日期 (如: 4/7)

#### 9.3.2 照片详情页 (PhotoDetailPage)

**页面组成**:
1. **全屏照片**: 支持双指缩放
2. **拍摄信息**:
   - 拍摄时间
   - 照片 ID
   - 相机设置 (闪光灯等)
3. **AI 分析结果**:
   - 💡 拍摄建议
   - 📷 相机参数
   - 🎨 滤镜建议
   - 🔧 修图参数
4. **操作按钮**:
   - 分享 (即将推出)
   - 删除 (带确认对话框)

### 9.4 拍照页增强

#### 9.4.1 控制按钮布局

```
┌─────────────────────────────────────┐
│  [闪光灯]  [图库]  [快门]           │
│   (48x48)  (48x48)  (72x72)         │
└─────────────────────────────────────┘
```

#### 9.4.2 缩略图显示逻辑

- 有照片: 显示最新照片的圆形缩略图
- 无照片: 显示相册图标占位符
- 点击后: 导航到照片列表页

#### 9.4.3 拍照流程更新

```dart
// 旧流程 (已废弃)
final photo = await cameraService.takePhoto();
_showPhotoResult(photo.path);

// 新流程 (当前实现)
final metadata = await cameraService.takePhoto(
  storageService,
  analysisResult: currentAnalysisResult,
);
_showPhotoResult(metadata);
```

### 9.5 技术实现要点

#### 9.5.1 缩略图生成

```dart
// 使用 image 包生成缩略图
img.Image original = img.decodeImage(bytes);
img.Image thumbnail = img.copyResize(
  original,
  width: 200,
  height: 200,
  interpolation: img.Interpolation.linear,
);
// 编码为 JPEG，质量 85%
final jpg = img.encodeJpg(thumbnail, quality: 85);
```

#### 9.5.2 字符串插值注意事项

```dart
// ❌ 错误写法
'${prefix}_$dateStr_${sequence}'  // $dateStr_ 会被解析为变量名

// ✅ 正确写法
'${prefix}_${dateStr}_${sequence}' // 使用 ${} 明确变量边界
```

#### 9.5.3 网络配置

中国大陆用户需要配置镜像源：

```bash
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
```

### 9.6 使用指南

#### 9.6.1 首次使用

1. 启动应用，授予相机和存储权限
2. 等待相机初始化完成
3. 确认闪光灯图标显示为"关闭"状态
4. 开始拍照，照片会自动保存到应用存储

#### 9.6.2 拍照建议

1. **调整构图**: 观察 AI 建议覆盖层的拍摄参数
2. **设置闪光灯**: 根据环境光线调整闪光灯模式
3. **等待稳定**: 等待场景稳定后 AI 会自动分析
4. **点击快门**: 拍照后可以查看详情或继续拍摄

#### 9.6.3 查看照片

1. 点击快门按钮右侧的圆形缩略图
2. 浏览照片列表，点击查看详情
3. 在详情页可以查看完整的 AI 分析结果
4. 不需要的照片可以删除

#### 9.6.4 数据管理

- **查看存储大小**: 在设置中查看总存储占用
- **删除照片**: 在详情页点击删除按钮
- **清空所有**: 在设置中选择"清空所有照片"（谨慎操作）

---

## 10. 版本历史

| 版本 | 日期 | 变更内容 |
|------|------|---------|
| 0.1.0 | 2024-01 | 初始设计文档，完成架构设计 |
| 1.0.0 | 2024-01 | MVP 发布，Android 平台基础功能 |
| 1.1.0 | 2026-04 | **照片管理和闪光灯控制功能** |
| | | ✅ 新增照片本地存储系统 |
| | | ✅ 新增照片列表和详情页 |
| | | ✅ 新增闪光灯控制功能 |
| | | ✅ 修复频繁闪烁问题 |
| | | ✅ 完善文档和使用指南 |

---

*文档最后更新：2026 年 4 月 7 日*
*维护者：开发团队*
*文档版本：1.1.0*
