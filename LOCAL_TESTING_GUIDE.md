# F5-TTS Local API Testing Guide

## 🚀 Server Status: RUNNING ✅

Your F5-TTS API is now running locally and ready for testing!

**Server URL:** `http://localhost:8000`

---

## 📋 Available Endpoints

### 1. Health Check
**URL:** `http://localhost:8000/health`
**Method:** `GET`
**Description:** Check if the API is running

**Response:**
```json
{
  "status": "ok",
  "message": "F5-TTS API is running locally",
  "version": "1.0.0",
  "mode": "local_testing"
}
```

### 2. Root Endpoint
**URL:** `http://localhost:8000/`
**Method:** `GET`
**Description:** Get API information

**Response:**
```json
{
  "message": "F5-TTS API - Local Testing Mode",
  "endpoints": {
    "health": "/health",
    "tts": "/tts"
  },
  "status": "running",
  "note": "This is a simplified version for local testing"
}
```

### 3. TTS Endpoint
**URL:** `http://localhost:8000/tts`
**Method:** `POST`
**Content-Type:** `multipart/form-data`
**Description:** Generate speech (mock response for testing)

**Required Parameters:**
- `ref_audio` (file): Reference audio file
- `gen_text` (string): Text to generate speech for

**Optional Parameters:**
- `ref_text` (string): Text content of reference audio
- `speed` (float): Speech speed (query parameter)
- `cfg_strength` (float): CFG strength (query parameter)

---

## 🧪 Testing Methods

### Method 1: PowerShell (Windows)
```powershell
# Health check
Invoke-WebRequest -Uri "http://localhost:8000/health" -Method GET

# Root endpoint
Invoke-WebRequest -Uri "http://localhost:8000/" -Method GET

# TTS endpoint (requires file upload - see below for file testing)
```

### Method 2: curl (if available)
```bash
# Health check
curl http://localhost:8000/health

# Root endpoint
curl http://localhost:8000/

# TTS endpoint
curl -X POST \
  -F "ref_audio=@your_audio_file.wav" \
  -F "ref_text=Hello world" \
  -F "gen_text=This is a test" \
  "http://localhost:8000/tts?speed=1.0"
```

### Method 3: Browser Testing
Open these URLs in your browser:
- `http://localhost:8000/health`
- `http://localhost:8000/`

### Method 4: Postman/Insomnia
Import these requests:

**Health Check:**
- Method: GET
- URL: `http://localhost:8000/health`

**TTS Request:**
- Method: POST
- URL: `http://localhost:8000/tts`
- Body: form-data
  - `ref_audio`: [Select audio file]
  - `ref_text`: "Hello world"
  - `gen_text`: "This is a test"
- Query params: `speed=1.0`

---

## 📁 File Testing

### Test with Sample Audio
1. **Find an audio file** (WAV, MP3, etc.) on your computer
2. **Use PowerShell** to test file upload:

```powershell
# Create a test file upload
$filePath = "C:\path\to\your\audio\file.wav"  # Replace with actual path
$uri = "http://localhost:8000/tts?speed=1.0&cfg_strength=2.0"

$form = @{
    ref_audio = Get-Item $filePath
    ref_text = "This is my reference audio"
    gen_text = "Hello, this is a test of the TTS system"
}

Invoke-RestMethod -Uri $uri -Method Post -Form $form
```

### Test with Sample Files from Project
If you have sample audio files in your project:
```powershell
# Test with project sample files
$sampleFile = "src\instance\uploads\harvard.wav"  # If this exists
$uri = "http://localhost:8000/tts"

$form = @{
    ref_audio = Get-Item $sampleFile
    ref_text = "The quick brown fox jumps over the lazy dog"
    gen_text = "This is a test of the F5-TTS voice cloning system"
}

Invoke-RestMethod -Uri $uri -Method Post -Form $form
```

---

## 🔧 Server Management

### Start Server
```bash
python local_server.py
```

### Stop Server
Press `Ctrl+C` in the terminal where the server is running

### Check Server Status
```powershell
Invoke-WebRequest -Uri "http://localhost:8000/health" -Method GET
```

### Server Configuration
The server runs with these default settings:
- **Host:** `127.0.0.1` (localhost)
- **Port:** `8000`
- **Debug Mode:** `true`
- **CORS:** Enabled for all origins

---

## 🎯 Expected Responses

### Successful TTS Request
```json
{
  "message": "TTS request received successfully!",
  "received_data": {
    "ref_audio_filename": "your_file.wav",
    "ref_text": "Hello world",
    "gen_text": "This is a test",
    "speed": "1.0",
    "cfg_strength": "2.0"
  },
  "note": "This is a mock response for local testing. In production, this would generate actual speech.",
  "status": "success"
}
```

### Error Responses
```json
{
  "error": "ref_audio file is required",
  "status": "error"
}
```

```json
{
  "error": "gen_text is required",
  "status": "error"
}
```

---

## 🔗 Integration with Frontend

### Update Your Frontend API URL
In your Next.js project, update the API client:

```typescript
// In your API client
const client = new F5TTSClient('http://localhost:8000');
```

Or set environment variable:
```env
NEXT_PUBLIC_API_URL=http://localhost:8000
```

### Test Frontend Integration
1. **Start your Next.js frontend:**
   ```bash
   cd f5-tts-ui
   npm run dev
   ```

2. **Update API URL** to point to localhost
3. **Test the full application** with file upload and TTS generation

---

## 🚨 Troubleshooting

### Server Won't Start
- **Check if port 8000 is available:**
  ```powershell
  netstat -an | findstr :8000
  ```
- **Try a different port:**
  ```bash
  set F5TTS_API_PORT=8001
  python local_server.py
  ```

### Connection Refused
- **Verify server is running:** Check terminal for startup messages
- **Check firewall:** Windows Firewall might be blocking the connection
- **Try different host:** Use `0.0.0.0` instead of `127.0.0.1`

### File Upload Issues
- **Check file format:** Ensure audio file is supported (WAV, MP3, etc.)
- **Check file size:** Large files might timeout
- **Check file path:** Ensure file exists and is accessible

---

## 📊 Performance Notes

### Local Testing Mode
- **No model loading:** Fast startup (no F5-TTS model download)
- **Mock responses:** Instant responses for testing
- **CORS enabled:** Works with frontend development
- **Debug mode:** Detailed error messages

### Production vs Local
- **Local:** Mock responses, no actual speech generation
- **Production (Render):** Full F5-TTS model, actual speech generation
- **Memory usage:** Local uses minimal memory
- **Response time:** Local is instant, production takes time for generation

---

## 🎉 Success Indicators

✅ **Server running:** `http://localhost:8000/health` returns 200 OK
✅ **CORS working:** Frontend can make requests
✅ **File upload working:** TTS endpoint accepts files
✅ **Error handling:** Proper error messages for invalid requests
✅ **API structure:** Same endpoints as production version

Your local F5-TTS API is ready for development and testing! 🚀
