// Camera page with real-time AI suggestions overlay.
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../camera_service.dart';
import '../../../analysis/presentation/analysis_service.dart';
import '../../../analysis/presentation/analysis_coordinator.dart';
import '../../../settings/presentation/settings_service.dart' hide AppLogger;
import '../../../photo/presentation/photo_storage_service.dart';
import '../../../photo/domain/photo_metadata.dart';
import '../../../../core/utils/logger.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  Timer? _frameTimer;
  double _shutterScale = 1.0;

  @override
  void initState() {
    super.initState();
    _setSystemUIOverlayStyle();
    _startFrameMonitoring();
  }

  /// 设置系统栏样式为沉浸式
  void _setSystemUIOverlayStyle() {
    // 隐藏状态栏和导航栏，实现完全全屏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    // 恢复系统栏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  /// Start monitoring frames for stability and analysis.
  void _startFrameMonitoring() {
    // Check frames every 500ms
    _frameTimer =
        Timer.periodic(const Duration(milliseconds: 1000), (timer) async {
      try {
        final coordinator = context.read<AnalysisCoordinator>();
        final analysisService = context.read<AnalysisService>();
        final settingsService = context.read<SettingsService>();
        final cameraService = context.read<CameraService>();

        if (!settingsService.settings.enableAutoAnalysis) {
          return;
        }

        // Capture current frame
        final currentFrame = await cameraService.captureFrameForAnalysis();
        if (currentFrame == null) {
          return;
        }

        // Process frame (calculates difference, updates stability and scene change)
        await coordinator.processFrame(currentFrame);

        // If conditions are met, trigger analysis
        if (coordinator.shouldAnalyze) {
          await analysisService.analyzeIfReady(currentFrame);
        }
      } catch (e) {
        AppLogger.e('Frame monitoring error', 'CameraPage', e);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 使用全屏黑色背景，移除 Scaffold 以避免安全区域边距
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          _buildCameraPreview(),

          // AI suggestions overlay
          _buildOverlay(),

          // Settings button (top right)
          _buildSettingsButton(),

          // Controls (bottom)
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Consumer<CameraService>(
      builder: (context, cameraService, child) {
        if (!cameraService.isInitialized || cameraService.controller == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return CameraPreview(cameraService.controller!);
      },
    );
  }

  Widget _buildOverlay() {
    return Consumer2<AnalysisService, CameraService>(
      builder: (context, analysisService, cameraService, child) {
        final result = analysisService.currentResult;

        if (result == null) {
          // 在 debug 模式下也显示 debug 信息
          if (kDebugMode) {
            return _buildDebugOverlay(analysisService, cameraService);
          }
          return const SizedBox.shrink();
        }

        return Positioned(
          top: 50,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Debug info (仅 debug 模式显示)
                if (kDebugMode) ...[
                  _buildDebugInfo(analysisService, cameraService),
                  const SizedBox(height: 8),
                ],

                // Shooting advice
                Text(
                  '💡 ${result.shootingAdvice}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),

                // Camera parameters
                if (result.cameraParams.isNotEmpty) ...[
                  Text(
                    '📷 Parameters:',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatParams(result.cameraParams),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],

                // Filter suggestions
                if (result.filterSuggestions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '🎨 Filters: ${result.filterSuggestions.join(", ")}',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 50,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Flash button
          _buildFlashButton(),

          // Shutter button
          _buildShutterButton(),

          // Gallery thumbnail button
          _buildGalleryButton(),
        ],
      ),
    );
  }

  Widget _buildFlashButton() {
    return Consumer<CameraService>(
      builder: (context, cameraService, child) {
        IconData icon;
        switch (cameraService.flashMode) {
          case FlashMode.off:
            icon = Icons.flash_off;
            break;
          case FlashMode.auto:
            icon = Icons.flash_auto;
            break;
          case FlashMode.always:
            icon = Icons.flash_on;
            break;
          default:
            icon = Icons.flash_off;
        }

        return GestureDetector(
          onTap: () {
            // Cycle flash mode: off -> auto -> always -> off
            FlashMode nextMode;
            switch (cameraService.flashMode) {
              case FlashMode.off:
                nextMode = FlashMode.auto;
                break;
              case FlashMode.auto:
                nextMode = FlashMode.always;
                break;
              case FlashMode.always:
                nextMode = FlashMode.off;
                break;
              default:
                nextMode = FlashMode.off;
            }
            cameraService.setFlashMode(nextMode);
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        );
      },
    );
  }

  Widget _buildShutterButton() {
    return Consumer<CameraService>(
      builder: (context, cameraService, child) {
        return AnimatedScale(
          scale: _shutterScale,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
          child: GestureDetector(
            onTapDown: (_) {
              setState(() {
                _shutterScale = 0.85;
              });
            },
            onTapUp: (_) {
              setState(() {
                _shutterScale = 1.0;
              });
            },
            onTapCancel: () {
              setState(() {
                _shutterScale = 1.0;
              });
            },
            onTap: () async {
              // 先读取服务，避免 async gap 问题
              final storageService = context.read<PhotoStorageService>();
              final analysisService = context.read<AnalysisService>();

              // 执行拍照
              final metadata = await cameraService.takePhoto(
                storageService,
                analysisResult: analysisService.currentResult,
              );

              if (metadata != null && mounted) {
                _showPhotoResult(metadata);
              }
            },
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.black,
                size: 36,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGalleryButton() {
    return Consumer<PhotoStorageService>(
      builder: (context, storageService, child) {
        final photos = storageService.photos;
        final latestPhoto = photos.isNotEmpty ? photos.first : null;

        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/gallery');
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: latestPhoto != null
                ? ClipOval(
                    child: Image.file(
                      File(latestPhoto.thumbnailPath),
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    Icons.photo_library,
                    color: Colors.white,
                    size: 24,
                  ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsButton() {
    return Positioned(
      top: 50, // 从顶部开始，考虑状态栏
      right: 16,
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, '/settings');
        },
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.3), width: 1),
          ),
          child: const Icon(
            Icons.settings,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  String _formatParams(Map<String, dynamic> params) {
    return params.entries.map((e) => '${e.key}: ${e.value}').join(' | ');
  }

  /// Build debug info widget (only shown in debug mode)
  Widget _buildDebugInfo(
    AnalysisService analysisService,
    CameraService cameraService,
  ) {
    final coordinator = context.watch<AnalysisCoordinator>();
    final isAnalyzing = analysisService.isAnalyzing;
    final isStable = coordinator.isStable;
    final stability = coordinator.stability;
    final sceneChange = coordinator.sceneChange;
    final settingsService = context.watch<SettingsService>();

    String stabilityStatus;
    Color statusColor;

    if (isAnalyzing) {
      stabilityStatus = '🔄 分析中';
      statusColor = Colors.orange;
    } else if (isStable) {
      stabilityStatus = '✅ 画面稳定';
      statusColor = Colors.green;
    } else {
      stabilityStatus = '⏳ 检测中';
      statusColor = Colors.orange;
    }

    // 获取场景类型标题
    String sceneTitle = '未分析';
    if (analysisService.currentResult != null) {
      // 从拍摄建议中提取场景信息
      final advice = analysisService.currentResult!.shootingAdvice;
      sceneTitle = _extractSceneTitle(advice);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border:
            Border.all(color: Colors.orange.withValues(alpha: 0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(Icons.bug_report, color: Colors.orange, size: 12),
              SizedBox(width: 4),
              Text(
                'DEBUG',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '场景: $sceneTitle',
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '状态: $stabilityStatus',
            style: TextStyle(
              color: statusColor,
              fontSize: 10,
            ),
          ),
          ..._buildLlmDebugRows(analysisService, settingsService),
          if (!isStable && !isAnalyzing)
            Text(
              '稳定性: ${(stability * 100).toStringAsFixed(0)}%, 场景变化: ${(sceneChange * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: statusColor,
                fontSize: 9,
              ),
            ),
        ],
      ),
    );
  }

  /// Build debug overlay when no analysis result is available
  Widget _buildDebugOverlay(
    AnalysisService analysisService,
    CameraService cameraService,
  ) {
    final coordinator = context.watch<AnalysisCoordinator>();
    final isAnalyzing = analysisService.isAnalyzing;
    final isStable = coordinator.isStable;
    final stability = coordinator.stability;
    final sceneChange = coordinator.sceneChange;
    final settingsService = context.watch<SettingsService>();

    String stabilityStatus;
    Color statusColor;

    if (isAnalyzing) {
      stabilityStatus = '🔄 分析中';
      statusColor = Colors.orange;
    } else if (isStable) {
      stabilityStatus = '✅ 画面稳定';
      statusColor = Colors.green;
    } else {
      stabilityStatus = '⏳ 检测中';
      statusColor = Colors.orange;
    }

    return Positioned(
      top: 50,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.bug_report,
                  color: Colors.orange,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  'DEBUG MODE',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '状态: $stabilityStatus',
              style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  decoration: TextDecoration.none),
            ),
            Text(
              '稳定性: ${(stability * 100).toStringAsFixed(0)}%, 场景变化: ${(sceneChange * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: Colors.orange[300],
                fontSize: 9,
                decoration: TextDecoration.none,
              ),
            ),
            ..._buildLlmDebugRows(analysisService, settingsService),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLlmDebugRows(
    AnalysisService analysisService,
    SettingsService settingsService,
  ) {
    return [
      const SizedBox(height: 4),
      _buildDebugLine(
        'LLM: ${_formatProvider(settingsService.settings.selectedProvider)}',
      ),
      _buildDebugLine('API: ${_formatApiValidation(settingsService)}'),
      _buildDebugLine(
        '检测: ${analysisService.isAnalyzing ? '正在检测' : '空闲'}',
      ),
      _buildDebugLine(
        '返回: ${_formatAnalysisResultStatus(analysisService)}',
        maxLines: 2,
      ),
    ];
  }

  Widget _buildDebugLine(String text, {int maxLines = 1}) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.orange[200],
        fontSize: 9,
        decoration: TextDecoration.none,
      ),
    );
  }

  String _formatProvider(String provider) {
    switch (provider) {
      case 'openai':
        return 'OpenAI';
      case 'anthropic':
        return 'Anthropic';
      case 'azure':
        return 'Azure OpenAI';
      case 'zhipu_glm':
        return '智谱 GLM';
      case 'custom':
        return 'Custom Endpoint';
      default:
        return provider;
    }
  }

  String _formatApiValidation(SettingsService settingsService) {
    final message = settingsService.apiValidationMessage;
    switch (settingsService.apiValidationStatus) {
      case ApiValidationStatus.notConfigured:
        return '未配置 API Key';
      case ApiValidationStatus.unverified:
        return '已配置，未验证';
      case ApiValidationStatus.checking:
        return '正在验证';
      case ApiValidationStatus.valid:
        return '有效${message == null ? '' : ' - $message'}';
      case ApiValidationStatus.invalid:
        return '无效${message == null ? '' : ' - $message'}';
    }
  }

  String _formatAnalysisResultStatus(AnalysisService analysisService) {
    switch (analysisService.lastRunStatus) {
      case AnalysisRunStatus.idle:
        return analysisService.currentResult == null ? '暂无返回' : '已有结果';
      case AnalysisRunStatus.analyzing:
        return '请求中';
      case AnalysisRunStatus.success:
        return '成功 - ${analysisService.lastRunMessage ?? '有结果'}';
      case AnalysisRunStatus.failed:
        return '失败 - ${analysisService.lastErrorMessage ?? '未知错误'}';
    }
  }

  /// Extract scene title from shooting advice
  String _extractSceneTitle(String advice) {
    // 简单的场景识别逻辑
    final lowerAdvice = advice.toLowerCase();

    if (lowerAdvice.contains('人像') || lowerAdvice.contains('portrait')) {
      return '人像';
    } else if (lowerAdvice.contains('风景') ||
        lowerAdvice.contains('landscape')) {
      return '风景';
    } else if (lowerAdvice.contains('夜景') || lowerAdvice.contains('night')) {
      return '夜景';
    } else if (lowerAdvice.contains('食物') || lowerAdvice.contains('food')) {
      return '食物';
    } else if (lowerAdvice.contains('建筑') ||
        lowerAdvice.contains('architecture')) {
      return '建筑';
    } else if (lowerAdvice.contains('静物') || lowerAdvice.contains('still')) {
      return '静物';
    } else if (lowerAdvice.contains('逆光') ||
        lowerAdvice.contains('backlight')) {
      return '逆光';
    } else {
      return '通用场景';
    }
  }

  void _showPhotoResult(PhotoMetadata metadata) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.black.withValues(alpha: 0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                '拍摄成功',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Photo saved successfully',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Auto-close after 1.5 seconds
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }
}
