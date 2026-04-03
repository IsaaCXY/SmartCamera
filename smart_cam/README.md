# Smart Camera App

A Flutter-based smart camera application with AI-powered shooting suggestions and editing recommendations.

## Features

- **Real-time Scene Analysis**: Automatically analyzes the scene in the viewfinder to provide shooting suggestions
- **AI-Powered Recommendations**: Get camera parameter suggestions and filter recommendations from large language models
- **Multi-Provider Support**: Flexible backend supporting OpenAI, Anthropic, Azure, and custom endpoints
- **Stability Detection**: Only triggers analysis when the scene is stable to avoid unnecessary API calls
- **Cross-Platform**: Built with Flutter for iOS and Android support (Android priority)

## Architecture

The app follows a clean architecture pattern with clear separation of concerns:

```
lib/
├── core/                    # Core utilities and configuration
│   ├── config/             # App configuration
│   ├── constants/          # Constants
│   └── utils/              # Utilities (logger, etc.)
├── features/               # Feature modules
│   ├── camera/            # Camera functionality
│   │   ├── data/         # Data layer
│   │   ├── domain/       # Business logic
│   │   └── presentation/ # UI and state management
│   ├── analysis/         # AI analysis feature
│   │   ├── data/         # API repository
│   │   ├── domain/       # Models and interfaces
│   │   └── presentation/ # Service and UI
│   └── settings/         # Settings management
└── main.dart            # App entry point
```

## Getting Started

### Prerequisites

- Flutter SDK 3.5.0 or higher
- Android Studio / Xcode for platform development
- API key from your preferred AI provider (OpenAI, Anthropic, etc.)

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure your API key in the app settings

4. Run the app:
   ```bash
   flutter run
   ```

## Configuration

### AI Provider Setup

The app supports multiple AI providers. Configure in Settings > AI Provider:

- **OpenAI**: Use GPT-4 Vision or similar
- **Anthropic**: Use Claude with vision capabilities
- **Azure OpenAI**: Enterprise deployment
- **Custom**: Your own endpoint

### API Format

The backend should accept POST requests with:
```json
{
  "image": "<base64_encoded_image>",
  "task": "camera_advice",
  "return_format": {
    "shooting_advice": "string",
    "camera_params": "object",
    "filter_suggestions": "array",
    "edit_params": "object"
  }
}
```

Expected response:
```json
{
  "shooting_advice": "Move slightly to the left for better composition",
  "camera_params": {
    "iso": "100",
    "exposure": "-0.3",
    "focus": "center"
  },
  "filter_suggestions": ["Warm", "Vivid", "Portrait"],
  "edit_params": {
    "brightness": "+10",
    "contrast": "+5",
    "saturation": "+8"
  }
}
```

## Key Components

### CameraService
Manages camera initialization, preview, and image capture. Handles frame comparison for stability detection.

### AnalysisService
Orchestrates the AI analysis workflow:
- Monitors frame stability
- Throttles API calls with cooldown period
- Manages analysis state and results

### AnalysisApiRepository
Communicates with the backend AI service. Supports multiple providers through a unified interface.

### Stability Detection
The app uses a simple frame-difference algorithm to detect scene stability:
1. Captures frames at 500ms intervals
2. Calculates pixel difference between consecutive frames
3. Triggers analysis only when scene is stable for N consecutive frames
4. Resets when significant scene change is detected

## Future Enhancements

- [ ] Image resizing before API upload
- [ ] Persistent settings storage
- [ ] Grid lines overlay on camera preview
- [ ] Photo gallery with edit history
- [ ] Direct integration with photo editing apps
- [ ] On-device ML for basic scene detection
- [ ] Batch analysis for burst mode

## License

MIT License
