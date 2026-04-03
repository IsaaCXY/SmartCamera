# Backend API Specification

This document describes the expected backend API for AI-powered camera suggestions.

## Overview

The backend should accept images and return shooting/editing suggestions using a large multimodal model (GPT-4V, Claude, etc.).

## API Endpoint

```
POST /api/analyze
Content-Type: application/json
Authorization: Bearer <api_key>
X-Provider: openai|anthropic|azure|custom
```

## Request Format

```json
{
  "image": "<base64_encoded_image_data>",
  "task": "camera_advice",
  "return_format": {
    "shooting_advice": "string - brief composition/lighting advice",
    "camera_params": "object - recommended camera settings",
    "filter_suggestions": "array - list of filter names",
    "edit_params": "object - post-processing adjustments"
  }
}
```

### System Prompt Template

Your backend should use a prompt like:

```
You are a professional photography assistant. Analyze this image and provide:

1. SHOOTING ADVICE: One concise tip about composition, lighting, or angle
2. CAMERA PARAMETERS: Suggested ISO, exposure compensation, focus mode, white balance
3. FILTER SUGGESTIONS: 2-3 filter styles that would enhance this photo
4. EDIT PARAMETERS: Specific adjustments for brightness, contrast, saturation, etc.

Be specific and actionable. Consider the scene type (portrait, landscape, macro, etc.)
```

## Response Format

### Success (200 OK)

```json
{
  "shooting_advice": "Try moving slightly lower to capture more sky and reduce foreground clutter",
  "camera_params": {
    "iso": "100",
    "exposure": "-0.3 EV",
    "focus": "single-point AF on subject",
    "white_balance": "5500K daylight",
    "aperture": "f/2.8 for shallow depth"
  },
  "filter_suggestions": ["Golden Hour", "Vivid Landscape", "Natural Contrast"],
  "edit_params": {
    "brightness": "+5",
    "contrast": "+10",
    "highlights": "-15",
    "shadows": "+20",
    "saturation": "+8",
    "sharpness": "+5"
  }
}
```

### Error Responses

#### 400 Bad Request
```json
{
  "error": "invalid_request",
  "message": "Image data is required"
}
```

#### 401 Unauthorized
```json
{
  "error": "authentication_failed",
  "message": "Invalid or missing API key"
}
```

#### 429 Too Many Requests
```json
{
  "error": "rate_limit_exceeded",
  "message": "Too many requests. Please try again in 60 seconds",
  "retry_after": 60
}
```

#### 500 Internal Server Error
```json
{
  "error": "processing_failed",
  "message": "Failed to analyze image. Please try again."
}
```

## Provider-Specific Implementation Examples

### OpenAI (GPT-4 Vision)

```python
from openai import OpenAI
import base64

client = OpenAI(api_key="your-key")

def analyze_image(base64_image: str) -> dict:
    response = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {
                "role": "system",
                "content": "You are a photography expert. Return JSON with: shooting_advice, camera_params, filter_suggestions, edit_params"
            },
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": "Analyze this photo for shooting tips"},
                    {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{base64_image}"}}
                ]
            }
        ],
        response_format={"type": "json_object"}
    )
    
    return json.loads(response.choices[0].message.content)
```

### Anthropic (Claude)

```python
from anthropic import Anthropic

client = Anthropic(api_key="your-key")

def analyze_image(base64_image: str) -> dict:
    response = client.messages.create(
        model="claude-3-opus-20240229",
        max_tokens=1024,
        system="You are a photography expert. Return valid JSON.",
        messages=[
            {
                "role": "user",
                "content": [
                    {
                        "type": "image",
                        "source": {
                            "type": "base64",
                            "media_type": "image/jpeg",
                            "data": base64_image
                        }
                    },
                    {
                        "type": "text",
                        "text": "Provide shooting advice, camera params, filters, and edit suggestions as JSON"
                    }
                ]
            }
        ]
    )
    
    return json.loads(response.content[0].text)
```

## Rate Limiting Recommendations

- Implement request queuing on the client side
- Cache results for similar scenes (optional)
- Use exponential backoff for retries
- Respect `Retry-After` headers

## Performance Optimization

1. **Image Preprocessing**: Resize images to 640x480 before sending
2. **Compression**: Use JPEG quality 80% to reduce payload size
3. **Caching**: Cache analysis results for identical frames
4. **Streaming**: Consider streaming responses for faster time-to-first-token

## Security Considerations

- Validate API keys on every request
- Implement rate limiting per API key
- Sanitize all inputs
- Use HTTPS only
- Log requests for debugging (without storing images)
- Set appropriate CORS headers if accessed from web

## Testing

Test your endpoint with:

```bash
curl -X POST http://localhost:8000/api/analyze \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-test-key" \
  -H "X-Provider: openai" \
  -d '{
    "image": "/9j/4AAQSkZJRg...",
    "task": "camera_advice"
  }'
```

## Sample Backend (FastAPI)

```python
from fastapi import FastAPI, HTTPException, Header
from pydantic import BaseModel
import base64

app = FastAPI()

class AnalysisRequest(BaseModel):
    image: str
    task: str = "camera_advice"

@app.post("/api/analyze")
async def analyze(
    request: AnalysisRequest,
    authorization: str = Header(...),
    x_provider: str = Header("openai")
):
    # Validate API key
    api_key = authorization.replace("Bearer ", "")
    if not validate_api_key(api_key):
        raise HTTPException(status_code=401, detail="Invalid API key")
    
    # Call LLM provider
    result = await call_llm_provider(request.image, x_provider)
    
    return result
```
