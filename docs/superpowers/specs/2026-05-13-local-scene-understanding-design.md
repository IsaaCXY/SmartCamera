# Local Scene Understanding Design

Date: 2026-05-13

## Summary

Add an optional local scene understanding path before the existing LLM image analysis flow. MVP uses LiteRT-LM with Gemma 4 E2B on Android for offline validation. iOS keeps the same architecture but falls back to the existing remote image-analysis flow until a local iOS runtime is implemented.

When the setting is disabled, behavior is identical to the current app. When enabled, the app first asks the local model to produce structured scene understanding, then sends that structure to the existing LLM API path for photography recommendations. If local understanding fails, the app falls back to the current image-based LLM API flow.

## Goals

- Understand scene content locally, not just detect object labels.
- Capture visible objects, object attributes, object states, relationships, scene type, and quality notes.
- Keep Android MVP offline for the scene-understanding step.
- Keep iOS extensible without blocking MVP.
- Preserve the current user experience when the local model path is disabled or unavailable.
- Support bundled model assets in MVP and leave a clean path for dynamic model delivery later.

## Non-Goals

- Do not replace the recommendation API in MVP.
- Do not require iOS local inference in MVP.
- Do not change camera capture behavior except for routing analysis frames through the optional local path.
- Do not add unrelated ML capabilities such as training, photo editing, or model fine-tuning.

## Current Context

The app currently routes analysis through `AnalysisRepository.analyzeImage(Uint8List imageData)` and `AnalysisApiRepository`, where a remote vision-capable provider receives the image and returns `AnalysisResult`.

This design splits the pipeline into two conceptual steps:

1. Local scene understanding.
2. Recommendation generation.

The split keeps model-specific runtime code out of API provider selection and allows future local/remote scene understanding providers to share one domain contract.

## User Setting

Add a persisted setting:

```dart
bool enableLocalSceneUnderstanding;
```

Default: `false`.

Reason: the MVP model is large and may add load time, memory pressure, and battery cost. The feature should not alter existing behavior unless the user explicitly enables it.

Settings UI:

```text
Use Local Model
Locally understand scene content before requesting recommendations. Falls back to the existing LLM API flow if unavailable.
```

Runtime behavior:

```text
setting off -> existing image-based LLM API flow
setting on  -> local scene understanding -> recommendation API
             -> fallback to existing image-based LLM API flow on failure
```

## Architecture

New module:

```text
lib/features/scene_understanding/
  domain/
    scene_understanding_repository.dart
    scene_understanding_result.dart
    scene_object.dart
    scene_relationship.dart
    scene_understanding_status.dart
  data/
    litert_lm_scene_repository.dart
    unsupported_scene_repository.dart
  platform/
    scene_understanding_channel.dart
```

High-level flow:

```text
CameraService analysis frame
  -> ImagePreprocessor
  -> AnalysisService
     -> if local disabled:
          AnalysisRepository.analyzeImage(imageData)
     -> if local enabled:
          SceneUnderstandingRepository.analyzeScene(imageData)
          -> success:
               RecommendationRepository.recommendFromScene(scene)
          -> failure:
               AnalysisRepository.analyzeImage(imageData)
  -> AnalysisResult
  -> UI
```

`RecommendationRepository` can be backed by the existing API implementation, but it must accept scene JSON instead of image bytes. The important boundary is that scene understanding returns structured content, while the recommendation layer returns the existing `AnalysisResult` shape used by UI and photo metadata.

## Domain Model

`SceneUnderstandingResult`:

```dart
class SceneUnderstandingResult {
  final String summary;
  final String sceneType;
  final List<SceneObject> objects;
  final List<SceneRelationship> relationships;
  final List<String> qualityNotes;
  final SceneUnderstandingRuntime runtime;
}
```

`SceneObject`:

```dart
class SceneObject {
  final String id;
  final String name;
  final List<String> attributes;
  final String state;
  final double? confidence;
}
```

`SceneRelationship`:

```dart
class SceneRelationship {
  final String subjectId;
  final String relation;
  final String objectId;
  final double? confidence;
}
```

`SceneUnderstandingRuntime`:

```dart
class SceneUnderstandingRuntime {
  final String provider;      // litert_lm, unsupported, remote_fallback
  final String modelId;       // gemma-4-E2B-it-litert-lm
  final String modelVersion;
  final int latencyMs;
  final String status;        // success, unavailable, timeout, parse_error
  final String? errorMessage;
}
```

## Android MVP

Use LiteRT-LM with Gemma 4 E2B through Android native code.

Flutter calls Android through `MethodChannel`:

```text
scene_understanding/analyze
input:
  temporary resized JPEG path
  prompt version
  timeoutMs
output:
  JSON string
```

Android native responsibilities:

- Load bundled `.litertlm` model.
- Prewarm the model when local scene understanding is enabled.
- Convert or pass the analysis image to LiteRT-LM as required by the runtime.
- Run prompt-based inference.
- Return raw model output and runtime metadata.
- Release model resources when the app shuts down or local mode is disabled.

MVP model source:

```text
bundled asset: Gemma 4 E2B LiteRT-LM model
```

Future model source:

```text
ModelStore
  bundled
  downloaded
  checksum verified
  version selected
  rollback supported
```

## iOS MVP

iOS implements the same Dart-facing repository contract but does not need local inference in MVP.

Behavior:

```text
enableLocalSceneUnderstanding = false -> existing flow
enableLocalSceneUnderstanding = true  -> unsupported result -> existing flow
```

The iOS MVP stub must preserve:

- Same `SceneUnderstandingRepository` interface.
- Same runtime status vocabulary.
- A clear insertion point for future LiteRT-LM C++ or native iOS integration.

## Prompt Contract

The local model prompt must request strict JSON only. It should ask for observable facts, not photography recommendations.

Expected output shape:

```json
{
  "summary": "one concise description of the scene",
  "scene_type": "portrait | landscape | food | street | indoor | document | other",
  "objects": [
    {
      "id": "person_1",
      "name": "person",
      "attributes": ["standing", "backlit"],
      "state": "still",
      "confidence": 0.72
    }
  ],
  "relationships": [
    {
      "subject": "person_1",
      "relation": "standing in front of",
      "object": "building_1",
      "confidence": 0.64
    }
  ],
  "quality_notes": ["backlit subject", "busy background"]
}
```

The recommendation API prompt should explicitly state that the input is a local scene-understanding result and should generate only photography advice in the existing `AnalysisResult` JSON format.

## Fallback Rules

Fallback must match the current flow.

Fallback triggers:

- Local feature disabled.
- Android model missing or not loaded.
- iOS local provider unsupported.
- LiteRT-LM timeout.
- Native bridge error.
- Model output is not valid JSON.
- Parsed JSON fails required schema checks.

Fallback action:

```text
AnalysisRepository.analyzeImage(imageData)
```

The user-facing analysis result remains the same shape as today. Debug UI may show that fallback occurred.

If cloud API is unavailable and local scene understanding succeeds, the app may display local scene summary in debug/UI, but full recommendation remains unavailable.

## Debug UI

Add lightweight debug rows:

```text
Local model: off | loading | analyzing | success | fallback
Model: Gemma 4 E2B
Latency: xxx ms
Fallback reason: timeout | parse_error | unsupported | unavailable
```

These rows should not replace the existing API validation or LLM provider rows.

## Testing

Unit tests:

- Setting default is false.
- Setting persists after reload.
- Local disabled calls only current image-based analysis path.
- Local enabled and scene success calls scene understanding, then recommendation.
- Local enabled and scene failure falls back to current image-based analysis path.
- iOS unsupported result falls back.
- Timeout, parse error, and invalid schema all fall back.
- Recommendation prompt uses scene JSON and does not include image bytes.

Widget tests:

- Settings page displays the local model switch.
- Switch updates persisted setting.
- Debug panel shows local model status when available.

Native/Integration tests:

- Android bridge returns a valid JSON string for a fixture image.
- Android bridge reports unavailable when the model asset is missing.
- Android bridge timeout is surfaced as a typed failure.

Manual MVP checks:

- Local model off: behavior matches current app.
- Local model on with bundled model: scene understanding completes on Android.
- Local model on with forced native failure: recommendation falls back to current remote image analysis.

## Risks

- Model size is large. Gemma 4 E2B LiteRT-LM is documented at about 2.58 GB, so bundled MVP is only suitable for validation.
- First load and prewarm may be slow.
- Battery and memory pressure may be noticeable on mid-range devices.
- JSON-only prompting can still fail; parser and fallback are required.
- iOS parity is intentionally deferred.

## External References

- LiteRT-LM: https://ai.google.dev/edge/litert-lm
- Gemma 4 LiteRT-LM: https://ai.google.dev/edge/litert-lm/models/gemma-4
- Google AI Edge: https://ai.google.dev/edge
- Apple Machine Learning & AI: https://developer.apple.com/machine-learning/
