# Local Scene Understanding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an optional Android LiteRT-LM local scene-understanding path before the existing LLM image-analysis flow, with iOS falling back through the same current remote flow.

**Architecture:** Keep local scene understanding separate from LLM recommendation. `SceneUnderstandingRepository` produces structured scene JSON from an image; `RecommendationRepository` turns that scene JSON into the existing `AnalysisResult`; `AnalysisService` chooses local-first or current image-based fallback based on settings and failures.

**Tech Stack:** Flutter/Dart, Provider, shared_preferences, http tests with `MockClient`, Flutter MethodChannel, Android Kotlin, LiteRT-LM Android SDK, Gemma 4 E2B LiteRT-LM model.

---

## Source Spec

Implement from `docs/superpowers/specs/2026-05-13-local-scene-understanding-design.md`.

Scope is one MVP:

- Android local scene understanding with LiteRT-LM and Gemma 4 E2B.
- iOS architecture preserved through a Dart repository that reports unsupported and falls back.
- A user setting controls local mode.
- Fallback after any local failure must call the existing `AnalysisRepository.analyzeImage(imageData)` path.
- Recommendation API continues to return `AnalysisResult`.

## File Structure

Create:

- `smart_cam/lib/features/scene_understanding/domain/scene_understanding_repository.dart`  
  Interface for local scene understanding.
- `smart_cam/lib/features/scene_understanding/domain/scene_understanding_result.dart`  
  Serializable scene graph result and runtime metadata.
- `smart_cam/lib/features/scene_understanding/domain/scene_object.dart`  
  Object model for name, attributes, state, and confidence.
- `smart_cam/lib/features/scene_understanding/domain/scene_relationship.dart`  
  Relationship model between object ids.
- `smart_cam/lib/features/scene_understanding/domain/scene_understanding_status.dart`  
  Status enum used by Dart, debug UI, and fallback logic.
- `smart_cam/lib/features/scene_understanding/domain/scene_understanding_exception.dart`  
  Typed exception for unavailable, timeout, parse, and native errors.
- `smart_cam/lib/features/scene_understanding/data/litert_lm_scene_repository.dart`  
  Android local provider: writes a resized JPEG, calls the platform channel, parses strict JSON.
- `smart_cam/lib/features/scene_understanding/data/unsupported_scene_repository.dart`  
  iOS and non-Android provider: returns a typed unsupported failure.
- `smart_cam/lib/features/scene_understanding/data/bundled_scene_model_store.dart`  
  Resolves bundled Gemma model to a native-readable file path.
- `smart_cam/lib/features/scene_understanding/platform/scene_understanding_channel.dart`  
  MethodChannel wrapper for `scene_understanding/analyze`.
- `smart_cam/lib/features/analysis/domain/recommendation_repository.dart`  
  Scene JSON to `AnalysisResult` recommendation contract.
- `smart_cam/android/app/src/main/kotlin/com/example/smart_cam/SceneUnderstandingChannel.kt`  
  Kotlin channel registration and argument parsing.
- `smart_cam/android/app/src/main/kotlin/com/example/smart_cam/LiteRtLmSceneAnalyzer.kt`  
  Kotlin LiteRT-LM adapter.
- `smart_cam/assets/models/README.md`  
  Documents the bundled model filename expected by MVP.
- Tests under `smart_cam/test/unit/scene_understanding/`.

Modify:

- `smart_cam/lib/features/settings/domain/app_settings.dart`  
  Add persisted `enableLocalSceneUnderstanding`.
- `smart_cam/lib/features/settings/presentation/settings_service.dart`  
  Add toggle method.
- `smart_cam/lib/features/settings/presentation/pages/settings_page.dart`  
  Add switch in Preferences.
- `smart_cam/lib/features/analysis/data/analysis_api_repository.dart`  
  Implement `RecommendationRepository.recommendFromScene`.
- `smart_cam/lib/features/analysis/presentation/analysis_service.dart`  
  Local-first orchestration and debug status.
- `smart_cam/lib/features/camera/presentation/pages/camera_page.dart`  
  Debug rows for local model status.
- `smart_cam/lib/main.dart`  
  Wire settings, scene repository, and recommendation repository.
- `smart_cam/android/app/build.gradle`  
  Add LiteRT-LM dependency and asset packaging config.
- `smart_cam/android/app/src/main/kotlin/com/example/smart_cam/MainActivity.kt`  
  Register the scene-understanding channel.
- Existing unit/widget tests touched by constructor signature changes.

## Execution Notes

- If using a worktree for implementation, create it under `/Users/xiyu.chen/toys/SmartCamera/.worktree/` per project instruction.
- Do not commit a 2.58 GB model unless the user explicitly approves that repository change. The code should support `smart_cam/assets/models/gemma-4-E2B-it-litert-lm.litertlm`; when the file is absent, local mode must fall back.
- Keep every task independently buildable where possible. Commit after each task.

---

### Task 1: Add Local Model Setting

**Files:**
- Modify: `smart_cam/lib/features/settings/domain/app_settings.dart`
- Modify: `smart_cam/lib/features/settings/presentation/settings_service.dart`
- Test: `smart_cam/test/unit/settings_service_test.dart`

- [ ] **Step 1: Write failing settings tests**

Append these tests inside the existing `group('SettingsService', () { ... })` in `smart_cam/test/unit/settings_service_test.dart`:

```dart
    test('defaults local scene understanding to disabled', () {
      final settings = AppSettings();

      expect(settings.enableLocalSceneUnderstanding, isFalse);
      expect(settings.toJson()['local_scene_understanding'], isFalse);
    });

    test('loads and persists local scene understanding setting', () async {
      SharedPreferences.setMockInitialValues({
        'app_settings': jsonEncode({
          'provider': 'openai',
          'api_key': 'key',
          'local_scene_understanding': true,
        }),
      });

      final service = SettingsService();
      await service.loadSettings();

      expect(service.settings.enableLocalSceneUnderstanding, isTrue);

      service.toggleLocalSceneUnderstanding(false);
      expect(service.settings.enableLocalSceneUnderstanding, isFalse);
    });
```

- [ ] **Step 2: Run tests and verify failure**

Run:

```bash
cd /Users/xiyu.chen/toys/SmartCamera/smart_cam
flutter test test/unit/settings_service_test.dart
```

Expected: fails because `enableLocalSceneUnderstanding` and `toggleLocalSceneUnderstanding` are not defined.

- [ ] **Step 3: Update `AppSettings`**

Edit `smart_cam/lib/features/settings/domain/app_settings.dart` so the class includes the new field:

```dart
  bool enableLocalSceneUnderstanding;
```

Add it to the constructor:

```dart
    this.enableLocalSceneUnderstanding = false,
```

Add it to `fromJson`:

```dart
      enableLocalSceneUnderstanding:
          json['local_scene_understanding'] ?? false,
```

Add it to `toJson`:

```dart
      'local_scene_understanding': enableLocalSceneUnderstanding,
```

- [ ] **Step 4: Update `SettingsService`**

Add this method near the other toggle methods in `smart_cam/lib/features/settings/presentation/settings_service.dart`:

```dart
  void toggleLocalSceneUnderstanding(bool enabled) {
    _settings.enableLocalSceneUnderstanding = enabled;
    notifyListeners();
    _saveSettings();
  }
```

- [ ] **Step 5: Run settings tests**

Run:

```bash
cd /Users/xiyu.chen/toys/SmartCamera/smart_cam
flutter test test/unit/settings_service_test.dart
```

Expected: all tests in `settings_service_test.dart` pass.

- [ ] **Step 6: Commit**

```bash
cd /Users/xiyu.chen/toys/SmartCamera
git add smart_cam/lib/features/settings/domain/app_settings.dart \
  smart_cam/lib/features/settings/presentation/settings_service.dart \
  smart_cam/test/unit/settings_service_test.dart
git commit -m "feat: add local scene understanding setting"
```

---

### Task 2: Add Scene Understanding Domain Models

**Files:**
- Create: `smart_cam/lib/features/scene_understanding/domain/scene_understanding_status.dart`
- Create: `smart_cam/lib/features/scene_understanding/domain/scene_object.dart`
- Create: `smart_cam/lib/features/scene_understanding/domain/scene_relationship.dart`
- Create: `smart_cam/lib/features/scene_understanding/domain/scene_understanding_result.dart`
- Create: `smart_cam/lib/features/scene_understanding/domain/scene_understanding_exception.dart`
- Create: `smart_cam/lib/features/scene_understanding/domain/scene_understanding_repository.dart`
- Test: `smart_cam/test/unit/scene_understanding/scene_understanding_result_test.dart`

- [ ] **Step 1: Write failing domain tests**

Create `smart_cam/test/unit/scene_understanding/scene_understanding_result_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_cam/features/scene_understanding/domain/scene_understanding_result.dart';
import 'package:smart_cam/features/scene_understanding/domain/scene_understanding_status.dart';

void main() {
  group('SceneUnderstandingResult', () {
    test('parses valid scene graph json', () {
      final result = SceneUnderstandingResult.fromJson({
        'summary': 'A person stands in front of a building.',
        'scene_type': 'street',
        'objects': [
          {
            'id': 'person_1',
            'name': 'person',
            'attributes': ['standing', 'backlit'],
            'state': 'still',
            'confidence': 0.72,
          },
          {
            'id': 'building_1',
            'name': 'building',
            'attributes': ['tall'],
            'state': 'static',
            'confidence': 0.66,
          },
        ],
        'relationships': [
          {
            'subject': 'person_1',
            'relation': 'standing in front of',
            'object': 'building_1',
            'confidence': 0.64,
          },
        ],
        'quality_notes': ['backlit subject'],
      });

      expect(result.summary, 'A person stands in front of a building.');
      expect(result.sceneType, 'street');
      expect(result.objects.first.id, 'person_1');
      expect(result.objects.first.attributes, ['standing', 'backlit']);
      expect(result.relationships.first.subjectId, 'person_1');
      expect(result.relationships.first.objectId, 'building_1');
      expect(result.qualityNotes, ['backlit subject']);
      expect(result.runtime.status, SceneUnderstandingStatus.success);
    });

    test('throws format exception when required string fields are missing', () {
      expect(
        () => SceneUnderstandingResult.fromJson({
          'summary': '',
          'scene_type': 'street',
          'objects': const [],
          'relationships': const [],
          'quality_notes': const [],
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('serializes runtime metadata', () {
      final result = SceneUnderstandingResult.emptyUnsupported(
        errorMessage: 'iOS local scene understanding is not available',
      );

      expect(result.runtime.status, SceneUnderstandingStatus.unsupported);
      expect(result.runtime.provider, 'unsupported');
      expect(result.toJson()['runtime']['status'], 'unsupported');
      expect(result.toJson()['runtime']['error_message'],
          'iOS local scene understanding is not available');
    });
  });
}
```

- [ ] **Step 2: Run test and verify failure**

Run:

```bash
cd /Users/xiyu.chen/toys/SmartCamera/smart_cam
flutter test test/unit/scene_understanding/scene_understanding_result_test.dart
```

Expected: fails because scene-understanding files do not exist.

- [ ] **Step 3: Create status enum**

Create `smart_cam/lib/features/scene_understanding/domain/scene_understanding_status.dart`:

```dart
enum SceneUnderstandingStatus {
  success,
  unavailable,
  unsupported,
  timeout,
  parseError,
  nativeError,
}

extension SceneUnderstandingStatusJson on SceneUnderstandingStatus {
  String get wireName {
    switch (this) {
      case SceneUnderstandingStatus.success:
        return 'success';
      case SceneUnderstandingStatus.unavailable:
        return 'unavailable';
      case SceneUnderstandingStatus.unsupported:
        return 'unsupported';
      case SceneUnderstandingStatus.timeout:
        return 'timeout';
      case SceneUnderstandingStatus.parseError:
        return 'parse_error';
      case SceneUnderstandingStatus.nativeError:
        return 'native_error';
    }
  }

  static SceneUnderstandingStatus fromWireName(String value) {
    switch (value) {
      case 'success':
        return SceneUnderstandingStatus.success;
      case 'unavailable':
        return SceneUnderstandingStatus.unavailable;
      case 'unsupported':
        return SceneUnderstandingStatus.unsupported;
      case 'timeout':
        return SceneUnderstandingStatus.timeout;
      case 'parse_error':
        return SceneUnderstandingStatus.parseError;
      case 'native_error':
        return SceneUnderstandingStatus.nativeError;
      default:
        return SceneUnderstandingStatus.nativeError;
    }
  }
}
```

- [ ] **Step 4: Create object and relationship models**

Create `smart_cam/lib/features/scene_understanding/domain/scene_object.dart`:

```dart
class SceneObject {
  final String id;
  final String name;
  final List<String> attributes;
  final String state;
  final double? confidence;

  const SceneObject({
    required this.id,
    required this.name,
    required this.attributes,
    required this.state,
    this.confidence,
  });

  factory SceneObject.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as String? ?? '').trim();
    final name = (json['name'] as String? ?? '').trim();
    if (id.isEmpty || name.isEmpty) {
      throw const FormatException('Scene object id and name are required');
    }

    return SceneObject(
      id: id,
      name: name,
      attributes: List<String>.from(json['attributes'] ?? const []),
      state: (json['state'] as String? ?? '').trim(),
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'attributes': attributes,
      'state': state,
      if (confidence != null) 'confidence': confidence,
    };
  }
}
```

Create `smart_cam/lib/features/scene_understanding/domain/scene_relationship.dart`:

```dart
class SceneRelationship {
  final String subjectId;
  final String relation;
  final String objectId;
  final double? confidence;

  const SceneRelationship({
    required this.subjectId,
    required this.relation,
    required this.objectId,
    this.confidence,
  });

  factory SceneRelationship.fromJson(Map<String, dynamic> json) {
    final subject = (json['subject'] as String? ?? '').trim();
    final relation = (json['relation'] as String? ?? '').trim();
    final object = (json['object'] as String? ?? '').trim();
    if (subject.isEmpty || relation.isEmpty || object.isEmpty) {
      throw const FormatException(
        'Scene relationship subject, relation, and object are required',
      );
    }

    return SceneRelationship(
      subjectId: subject,
      relation: relation,
      objectId: object,
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subjectId,
      'relation': relation,
      'object': objectId,
      if (confidence != null) 'confidence': confidence,
    };
  }
}
```

- [ ] **Step 5: Create result, exception, and repository interface**

Create `smart_cam/lib/features/scene_understanding/domain/scene_understanding_result.dart`:

```dart
import 'scene_object.dart';
import 'scene_relationship.dart';
import 'scene_understanding_status.dart';

class SceneUnderstandingRuntime {
  final String provider;
  final String modelId;
  final String modelVersion;
  final int latencyMs;
  final SceneUnderstandingStatus status;
  final String? errorMessage;

  const SceneUnderstandingRuntime({
    required this.provider,
    required this.modelId,
    required this.modelVersion,
    required this.latencyMs,
    required this.status,
    this.errorMessage,
  });

  factory SceneUnderstandingRuntime.success({
    required int latencyMs,
    String provider = 'litert_lm',
    String modelId = 'gemma-4-E2B-it-litert-lm',
    String modelVersion = 'mvp',
  }) {
    return SceneUnderstandingRuntime(
      provider: provider,
      modelId: modelId,
      modelVersion: modelVersion,
      latencyMs: latencyMs,
      status: SceneUnderstandingStatus.success,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'model_id': modelId,
      'model_version': modelVersion,
      'latency_ms': latencyMs,
      'status': status.wireName,
      if (errorMessage != null) 'error_message': errorMessage,
    };
  }
}

class SceneUnderstandingResult {
  final String summary;
  final String sceneType;
  final List<SceneObject> objects;
  final List<SceneRelationship> relationships;
  final List<String> qualityNotes;
  final SceneUnderstandingRuntime runtime;
  final String? rawText;

  const SceneUnderstandingResult({
    required this.summary,
    required this.sceneType,
    required this.objects,
    required this.relationships,
    required this.qualityNotes,
    required this.runtime,
    this.rawText,
  });

  factory SceneUnderstandingResult.fromJson(
    Map<String, dynamic> json, {
    SceneUnderstandingRuntime? runtime,
    String? rawText,
  }) {
    final summary = (json['summary'] as String? ?? '').trim();
    final sceneType = (json['scene_type'] as String? ?? '').trim();
    if (summary.isEmpty || sceneType.isEmpty) {
      throw const FormatException('summary and scene_type are required');
    }

    return SceneUnderstandingResult(
      summary: summary,
      sceneType: sceneType,
      objects: (json['objects'] as List<dynamic>? ?? const [])
          .map((item) => SceneObject.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      relationships:
          (json['relationships'] as List<dynamic>? ?? const [])
              .map((item) =>
                  SceneRelationship.fromJson(item as Map<String, dynamic>))
              .toList(growable: false),
      qualityNotes: List<String>.from(json['quality_notes'] ?? const []),
      runtime: runtime ?? SceneUnderstandingRuntime.success(latencyMs: 0),
      rawText: rawText,
    );
  }

  factory SceneUnderstandingResult.emptyUnsupported({
    required String errorMessage,
  }) {
    return SceneUnderstandingResult(
      summary: '',
      sceneType: '',
      objects: const [],
      relationships: const [],
      qualityNotes: const [],
      runtime: SceneUnderstandingRuntime(
        provider: 'unsupported',
        modelId: '',
        modelVersion: '',
        latencyMs: 0,
        status: SceneUnderstandingStatus.unsupported,
        errorMessage: errorMessage,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'scene_type': sceneType,
      'objects': objects.map((item) => item.toJson()).toList(),
      'relationships':
          relationships.map((item) => item.toJson()).toList(),
      'quality_notes': qualityNotes,
      'runtime': runtime.toJson(),
      if (rawText != null) 'raw_text': rawText,
    };
  }
}
```

Create `smart_cam/lib/features/scene_understanding/domain/scene_understanding_exception.dart`:

```dart
import 'scene_understanding_status.dart';

class SceneUnderstandingException implements Exception {
  final SceneUnderstandingStatus status;
  final String message;

  const SceneUnderstandingException(this.status, this.message);

  @override
  String toString() {
    return 'SceneUnderstandingException(${status.wireName}): $message';
  }
}
```

Create `smart_cam/lib/features/scene_understanding/domain/scene_understanding_repository.dart`:

```dart
import 'dart:typed_data';

import 'scene_understanding_result.dart';

abstract class SceneUnderstandingRepository {
  Future<SceneUnderstandingResult> analyzeScene(Uint8List imageData);
}
```

- [ ] **Step 6: Run domain tests**

Run:

```bash
cd /Users/xiyu.chen/toys/SmartCamera/smart_cam
flutter test test/unit/scene_understanding/scene_understanding_result_test.dart
```

Expected: pass.

- [ ] **Step 7: Commit**

```bash
cd /Users/xiyu.chen/toys/SmartCamera
git add smart_cam/lib/features/scene_understanding/domain \
  smart_cam/test/unit/scene_understanding/scene_understanding_result_test.dart
git commit -m "feat: add scene understanding domain"
```

---

### Task 3: Add Dart Platform Channel and Local Repositories

**Files:**
- Create: `smart_cam/lib/features/scene_understanding/platform/scene_understanding_channel.dart`
- Create: `smart_cam/lib/features/scene_understanding/data/bundled_scene_model_store.dart`
- Create: `smart_cam/lib/features/scene_understanding/data/litert_lm_scene_repository.dart`
- Create: `smart_cam/lib/features/scene_understanding/data/unsupported_scene_repository.dart`
- Modify: `smart_cam/pubspec.yaml`
- Create: `smart_cam/assets/models/README.md`
- Test: `smart_cam/test/unit/scene_understanding/litert_lm_scene_repository_test.dart`
- Test: `smart_cam/test/unit/scene_understanding/unsupported_scene_repository_test.dart`

- [ ] **Step 1: Write failing repository tests**

Create `smart_cam/test/unit/scene_understanding/litert_lm_scene_repository_test.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_cam/features/scene_understanding/data/litert_lm_scene_repository.dart';
import 'package:smart_cam/features/scene_understanding/domain/scene_understanding_exception.dart';
import 'package:smart_cam/features/scene_understanding/domain/scene_understanding_status.dart';
import 'package:smart_cam/features/scene_understanding/platform/scene_understanding_channel.dart';

class _FakeChannel implements SceneUnderstandingChannel {
  _FakeChannel(this.response);

  final Future<Map<String, dynamic>> Function(Map<String, dynamic> request)
      response;
  Map<String, dynamic>? lastRequest;

  @override
  Future<Map<String, dynamic>> analyze(Map<String, dynamic> request) {
    lastRequest = request;
    return response(request);
  }
}

void main() {
  group('LiteRtLmSceneRepository', () {
    test('parses native raw json into scene understanding result', () async {
      final channel = _FakeChannel((request) async {
        return {
          'status': 'success',
          'latencyMs': 123,
          'rawText': jsonEncode({
            'summary': 'A person is holding a cup near a window.',
            'scene_type': 'indoor',
            'objects': [
              {
                'id': 'person_1',
                'name': 'person',
                'attributes': ['holding cup'],
                'state': 'still',
                'confidence': 0.8,
              },
            ],
            'relationships': [],
            'quality_notes': ['soft side light'],
          }),
        };
      });

      final repository = LiteRtLmSceneRepository(
        channel: channel,
        imageFileWriter: (_) async => '/tmp/frame.jpg',
        modelPathProvider: () async => '/tmp/model.litertlm',
      );

      final result = await repository.analyzeScene(Uint8List.fromList([1, 2]));

      expect(channel.lastRequest!['imagePath'], '/tmp/frame.jpg');
      expect(channel.lastRequest!['modelPath'], '/tmp/model.litertlm');
      expect(result.summary, 'A person is holding a cup near a window.');
      expect(result.runtime.latencyMs, 123);
      expect(result.runtime.status, SceneUnderstandingStatus.success);
    });

    test('throws parseError when native raw text is not json', () async {
      final repository = LiteRtLmSceneRepository(
        channel: _FakeChannel((request) async {
          return {
            'status': 'success',
            'latencyMs': 5,
            'rawText': 'not json',
          };
        }),
        imageFileWriter: (_) async => '/tmp/frame.jpg',
        modelPathProvider: () async => '/tmp/model.litertlm',
      );

      expect(
        () => repository.analyzeScene(Uint8List.fromList([1])),
        throwsA(
          isA<SceneUnderstandingException>().having(
            (error) => error.status,
            'status',
            SceneUnderstandingStatus.parseError,
          ),
        ),
      );
    });
  });
}
```

Create `smart_cam/test/unit/scene_understanding/unsupported_scene_repository_test.dart`:

```dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_cam/features/scene_understanding/data/unsupported_scene_repository.dart';
import 'package:smart_cam/features/scene_understanding/domain/scene_understanding_exception.dart';
import 'package:smart_cam/features/scene_understanding/domain/scene_understanding_status.dart';

void main() {
  test('unsupported repository throws typed unsupported exception', () {
    final repository = UnsupportedSceneRepository(
      message: 'iOS local scene understanding is not available',
    );

    expect(
      () => repository.analyzeScene(Uint8List.fromList([1])),
      throwsA(
        isA<SceneUnderstandingException>().having(
          (error) => error.status,
          'status',
          SceneUnderstandingStatus.unsupported,
        ),
      ),
    );
  });
}
```

- [ ] **Step 2: Run tests and verify failure**

Run:

```bash
cd /Users/xiyu.chen/toys/SmartCamera/smart_cam
flutter test test/unit/scene_understanding
```

Expected: fails because repositories and channel do not exist.

- [ ] **Step 3: Add model asset directory**

Modify `smart_cam/pubspec.yaml` under `flutter:`:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/models/
```

Create `smart_cam/assets/models/README.md`:

```markdown
# Local Scene Model Assets

MVP expects the Android local scene-understanding model at:

`assets/models/gemma-4-E2B-it-litert-lm.litertlm`

The app falls back to the existing remote image-analysis flow when this file is not bundled or cannot be copied to app storage.
```

- [ ] **Step 4: Create channel wrapper**

Create `smart_cam/lib/features/scene_understanding/platform/scene_understanding_channel.dart`:

```dart
import 'package:flutter/services.dart';

abstract class SceneUnderstandingChannel {
  Future<Map<String, dynamic>> analyze(Map<String, dynamic> request);
}

class MethodChannelSceneUnderstandingChannel
    implements SceneUnderstandingChannel {
  static const MethodChannel _channel =
      MethodChannel('smart_cam/scene_understanding');

  @override
  Future<Map<String, dynamic>> analyze(Map<String, dynamic> request) async {
    final response = await _channel.invokeMapMethod<String, dynamic>(
      'analyze',
      request,
    );
    if (response == null) {
      throw PlatformException(
        code: 'empty_response',
        message: 'Native scene understanding returned an empty response',
      );
    }
    return response;
  }
}
```

- [ ] **Step 5: Create model store**

Create `smart_cam/lib/features/scene_understanding/data/bundled_scene_model_store.dart`:

```dart
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class BundledSceneModelStore {
  static const String assetPath =
      'assets/models/gemma-4-E2B-it-litert-lm.litertlm';
  static const String fileName = 'gemma-4-E2B-it-litert-lm.litertlm';

  const BundledSceneModelStore();

  Future<String> resolveModelPath() async {
    final supportDir = await getApplicationSupportDirectory();
    final modelsDir = Directory('${supportDir.path}/models');
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }

    final modelFile = File('${modelsDir.path}/$fileName');
    if (await modelFile.exists() && await modelFile.length() > 0) {
      return modelFile.path;
    }

    final data = await rootBundle.load(assetPath);
    await modelFile.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
    return modelFile.path;
  }
}
```

- [ ] **Step 6: Create local and unsupported repositories**

Create `smart_cam/lib/features/scene_understanding/data/unsupported_scene_repository.dart`:

```dart
import 'dart:typed_data';

import '../domain/scene_understanding_exception.dart';
import '../domain/scene_understanding_repository.dart';
import '../domain/scene_understanding_result.dart';
import '../domain/scene_understanding_status.dart';

class UnsupportedSceneRepository implements SceneUnderstandingRepository {
  final String message;

  const UnsupportedSceneRepository({required this.message});

  @override
  Future<SceneUnderstandingResult> analyzeScene(Uint8List imageData) {
    throw SceneUnderstandingException(
      SceneUnderstandingStatus.unsupported,
      message,
    );
  }
}
```

Create `smart_cam/lib/features/scene_understanding/data/litert_lm_scene_repository.dart`:

```dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../domain/scene_understanding_exception.dart';
import '../domain/scene_understanding_repository.dart';
import '../domain/scene_understanding_result.dart';
import '../domain/scene_understanding_status.dart';
import '../platform/scene_understanding_channel.dart';

typedef SceneImageFileWriter = Future<String> Function(Uint8List imageData);
typedef SceneModelPathProvider = Future<String> Function();

class LiteRtLmSceneRepository implements SceneUnderstandingRepository {
  static const Duration defaultTimeout = Duration(seconds: 20);

  final SceneUnderstandingChannel channel;
  final SceneImageFileWriter imageFileWriter;
  final SceneModelPathProvider modelPathProvider;
  final Duration timeout;

  LiteRtLmSceneRepository({
    required this.channel,
    required this.imageFileWriter,
    required this.modelPathProvider,
    this.timeout = defaultTimeout,
  });

  factory LiteRtLmSceneRepository.android({
    required SceneUnderstandingChannel channel,
    required SceneModelPathProvider modelPathProvider,
  }) {
    return LiteRtLmSceneRepository(
      channel: channel,
      modelPathProvider: modelPathProvider,
      imageFileWriter: _writeTempImage,
    );
  }

  @override
  Future<SceneUnderstandingResult> analyzeScene(Uint8List imageData) async {
    try {
      final imagePath = await imageFileWriter(imageData);
      final modelPath = await modelPathProvider();
      final response = await channel
          .analyze({
            'imagePath': imagePath,
            'modelPath': modelPath,
            'prompt': _scenePrompt,
            'timeoutMs': timeout.inMilliseconds,
          })
          .timeout(timeout);

      final status = (response['status'] as String? ?? 'native_error');
      if (status != 'success') {
        throw SceneUnderstandingException(
          SceneUnderstandingStatusJson.fromWireName(status),
          response['errorMessage'] as String? ?? 'Local model failed',
        );
      }

      final rawText = response['rawText'] as String? ?? '';
      final jsonMap = _decodeSceneJson(rawText);
      return SceneUnderstandingResult.fromJson(
        jsonMap,
        rawText: rawText,
        runtime: SceneUnderstandingRuntime.success(
          latencyMs: response['latencyMs'] as int? ?? 0,
        ),
      );
    } on SceneUnderstandingException {
      rethrow;
    } on FormatException catch (e) {
      throw SceneUnderstandingException(
        SceneUnderstandingStatus.parseError,
        e.message,
      );
    } on TimeoutException {
      throw const SceneUnderstandingException(
        SceneUnderstandingStatus.timeout,
        'Local scene understanding timed out',
      );
    } catch (e) {
      throw SceneUnderstandingException(
        SceneUnderstandingStatus.nativeError,
        e.toString(),
      );
    }
  }

  static Future<String> _writeTempImage(Uint8List imageData) async {
    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/scene_understanding_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(imageData, flush: true);
    return file.path;
  }

  Map<String, dynamic> _decodeSceneJson(String rawText) {
    final trimmed = rawText.trim();
    final direct = jsonDecode(trimmed);
    if (direct is Map<String, dynamic>) {
      return direct;
    }
    throw const FormatException('Local model response is not a JSON object');
  }

  static const String _scenePrompt = '''
Return only valid JSON. Describe observable image content, not photography advice.
Shape:
{
  "summary": "one concise objective scene description",
  "scene_type": "portrait | landscape | food | street | indoor | document | other",
  "objects": [
    {
      "id": "object_1",
      "name": "object name",
      "attributes": ["visible attributes"],
      "state": "visible state",
      "confidence": 0.0
    }
  ],
  "relationships": [
    {
      "subject": "object_1",
      "relation": "visible relation",
      "object": "object_2",
      "confidence": 0.0
    }
  ],
  "quality_notes": ["observable lighting, blur, framing, or occlusion notes"]
}
Use Simplified Chinese for text values. Keep keys exactly as shown.
''';
}
```

- [ ] **Step 7: Add missing async import**

The implementation above uses `TimeoutException`. Add this import at the top of `smart_cam/lib/features/scene_understanding/data/litert_lm_scene_repository.dart`:

```dart
import 'dart:async';
```

- [ ] **Step 8: Run scene-understanding repository tests**

Run:

```bash
cd /Users/xiyu.chen/toys/SmartCamera/smart_cam
flutter test test/unit/scene_understanding
```

Expected: pass.

- [ ] **Step 9: Commit**

```bash
cd /Users/xiyu.chen/toys/SmartCamera
git add smart_cam/pubspec.yaml smart_cam/assets/models \
  smart_cam/lib/features/scene_understanding/data \
  smart_cam/lib/features/scene_understanding/platform \
  smart_cam/test/unit/scene_understanding
git commit -m "feat: add local scene repository"
```

---

### Task 4: Add Recommendation From Scene API Path

**Files:**
- Create: `smart_cam/lib/features/analysis/domain/recommendation_repository.dart`
- Modify: `smart_cam/lib/features/analysis/data/analysis_api_repository.dart`
- Test: `smart_cam/test/unit/analysis_api_repository_test.dart`

- [ ] **Step 1: Write failing API test**

Append this test to `group('AnalysisApiRepository direct providers', () { ... })` in `smart_cam/test/unit/analysis_api_repository_test.dart`:

```dart
    test('recommends from local scene json without uploading image bytes',
        () async {
      late Map<String, dynamic> capturedBody;

      final client = MockClient((request) async {
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'choices': [
              {
                'message': {
                  'content': jsonEncode({
                    'scene_description': '室内有人端着咖啡站在窗边',
                    'shooting_advice': '让人物稍微转向窗光',
                    'camera_params': {'iso': '200'},
                    'filter_suggestions': ['自然', '暖调'],
                  }),
                },
              },
            ],
          })),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final repository = AnalysisApiRepository(
        client: client,
        settingsProvider: () => AppSettings(
          selectedProvider: 'openai',
          apiKey: 'openai-key',
        ),
      );

      final result = await repository.recommendFromScene({
        'summary': '室内有人端着咖啡站在窗边',
        'scene_type': 'indoor',
        'objects': const [],
        'relationships': const [],
        'quality_notes': ['窗边侧光'],
      });

      final content = capturedBody['messages'].first['content'] as List;
      expect(content.length, 1);
      expect(content.first['type'], 'text');
      expect(content.first['text'], contains('室内有人端着咖啡站在窗边'));
      expect(content.first['text'], contains('shooting_advice'));
      expect(content.first['text'], isNot(contains('image_url')));
      expect(result.shootingAdvice, '让人物稍微转向窗光');
    });
```

- [ ] **Step 2: Run test and verify failure**

Run:

```bash
cd /Users/xiyu.chen/toys/SmartCamera/smart_cam
flutter test test/unit/analysis_api_repository_test.dart
```

Expected: fails because `recommendFromScene` is not defined.

- [ ] **Step 3: Create recommendation interface**

Create `smart_cam/lib/features/analysis/domain/recommendation_repository.dart`:

```dart
import 'analysis_result.dart';

abstract class RecommendationRepository {
  Future<AnalysisResult> recommendFromScene(Map<String, dynamic> sceneJson);
}
```

- [ ] **Step 4: Implement interface in API repository**

Modify class declaration in `smart_cam/lib/features/analysis/data/analysis_api_repository.dart`:

```dart
class AnalysisApiRepository
    implements AnalysisRepository, RecommendationRepository {
```

Add import:

```dart
import '../domain/recommendation_repository.dart';
```

Add public method:

```dart
  @override
  Future<AnalysisResult> recommendFromScene(
    Map<String, dynamic> sceneJson,
  ) async {
    final settings = _settingsProvider();
    final resultJson = await _recommendFromSceneWithPrompt(
      settings: settings,
      sceneJson: sceneJson,
      prompt: _sceneRecommendationPrompt,
    );
    return AnalysisResult.fromJson(resultJson);
  }
```

Add helper method near `_analyzeImageWithPrompt`:

```dart
  Future<Map<String, dynamic>> _recommendFromSceneWithPrompt({
    required AppSettings settings,
    required Map<String, dynamic> sceneJson,
    required String prompt,
  }) async {
    final sceneText = const JsonEncoder.withIndent('  ').convert(sceneJson);
    final combinedPrompt = '$prompt\n\nLocal scene understanding JSON:\n$sceneText';

    switch (settings.selectedProvider) {
      case 'openai':
        return _postOpenAiCompatibleText(
          uri: Uri.parse(AppConfig.openAiChatCompletionsUrl),
          apiKey: settings.apiKey,
          model: AppConfig.openAiVisionModel,
          prompt: combinedPrompt,
          label: 'OpenAI',
        );
      case 'anthropic':
        return _postAnthropicText(
          uri: Uri.parse(AppConfig.anthropicMessagesUrl),
          apiKey: settings.apiKey,
          model: AppConfig.anthropicVisionModel,
          prompt: combinedPrompt,
          label: 'Anthropic',
        );
      case 'azure':
        return _postOpenAiCompatibleText(
          uri: _buildAzureChatCompletionsUri(settings),
          apiKey: settings.apiKey,
          model: settings.azureDeployment.trim(),
          prompt: combinedPrompt,
          label: 'Azure OpenAI',
          useAzureApiKeyHeader: true,
        );
      case 'custom':
        return _postCustomText(settings, combinedPrompt);
      case 'zhipu_glm':
        return _postZhipuGlmText(settings, combinedPrompt);
      default:
        throw Exception('Unsupported provider: ${settings.selectedProvider}');
    }
  }
```

Add text post helpers:

```dart
  Future<Map<String, dynamic>> _postOpenAiCompatibleText({
    required Uri uri,
    required String apiKey,
    required String model,
    required String prompt,
    required String label,
    bool useAzureApiKeyHeader = false,
  }) async {
    final response = await _client
        .post(
          uri,
          headers: _jsonHeaders(
            apiKey,
            useAzureApiKeyHeader: useAzureApiKeyHeader,
          ),
          body: jsonEncode({
            'model': _requireNonEmpty(model, '$label model'),
            'messages': [
              {
                'role': 'user',
                'content': [
                  {'type': 'text', 'text': prompt},
                ],
              },
            ],
          }),
        )
        .timeout(AppConfig.apiTimeout);

    if (response.statusCode != 200) {
      throw Exception(
          '$label API error: ${response.statusCode} - ${response.body}');
    }

    final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
    return _decodeModelJson(_extractChatCompletionContent(jsonData, label));
  }

  Future<Map<String, dynamic>> _postAnthropicText({
    required Uri uri,
    required String apiKey,
    required String model,
    required String prompt,
    required String label,
  }) async {
    final response = await _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': _requireNonEmpty(apiKey, '$label API key'),
            'anthropic-version': AppConfig.anthropicVersion,
          },
          body: jsonEncode({
            'model': _requireNonEmpty(model, '$label model'),
            'max_tokens': 800,
            'messages': [
              {
                'role': 'user',
                'content': [
                  {'type': 'text', 'text': prompt},
                ],
              },
            ],
          }),
        )
        .timeout(AppConfig.apiTimeout);

    if (response.statusCode != 200) {
      throw Exception(
          '$label API error: ${response.statusCode} - ${response.body}');
    }

    final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
    return _decodeModelJson(_extractAnthropicContent(jsonData, label));
  }
```

Add custom and Zhipu text helpers:

```dart
  Future<Map<String, dynamic>> _postCustomText(
    AppSettings settings,
    String prompt,
  ) {
    final baseUrl = _requireNonEmpty(settings.customBaseUrl, 'Custom base URL');
    final model = _requireNonEmpty(settings.customModel, 'Custom model');

    if (settings.customUrlType == 'anthropic') {
      return _postAnthropicText(
        uri: _appendEndpoint(baseUrl, 'messages'),
        apiKey: settings.apiKey,
        model: model,
        prompt: prompt,
        label: 'Custom Anthropic-compatible',
      );
    }

    return _postOpenAiCompatibleText(
      uri: _appendEndpoint(baseUrl, 'chat/completions'),
      apiKey: settings.apiKey,
      model: model,
      prompt: prompt,
      label: 'Custom OpenAI-compatible',
    );
  }

  Future<Map<String, dynamic>> _postZhipuGlmText(
    AppSettings settings,
    String prompt,
  ) async {
    final response = await _client
        .post(
          Uri.parse(AppConfig.zhipuGlmApiUrl),
          headers: _jsonHeaders(settings.apiKey),
          body: jsonEncode({
            'model': AppConfig.zhipuGlmVisionModel,
            'messages': [
              {
                'role': 'user',
                'content': [
                  {'type': 'text', 'text': prompt},
                ],
              },
            ],
            'thinking': {'type': 'disabled'},
          }),
        )
        .timeout(AppConfig.apiTimeout);

    if (response.statusCode != 200) {
      throw Exception(
        'Zhipu GLM API error: ${response.statusCode} - ${response.body}',
      );
    }

    final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
    return _decodeModelJson(
      _extractChatCompletionContent(jsonData, 'Zhipu GLM'),
    );
  }
```

Add prompt constant:

```dart
  static const String _sceneRecommendationPrompt = '''
You are a professional photography assistant. The image has already been understood by a local model. Use only the local scene understanding JSON to return valid JSON with this exact shape:
{
  "scene_description": "one concise objective description of the visible image content",
  "shooting_advice": "one concise composition, lighting, or angle suggestion",
  "camera_params": {
    "iso": "recommended ISO",
    "exposure": "recommended exposure compensation",
    "focus": "recommended focus mode",
    "white_balance": "recommended white balance"
  },
  "filter_suggestions": ["2-3 suitable filter names"]
}
Return all text values in Chinese (Simplified Chinese). Keep JSON keys exactly as shown.
Do not include post-processing or edit parameters.
Do not wrap the JSON in markdown.
''';
```

- [ ] **Step 5: Run API tests**

Run:

```bash
cd /Users/xiyu.chen/toys/SmartCamera/smart_cam
flutter test test/unit/analysis_api_repository_test.dart
```

Expected: pass.

- [ ] **Step 6: Commit**

```bash
cd /Users/xiyu.chen/toys/SmartCamera
git add smart_cam/lib/features/analysis/domain/recommendation_repository.dart \
  smart_cam/lib/features/analysis/data/analysis_api_repository.dart \
  smart_cam/test/unit/analysis_api_repository_test.dart
git commit -m "feat: recommend from local scene context"
```

---

### Task 5: Orchestrate Local-First Analysis With Fallback

**Files:**
- Modify: `smart_cam/lib/features/analysis/presentation/analysis_service.dart`
- Test: `smart_cam/test/unit/analysis_service_test.dart`

- [ ] **Step 1: Write failing orchestration tests**

Add imports in `smart_cam/test/unit/analysis_service_test.dart`:

```dart
import 'package:smart_cam/features/analysis/domain/recommendation_repository.dart';
import 'package:smart_cam/features/settings/domain/app_settings.dart';
import 'package:smart_cam/features/scene_understanding/domain/scene_understanding_exception.dart';
import 'package:smart_cam/features/scene_understanding/domain/scene_understanding_repository.dart';
import 'package:smart_cam/features/scene_understanding/domain/scene_understanding_result.dart';
import 'package:smart_cam/features/scene_understanding/domain/scene_understanding_status.dart';
```

Add fake classes after `_FakeAnalysisRepository`:

```dart
class _FakeRecommendationRepository implements RecommendationRepository {
  _FakeRecommendationRepository(this._handler);

  final Future<AnalysisResult> Function(Map<String, dynamic> sceneJson)
      _handler;
  int requestCount = 0;
  Map<String, dynamic>? lastSceneJson;

  @override
  Future<AnalysisResult> recommendFromScene(Map<String, dynamic> sceneJson) {
    requestCount += 1;
    lastSceneJson = sceneJson;
    return _handler(sceneJson);
  }
}

class _FakeSceneRepository implements SceneUnderstandingRepository {
  _FakeSceneRepository(this._handler);

  final Future<SceneUnderstandingResult> Function(Uint8List imageData)
      _handler;
  int requestCount = 0;

  @override
  Future<SceneUnderstandingResult> analyzeScene(Uint8List imageData) {
    requestCount += 1;
    return _handler(imageData);
  }
}
```

Append tests inside the existing group:

```dart
    test('local disabled keeps current image analysis path', () async {
      var remoteImageRequests = 0;
      final sceneRepository = _FakeSceneRepository((_) async {
        fail('Scene repository should not run when local mode is disabled');
      });

      final service = AnalysisService(
        repository: _FakeAnalysisRepository((_) async {
          remoteImageRequests += 1;
          return AnalysisResult(
            shootingAdvice: '现有流程',
            cameraParams: const {},
            filterSuggestions: const [],
            editParams: const {},
          );
        }),
        recommendationRepository: _FakeRecommendationRepository((_) async {
          fail('Recommendation repository should not run');
        }),
        sceneRepository: sceneRepository,
        settingsProvider: () => AppSettings(
          enableLocalSceneUnderstanding: false,
        ),
      );

      final started = await service.analyzeNow(Uint8List.fromList([1]));

      expect(started, isTrue);
      expect(remoteImageRequests, 1);
      expect(sceneRepository.requestCount, 0);
      expect(service.localSceneStatus, LocalSceneRunStatus.off);
    });

    test('local success uses scene recommendation path', () async {
      var remoteImageRequests = 0;
      final recommendationRepository =
          _FakeRecommendationRepository((sceneJson) async {
        return AnalysisResult(
          shootingAdvice: '根据本地识别推荐',
          cameraParams: const {'iso': '200'},
          filterSuggestions: const ['自然'],
          editParams: const {},
        );
      });

      final service = AnalysisService(
        repository: _FakeAnalysisRepository((_) async {
          remoteImageRequests += 1;
          throw Exception('fallback should not run');
        }),
        recommendationRepository: recommendationRepository,
        sceneRepository: _FakeSceneRepository((_) async {
          return SceneUnderstandingResult.fromJson({
            'summary': '一个人在窗边喝咖啡',
            'scene_type': 'indoor',
            'objects': const [],
            'relationships': const [],
            'quality_notes': const ['侧光'],
          });
        }),
        settingsProvider: () => AppSettings(
          enableLocalSceneUnderstanding: true,
        ),
      );

      final started = await service.analyzeNow(Uint8List.fromList([1]));

      expect(started, isTrue);
      expect(remoteImageRequests, 0);
      expect(recommendationRepository.requestCount, 1);
      expect(recommendationRepository.lastSceneJson!['summary'], '一个人在窗边喝咖啡');
      expect(service.currentResult!.shootingAdvice, '根据本地识别推荐');
      expect(service.localSceneStatus, LocalSceneRunStatus.success);
    });

    test('local failure falls back to existing image analysis path', () async {
      var remoteImageRequests = 0;

      final service = AnalysisService(
        repository: _FakeAnalysisRepository((_) async {
          remoteImageRequests += 1;
          return AnalysisResult(
            shootingAdvice: '降级后现有流程',
            cameraParams: const {},
            filterSuggestions: const [],
            editParams: const {},
          );
        }),
        recommendationRepository: _FakeRecommendationRepository((_) async {
          fail('Recommendation repository should not run after scene failure');
        }),
        sceneRepository: _FakeSceneRepository((_) async {
          throw const SceneUnderstandingException(
            SceneUnderstandingStatus.timeout,
            'timeout',
          );
        }),
        settingsProvider: () => AppSettings(
          enableLocalSceneUnderstanding: true,
        ),
      );

      final started = await service.analyzeNow(Uint8List.fromList([1]));

      expect(started, isTrue);
      expect(remoteImageRequests, 1);
      expect(service.currentResult!.shootingAdvice, '降级后现有流程');
      expect(service.localSceneStatus, LocalSceneRunStatus.fallback);
      expect(service.localSceneMessage, contains('timeout'));
    });
```

- [ ] **Step 2: Run analysis service tests and verify failure**

Run:

```bash
cd /Users/xiyu.chen/toys/SmartCamera/smart_cam
flutter test test/unit/analysis_service_test.dart
```

Expected: fails because `recommendationRepository`, `sceneRepository`, `settingsProvider`, and local debug status do not exist.

- [ ] **Step 3: Add local status enum and constructor dependencies**

In `smart_cam/lib/features/analysis/presentation/analysis_service.dart`, add imports:

```dart
import '../../settings/domain/app_settings.dart';
import '../domain/recommendation_repository.dart';
import '../../scene_understanding/domain/scene_understanding_exception.dart';
import '../../scene_understanding/domain/scene_understanding_repository.dart';
```

Add typedef and enum above `AnalysisService`:

```dart
typedef AnalysisSettingsProvider = AppSettings Function();

enum LocalSceneRunStatus {
  off,
  analyzing,
  success,
  fallback,
}
```

Change fields and constructor:

```dart
  final AnalysisRepository _repository;
  final RecommendationRepository? _recommendationRepository;
  final SceneUnderstandingRepository? _sceneRepository;
  final AnalysisSettingsProvider _settingsProvider;
```

```dart
  LocalSceneRunStatus _localSceneStatus = LocalSceneRunStatus.off;
  String? _localSceneMessage;
```

```dart
  AnalysisService({
    required AnalysisRepository repository,
    RecommendationRepository? recommendationRepository,
    SceneUnderstandingRepository? sceneRepository,
    AnalysisSettingsProvider? settingsProvider,
  })  : _repository = repository,
        _recommendationRepository = recommendationRepository,
        _sceneRepository = sceneRepository,
        _settingsProvider = settingsProvider ?? (() => AppSettings());
```

Add getters:

```dart
  LocalSceneRunStatus get localSceneStatus => _localSceneStatus;

  String? get localSceneMessage => _localSceneMessage;
```

- [ ] **Step 4: Replace the repository call inside `_runAnalysis`**

Inside `_runAnalysis`, replace:

```dart
      final result = await _repository.analyzeImage(imageData);
```

with:

```dart
      final result = await _analyzeWithConfiguredPath(imageData);
```

Add this helper method to `AnalysisService`:

```dart
  Future<AnalysisResult> _analyzeWithConfiguredPath(
    Uint8List imageData,
  ) async {
    final settings = _settingsProvider();
    if (!settings.enableLocalSceneUnderstanding ||
        _sceneRepository == null ||
        _recommendationRepository == null) {
      _localSceneStatus = LocalSceneRunStatus.off;
      _localSceneMessage = null;
      return _repository.analyzeImage(imageData);
    }

    try {
      _localSceneStatus = LocalSceneRunStatus.analyzing;
      _localSceneMessage = '本地模型识别中';
      notifyListeners();

      final scene = await _sceneRepository.analyzeScene(imageData);
      final result = await _recommendationRepository.recommendFromScene(
        scene.toJson(),
      );
      _localSceneStatus = LocalSceneRunStatus.success;
      _localSceneMessage = '本地模型识别成功';
      return result;
    } on SceneUnderstandingException catch (e) {
      _localSceneStatus = LocalSceneRunStatus.fallback;
      _localSceneMessage = e.message;
      AppLogger.e('Local scene understanding failed', 'AnalysisService', e);
      return _repository.analyzeImage(imageData);
    } catch (e) {
      _localSceneStatus = LocalSceneRunStatus.fallback;
      _localSceneMessage = e.toString();
      AppLogger.e('Local scene understanding failed', 'AnalysisService', e);
      return _repository.analyzeImage(imageData);
    }
  }
```

Update `clearResult()` to reset local status:

```dart
    _localSceneStatus = LocalSceneRunStatus.off;
    _localSceneMessage = null;
```

- [ ] **Step 5: Run analysis service tests**

Run:

```bash
cd /Users/xiyu.chen/toys/SmartCamera/smart_cam
flutter test test/unit/analysis_service_test.dart
```

Expected: pass.

- [ ] **Step 6: Commit**

```bash
cd /Users/xiyu.chen/toys/SmartCamera
git add smart_cam/lib/features/analysis/presentation/analysis_service.dart \
  smart_cam/test/unit/analysis_service_test.dart
git commit -m "feat: orchestrate local scene fallback"
```

---

### Task 6: Wire Scene Understanding in App Startup

**Files:**
- Modify: `smart_cam/lib/main.dart`
- Test: existing unit/widget suite compile check

- [ ] **Step 1: Update imports**

Add imports to `smart_cam/lib/main.dart`:

```dart
import 'dart:io' show Platform;
import 'features/scene_understanding/data/bundled_scene_model_store.dart';
import 'features/scene_understanding/data/litert_lm_scene_repository.dart';
import 'features/scene_understanding/data/unsupported_scene_repository.dart';
import 'features/scene_understanding/domain/scene_understanding_repository.dart';
import 'features/scene_understanding/platform/scene_understanding_channel.dart';
```

- [ ] **Step 2: Add scene repository field**

Add a field to `_SmartCamAppState`:

```dart
  late final SceneUnderstandingRepository _sceneUnderstandingRepository;
```

- [ ] **Step 3: Construct repositories**

In `_initializeServices`, after `_cameraService = CameraService();`, add:

```dart
    final modelStore = const BundledSceneModelStore();
    _sceneUnderstandingRepository = Platform.isAndroid
        ? LiteRtLmSceneRepository.android(
            channel: MethodChannelSceneUnderstandingChannel(),
            modelPathProvider: modelStore.resolveModelPath,
          )
        : const UnsupportedSceneRepository(
            message: 'Local scene understanding is not available on iOS MVP',
          );
```

Change `AnalysisService` construction from:

```dart
    _analysisService = AnalysisService(repository: analysisRepository);
```

to:

```dart
    _analysisService = AnalysisService(
      repository: analysisRepository,
      recommendationRepository: analysisRepository,
      sceneRepository: _sceneUnderstandingRepository,
      settingsProvider: () => _settingsService.settings,
    );
```

- [ ] **Step 4: Run compile-focused tests**

Run:

```bash
cd /Users/xiyu.chen/toys/SmartCamera/smart_cam
flutter test test/unit/analysis_service_test.dart test/widget/debug_panel_scene_description_test.dart
```

Expected: pass.

- [ ] **Step 5: Commit**

```bash
cd /Users/xiyu.chen/toys/SmartCamera
git add smart_cam/lib/main.dart
git commit -m "feat: wire local scene repository"
```

---

### Task 7: Add Settings UI and Debug Rows

**Files:**
- Modify: `smart_cam/lib/features/settings/presentation/pages/settings_page.dart`
- Modify: `smart_cam/lib/features/camera/presentation/pages/camera_page.dart`
- Test: `smart_cam/test/unit/settings_service_test.dart`
- Test: `smart_cam/test/widget/debug_panel_scene_description_test.dart`

- [ ] **Step 1: Add widget test for debug local model status**

Append to `smart_cam/test/widget/debug_panel_scene_description_test.dart`:

```dart
testWidgets('debug panel shows local model fallback status', (tester) async {
  final cameraService = CameraService();
  final analysisService = AnalysisService(
    repository: _FakeAnalysisRepository(),
  );
  final settingsService = SettingsService();
  settingsService.toggleLocalSceneUnderstanding(true);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CameraService>.value(value: cameraService),
        ChangeNotifierProvider<AnalysisService>.value(
          value: analysisService,
        ),
        ChangeNotifierProvider<AnalysisCoordinator>(
          create: (_) => AnalysisCoordinator(cameraService: cameraService),
        ),
        ChangeNotifierProvider<SettingsService>.value(value: settingsService),
        ChangeNotifierProvider<PhotoStorageService>(
          create: (_) => PhotoStorageService(),
        ),
      ],
      child: const MaterialApp(
        home: CameraPage(),
      ),
    ),
  );

  expect(find.textContaining('本地模型: 开启'), findsOneWidget);
});
```

- [ ] **Step 2: Run widget test and verify failure**

Run:

```bash
cd /Users/xiyu.chen/toys/SmartCamera/smart_cam
flutter test test/widget/debug_panel_scene_description_test.dart
```

Expected: fails because debug row does not exist.

- [ ] **Step 3: Add switch to settings page**

In `smart_cam/lib/features/settings/presentation/pages/settings_page.dart`, inside `_buildToggleSection`, add this `SwitchListTile` after manual analysis or grid line controls:

```dart
        SwitchListTile(
          title: const Text('Use Local Model'),
          subtitle: const Text(
            'Locally understand scene content before requesting recommendations',
          ),
          value: settings.enableLocalSceneUnderstanding,
          onChanged: (value) {
            settingsService.toggleLocalSceneUnderstanding(value);
          },
        ),
```

- [ ] **Step 4: Add debug row formatters**

In `smart_cam/lib/features/camera/presentation/pages/camera_page.dart`, add local rows inside `_buildLlmDebugRows` after API row:

```dart
      _buildDebugLine(
        '本地模型: ${_formatLocalSceneStatus(analysisService, settingsService)}',
        maxLines: 2,
      ),
```

Add helper method near `_formatProvider`:

```dart
  String _formatLocalSceneStatus(
    AnalysisService analysisService,
    SettingsService settingsService,
  ) {
    if (!settingsService.settings.enableLocalSceneUnderstanding) {
      return '关闭';
    }

    switch (analysisService.localSceneStatus) {
      case LocalSceneRunStatus.off:
        return '开启';
      case LocalSceneRunStatus.analyzing:
        return '识别中';
      case LocalSceneRunStatus.success:
        return '成功';
      case LocalSceneRunStatus.fallback:
        final message = analysisService.localSceneMessage;
        return message == null ? '失败后降级' : '失败后降级 - $message';
    }
  }
```

- [ ] **Step 5: Run UI tests**

Run:

```bash
cd /Users/xiyu.chen/toys/SmartCamera/smart_cam
flutter test test/widget/debug_panel_scene_description_test.dart test/unit/settings_service_test.dart
```

Expected: pass.

- [ ] **Step 6: Commit**

```bash
cd /Users/xiyu.chen/toys/SmartCamera
git add smart_cam/lib/features/settings/presentation/pages/settings_page.dart \
  smart_cam/lib/features/camera/presentation/pages/camera_page.dart \
  smart_cam/test/widget/debug_panel_scene_description_test.dart
git commit -m "feat: expose local model setting"
```

---

### Task 8: Add Android LiteRT-LM MethodChannel

**Files:**
- Modify: `smart_cam/android/app/build.gradle`
- Modify: `smart_cam/android/app/src/main/kotlin/com/example/smart_cam/MainActivity.kt`
- Create: `smart_cam/android/app/src/main/kotlin/com/example/smart_cam/SceneUnderstandingChannel.kt`
- Create: `smart_cam/android/app/src/main/kotlin/com/example/smart_cam/LiteRtLmSceneAnalyzer.kt`

- [ ] **Step 1: Add Android dependency**

Modify `smart_cam/android/app/build.gradle`:

```gradle
android {
    namespace "com.example.smart_cam"
    compileSdk 36
    ndkVersion "27.3.13750724"

    aaptOptions {
        noCompress "litertlm"
    }
```

Replace the empty dependencies block:

```gradle
dependencies {}
```

with:

```gradle
dependencies {
    implementation "com.google.ai.edge.litertlm:litertlm-android:latest.release"
}
```

- [ ] **Step 2: Add analyzer wrapper**

Create `smart_cam/android/app/src/main/kotlin/com/example/smart_cam/LiteRtLmSceneAnalyzer.kt`:

```kotlin
package com.example.smart_cam

import android.content.Context
import com.google.ai.edge.litertlm.Backend
import com.google.ai.edge.litertlm.Content
import com.google.ai.edge.litertlm.Contents
import com.google.ai.edge.litertlm.Engine
import com.google.ai.edge.litertlm.EngineConfig
import java.io.File
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

data class SceneAnalysisResponse(
    val status: String,
    val rawText: String?,
    val latencyMs: Long,
    val errorMessage: String?
)

class LiteRtLmSceneAnalyzer(private val context: Context) {
    suspend fun analyze(
        imagePath: String,
        modelPath: String,
        prompt: String
    ): SceneAnalysisResponse = withContext(Dispatchers.Default) {
        val startedAt = System.currentTimeMillis()

        val imageFile = File(imagePath)
        if (!imageFile.exists()) {
            return@withContext SceneAnalysisResponse(
                status = "unavailable",
                rawText = null,
                latencyMs = System.currentTimeMillis() - startedAt,
                errorMessage = "Image file does not exist: $imagePath"
            )
        }

        val modelFile = File(modelPath)
        if (!modelFile.exists()) {
            return@withContext SceneAnalysisResponse(
                status = "unavailable",
                rawText = null,
                latencyMs = System.currentTimeMillis() - startedAt,
                errorMessage = "Model file does not exist: $modelPath"
            )
        }

        try {
            val rawText = LiteRtLmRuntime.runVisionPrompt(
                context = context,
                modelPath = modelFile.absolutePath,
                imagePath = imageFile.absolutePath,
                prompt = prompt
            )
            SceneAnalysisResponse(
                status = "success",
                rawText = rawText,
                latencyMs = System.currentTimeMillis() - startedAt,
                errorMessage = null
            )
        } catch (error: Throwable) {
            SceneAnalysisResponse(
                status = "native_error",
                rawText = null,
                latencyMs = System.currentTimeMillis() - startedAt,
                errorMessage = error.message ?: error.javaClass.simpleName
            )
        }
    }
}

object LiteRtLmRuntime {
    fun runVisionPrompt(
        context: Context,
        modelPath: String,
        imagePath: String,
        prompt: String
    ): String {
        val engineConfig = EngineConfig(
            modelPath = modelPath,
            backend = Backend.CPU(),
            visionBackend = Backend.CPU(),
            cacheDir = context.cacheDir.absolutePath
        )

        Engine(engineConfig).use { engine ->
            engine.initialize()
            engine.createConversation().use { conversation ->
                val message = conversation.sendMessage(
                    Contents.of(
                        Content.ImageFile(imagePath),
                        Content.Text(prompt)
                    )
                )
                return message.toString()
            }
        }
    }
}
```

This uses the documented LiteRT-LM Kotlin API shape: `EngineConfig`, `Engine.initialize()`, `createConversation()`, and multimodal `Contents.of(Content.ImageFile(...), Content.Text(...))`.

- [ ] **Step 3: Add MethodChannel registration**

Create `smart_cam/android/app/src/main/kotlin/com/example/smart_cam/SceneUnderstandingChannel.kt`:

```kotlin
package com.example.smart_cam

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class SceneUnderstandingChannel(
    flutterEngine: FlutterEngine,
    private val analyzer: LiteRtLmSceneAnalyzer
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    init {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "smart_cam/scene_understanding"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "analyze" -> analyze(call, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun analyze(call: MethodCall, result: MethodChannel.Result) {
        val imagePath = call.argument<String>("imagePath")
        val modelPath = call.argument<String>("modelPath")
        val prompt = call.argument<String>("prompt")

        if (imagePath.isNullOrBlank() ||
            modelPath.isNullOrBlank() ||
            prompt.isNullOrBlank()
        ) {
            result.success(
                mapOf(
                    "status" to "unavailable",
                    "rawText" to null,
                    "latencyMs" to 0,
                    "errorMessage" to "imagePath, modelPath, and prompt are required"
                )
            )
            return
        }

        scope.launch {
            val response = analyzer.analyze(
                imagePath = imagePath,
                modelPath = modelPath,
                prompt = prompt
            )
            withContext(Dispatchers.Main) {
                result.success(
                    mapOf(
                        "status" to response.status,
                        "rawText" to response.rawText,
                        "latencyMs" to response.latencyMs.toInt(),
                        "errorMessage" to response.errorMessage
                    )
                )
            }
        }
    }
}
```

- [ ] **Step 4: Register channel in `MainActivity`**

Replace `smart_cam/android/app/src/main/kotlin/com/example/smart_cam/MainActivity.kt` with:

```kotlin
package com.example.smart_cam

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        SceneUnderstandingChannel(
            flutterEngine = flutterEngine,
            analyzer = LiteRtLmSceneAnalyzer(applicationContext)
        )
    }
}
```

- [ ] **Step 5: Run Android compile**

Run:

```bash
cd /Users/xiyu.chen/toys/SmartCamera/smart_cam
flutter build apk --debug
```

Expected: build succeeds. If dependency resolution fails, verify Google Maven is available in `smart_cam/android/build.gradle` and use the current LiteRT-LM dependency coordinate from official docs.

- [ ] **Step 6: Commit**

```bash
cd /Users/xiyu.chen/toys/SmartCamera
git add smart_cam/android/app/build.gradle \
  smart_cam/android/app/src/main/kotlin/com/example/smart_cam/MainActivity.kt \
  smart_cam/android/app/src/main/kotlin/com/example/smart_cam/SceneUnderstandingChannel.kt \
  smart_cam/android/app/src/main/kotlin/com/example/smart_cam/LiteRtLmSceneAnalyzer.kt
git commit -m "feat: add Android scene understanding channel"
```

---

### Task 9: Add Local Model Manual Validation Path

**Files:**
- Modify: `smart_cam/assets/models/README.md`
- Modify: `docs/superpowers/specs/2026-05-13-local-scene-understanding-design.md`

- [ ] **Step 1: Document the local validation command**

Append to `smart_cam/assets/models/README.md`:

```markdown
## Manual Android MVP Validation

1. Place the Gemma 4 E2B LiteRT-LM model at:

   `assets/models/gemma-4-E2B-it-litert-lm.litertlm`

2. Run:

   ```bash
   cd /Users/xiyu.chen/toys/SmartCamera/smart_cam
   flutter pub get
   flutter build apk --debug
   flutter run -d <android-device-id>
   ```

3. In Settings, enable `Use Local Model`.

4. Trigger analysis from the camera screen.

Expected:

- If the model file exists and native runtime is wired, debug UI shows `本地模型: 成功`.
- If the model file is missing or native runtime returns an error, debug UI shows `本地模型: 失败后降级`, and the app still returns the existing remote LLM recommendation.
```

- [ ] **Step 2: Add validation note to spec**

Append to `docs/superpowers/specs/2026-05-13-local-scene-understanding-design.md` under `Manual MVP checks`:

```markdown
- Local model missing: debug UI reports fallback and the existing image-based LLM API still returns recommendations.
- Local model present but native runtime throws: debug UI reports fallback and the existing image-based LLM API still returns recommendations.
```

- [ ] **Step 3: Commit docs**

```bash
cd /Users/xiyu.chen/toys/SmartCamera
git add smart_cam/assets/models/README.md \
  docs/superpowers/specs/2026-05-13-local-scene-understanding-design.md
git commit -m "docs: add local model validation notes"
```

---

### Task 10: Final Verification

**Files:**
- No new files.
- Verify all files changed by previous tasks.

- [ ] **Step 1: Run Dart formatting**

Run:

```bash
cd /Users/xiyu.chen/toys/SmartCamera/smart_cam
dart format lib test
```

Expected: formatter exits with code 0.

- [ ] **Step 2: Run Flutter analyze**

Run:

```bash
cd /Users/xiyu.chen/toys/SmartCamera/smart_cam
flutter analyze
```

Expected: no analyzer errors.

- [ ] **Step 3: Run unit and widget tests**

Run:

```bash
cd /Users/xiyu.chen/toys/SmartCamera/smart_cam
flutter test
```

Expected: all tests pass.

- [ ] **Step 4: Run Android debug build**

Run:

```bash
cd /Users/xiyu.chen/toys/SmartCamera/smart_cam
flutter build apk --debug
```

Expected: debug APK builds successfully.

- [ ] **Step 5: Verify fallback behavior manually**

Run on Android without adding the model file:

```bash
cd /Users/xiyu.chen/toys/SmartCamera/smart_cam
flutter run -d <android-device-id>
```

Actions:

1. Open Settings.
2. Turn on `Use Local Model`.
3. Return to camera.
4. Trigger manual or automatic analysis.

Expected:

- Debug panel shows local model fallback.
- Existing LLM image-analysis result still appears.
- App does not crash.

- [ ] **Step 6: Commit verification-only cleanup if formatting changed files**

Run:

```bash
cd /Users/xiyu.chen/toys/SmartCamera
git status --short
```

If formatting changed files, commit them:

```bash
git add smart_cam/lib smart_cam/test
git commit -m "chore: format local scene understanding"
```

If no files changed, do not create an empty commit.

---

## Self-Review

Spec coverage:

- Optional local setting: Task 1 and Task 7.
- Android offline validation with LiteRT-LM: Task 8 and Task 9.
- iOS architecture fallback: Task 3 and Task 5 through `UnsupportedSceneRepository`.
- Scene objects, states, relationships, quality notes: Task 2 and Task 3 prompt contract.
- Existing-flow fallback: Task 5 tests and implementation.
- Recommendation from scene JSON: Task 4.
- Debug rows: Task 7.
- Tests: Tasks 1 through 5, Task 7, Task 10.
- Model bundled now, dynamic delivery path preserved: Task 3 `BundledSceneModelStore` and Task 9 asset notes.

Red-flag scan:

- No open-ended task remains.
- The Android runtime bridge calls the documented LiteRT-LM Kotlin API and still reports typed failures so Dart can fall back to the existing image-analysis path.

Type consistency:

- `SceneUnderstandingStatus`, `SceneUnderstandingResult`, `SceneUnderstandingException`, `SceneUnderstandingRepository`, `RecommendationRepository`, and `LocalSceneRunStatus` names are consistent across tasks.
- `enableLocalSceneUnderstanding` is used consistently in settings, service orchestration, and UI.

## References

- Spec: `docs/superpowers/specs/2026-05-13-local-scene-understanding-design.md`
- LiteRT-LM: https://ai.google.dev/edge/litert-lm
- Gemma 4 LiteRT-LM: https://ai.google.dev/edge/litert-lm/models/gemma-4
- LiteRT-LM Kotlin getting started: https://github.com/google-ai-edge/LiteRT-LM/blob/main/docs/api/kotlin/getting_started.md
