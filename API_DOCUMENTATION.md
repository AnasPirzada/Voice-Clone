# F5-TTS API Documentation

## Base URL
```
https://voice-clone-3pyz.onrender.com
```

## API Endpoints

### 1. Health Check
**Endpoint:** `GET /health`
**Description:** Check if the API is running and healthy
**URL:** `https://voice-clone-3pyz.onrender.com/health`

**Response:**
```json
{
  "status": "ok",
  "message": "F5-TTS API is running on Render",
  "version": "1.0.0"
}
```

**Usage Example:**
```javascript
const response = await fetch('https://voice-clone-3pyz.onrender.com/health');
const data = await response.json();
console.log(data); // { status: "ok", message: "F5-TTS API is running on Render", version: "1.0.0" }
```

---

### 2. Text-to-Speech Generation
**Endpoint:** `POST /tts`
**Description:** Generate speech from text using reference audio
**URL:** `https://voice-clone-3pyz.onrender.com/tts`

**Request Method:** `POST`
**Content-Type:** `multipart/form-data`

**Request Parameters:**

#### Form Data (multipart/form-data):
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `ref_audio` | File | ✅ Yes | Reference audio file (WAV, MP3, etc.) |
| `ref_text` | String | ❌ No | Text content of the reference audio |
| `gen_text` | String | ✅ Yes | Text to generate speech for |

#### Query Parameters (Optional):
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `target_rms` | Float | 0.1 | Target RMS level for audio normalization |
| `cross_fade_duration` | Float | 0.15 | Cross-fade duration in seconds |
| `sway_sampling_coef` | Float | -1.0 | Sway sampling coefficient |
| `cfg_strength` | Float | 2.0 | Classifier-free guidance strength |
| `nfe_step` | Integer | 32 | Number of function evaluations |
| `speed` | Float | 1.0 | Speech speed multiplier |
| `fix_duration` | Float | null | Fixed duration in seconds |
| `remove_silence` | Boolean | false | Whether to remove silence from output |

**Request Example:**
```javascript
const formData = new FormData();
formData.append('ref_audio', audioFile);
formData.append('ref_text', 'Hello, this is my reference audio');
formData.append('gen_text', 'This is the text I want to generate speech for');

const response = await fetch('https://voice-clone-3pyz.onrender.com/tts?speed=1.2&cfg_strength=2.5', {
  method: 'POST',
  body: formData
});
```

**Response:**
- **Success (200):** Returns audio file (WAV format)
- **Error (400/500):** Returns JSON error message

**Success Response:**
```
Content-Type: audio/wav
[Binary audio data]
```

**Error Response:**
```json
{
  "error": "Error message description",
  "status": "error"
}
```

---

### 3. Root Endpoint
**Endpoint:** `GET /`
**Description:** Get API information and available endpoints
**URL:** `https://voice-clone-3pyz.onrender.com/`

**Response:**
```json
{
  "message": "F5-TTS API",
  "endpoints": {
    "health": "/health",
    "tts": "/tts"
  },
  "status": "running"
}
```

---

## API Client Implementation

### TypeScript Interface
```typescript
export interface TTSRequest {
  ref_audio: File;
  ref_text?: string;
  gen_text: string;
  target_rms?: number;
  cross_fade_duration?: number;
  sway_sampling_coef?: number;
  cfg_strength?: number;
  nfe_step?: number;
  speed?: number;
  fix_duration?: number;
  remove_silence?: boolean;
}

export interface TTSResponse {
  audio: Blob;
  error?: string;
}

export interface HealthResponse {
  status: string;
  message: string;
  version: string;
}
```

### API Client Class
```typescript
export class F5TTSClient {
  private baseUrl: string;

  constructor(baseUrl: string = 'https://voice-clone-3pyz.onrender.com') {
    this.baseUrl = baseUrl;
  }

  async healthCheck(): Promise<boolean> {
    try {
      const response = await fetch(`${this.baseUrl}/health`);
      return response.ok;
    } catch (error) {
      console.error('Health check failed:', error);
      return false;
    }
  }

  async generateSpeech(request: TTSRequest): Promise<TTSResponse> {
    const formData = new FormData();
    formData.append('ref_audio', request.ref_audio);
    
    if (request.ref_text) {
      formData.append('ref_text', request.ref_text);
    }
    
    formData.append('gen_text', request.gen_text);

    // Build query parameters
    const params = new URLSearchParams();
    
    if (request.target_rms !== undefined) {
      params.append('target_rms', request.target_rms.toString());
    }
    if (request.cross_fade_duration !== undefined) {
      params.append('cross_fade_duration', request.cross_fade_duration.toString());
    }
    if (request.sway_sampling_coef !== undefined) {
      params.append('sway_sampling_coef', request.sway_sampling_coef.toString());
    }
    if (request.cfg_strength !== undefined) {
      params.append('cfg_strength', request.cfg_strength.toString());
    }
    if (request.nfe_step !== undefined) {
      params.append('nfe_step', request.nfe_step.toString());
    }
    if (request.speed !== undefined) {
      params.append('speed', request.speed.toString());
    }
    if (request.fix_duration !== undefined) {
      params.append('fix_duration', request.fix_duration.toString());
    }
    if (request.remove_silence !== undefined) {
      params.append('remove_silence', request.remove_silence.toString());
    }

    const url = `${this.baseUrl}/tts${params.toString() ? `?${params.toString()}` : ''}`;

    try {
      const response = await fetch(url, {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        return {
          audio: new Blob(),
          error: errorData.error || `HTTP ${response.status}: ${response.statusText}`,
        };
      }

      const audioBlob = await response.blob();
      return { audio: audioBlob };
    } catch (error) {
      console.error('TTS request failed:', error);
      return {
        audio: new Blob(),
        error: error instanceof Error ? error.message : 'Unknown error occurred',
      };
    }
  }
}
```

---

## Error Handling

### Common Error Codes
- **400 Bad Request:** Missing required parameters or invalid file format
- **500 Internal Server Error:** Server-side processing error
- **Network Error:** Connection issues or timeout

### Error Response Format
```json
{
  "error": "Detailed error message",
  "status": "error"
}
```

---

## Rate Limits & Considerations

### Current Limitations (Free Tier)
- **Memory:** 512MB RAM
- **CPU:** 0.1 CPU cores
- **Sleep:** Service sleeps after 15 minutes of inactivity
- **Cold Start:** May take 30-60 seconds to wake up

### Recommendations
- Implement retry logic for cold starts
- Add loading states for better UX
- Consider upgrading to paid tier for production use

---

## Testing the API

### Using curl
```bash
# Health check
curl https://voice-clone-3pyz.onrender.com/health

# TTS request
curl -X POST \
  -F "ref_audio=@reference.wav" \
  -F "ref_text=Hello world" \
  -F "gen_text=This is a test" \
  "https://voice-clone-3pyz.onrender.com/tts?speed=1.0" \
  --output generated_audio.wav
```

### Using JavaScript
```javascript
// Test health endpoint
const testHealth = async () => {
  const response = await fetch('https://voice-clone-3pyz.onrender.com/health');
  const data = await response.json();
  console.log('API Status:', data);
};

// Test TTS endpoint
const testTTS = async (audioFile, text) => {
  const formData = new FormData();
  formData.append('ref_audio', audioFile);
  formData.append('gen_text', text);
  
  const response = await fetch('https://voice-clone-3pyz.onrender.com/tts', {
    method: 'POST',
    body: formData
  });
  
  if (response.ok) {
    const audioBlob = await response.blob();
    const audioUrl = URL.createObjectURL(audioBlob);
    return audioUrl;
  } else {
    const error = await response.json();
    console.error('TTS Error:', error);
  }
};
```
