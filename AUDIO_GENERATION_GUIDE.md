# F5-TTS Audio Generation Guide

## 🎵 **Why You're Not Getting Audio Files**

### **Current Issue:**
You're using the **local testing server** (`local_server.py`) which only returns **mock responses** for testing API structure. It doesn't generate real audio.

### **Two Different Servers:**

| Server | File | Purpose | Audio Output |
|--------|------|---------|--------------|
| **Testing Server** | `local_server.py` | API testing | ❌ Mock JSON only |
| **Production Server** | `src/f5_tts/server.py` | Real TTS | ✅ Actual WAV files |

---

## 🚀 **How to Get Real Audio Generation**

### **Step 1: Stop Testing Server**
```powershell
# Find and kill the testing server
netstat -ano | findstr :8000
taskkill /PID [PID_NUMBER] /F
```

### **Step 2: Start Full F5-TTS Server**
```powershell
python src/f5_tts/server.py
```

**⚠️ Important:** This will take **5-15 minutes** to:
- Download F5-TTS model (~2-4 GB)
- Load model into memory
- Initialize vocoder

### **Step 3: Wait for Model Loading**
You'll see output like:
```
Loading F5-TTS model...
Downloading model files...
Initializing vocoder...
Model loaded successfully!
```

### **Step 4: Test Real Audio Generation**
```powershell
.\simple_test.ps1
```

---

## 📁 **Expected Response Format**

### **Testing Server Response (Current):**
```json
{
  "message": "TTS request received successfully!",
  "received_data": {
    "ref_audio_filename": "harvard.wav",
    "ref_text": "The subtitle or transcription of reference audio.",
    "gen_text": "hi i am anas how are you"
  },
  "note": "This is a mock response for local testing...",
  "status": "success"
}
```

### **Full F5-TTS Server Response:**
```
Content-Type: audio/wav
[Binary audio data - actual WAV file]
```

---

## 🔧 **Testing Real Audio Generation**

### **Method 1: PowerShell Script (Updated)**
```powershell
# Create a script that saves the audio file
$filePath = "C:\Users\Sunny\Downloads\harvard.wav"
$uri = "http://localhost:8000/tts"
$boundary = [System.Guid]::NewGuid().ToString()
$LF = "`r`n"

$bodyLines = @(
    "--$boundary",
    "Content-Disposition: form-data; name=`"ref_audio`"; filename=`"harvard.wav`"",
    "Content-Type: audio/wav",
    "",
    [System.IO.File]::ReadAllBytes($filePath),
    "--$boundary",
    "Content-Disposition: form-data; name=`"ref_text`"",
    "",
    "The subtitle or transcription of reference audio.",
    "--$boundary",
    "Content-Disposition: form-data; name=`"gen_text`"",
    "",
    "hi i am anas how are you",
    "--$boundary--",
    ""
) -join $LF

# Make request and save audio file
$response = Invoke-WebRequest -Uri $uri -Method Post -Body $bodyLines -ContentType "multipart/form-data; boundary=$boundary"
$response.Content | Set-Content -Path "generated_audio.wav" -Encoding Byte

Write-Host "Audio saved as: generated_audio.wav"
```

### **Method 2: Using curl**
```bash
curl -X POST \
  -F "ref_audio=@C:\Users\Sunny\Downloads\harvard.wav" \
  -F "ref_text=The subtitle or transcription of reference audio." \
  -F "gen_text=hi i am anas how are you" \
  "http://localhost:8000/tts" \
  --output generated_audio.wav
```

### **Method 3: Browser/Postman**
- **Method:** POST
- **URL:** `http://localhost:8000/tts`
- **Body:** form-data
- **Response:** Download the WAV file

---

## ⚡ **Performance Expectations**

### **Model Loading Time:**
- **First run:** 5-15 minutes (downloads model)
- **Subsequent runs:** 2-5 minutes (loads from cache)

### **Audio Generation Time:**
- **Short text (1-2 sentences):** 10-30 seconds
- **Long text (paragraph):** 30-60 seconds
- **Complex text:** 1-2 minutes

### **System Requirements:**
- **RAM:** 4-8 GB minimum
- **Storage:** 5-10 GB for models
- **CPU:** Multi-core recommended

---

## 🐛 **Troubleshooting**

### **Server Won't Start:**
```powershell
# Check if port is available
netstat -ano | findstr :8000

# Try different port
set F5TTS_API_PORT=8001
python src/f5_tts/server.py
```

### **Model Download Issues:**
- **Slow internet:** Be patient, models are large
- **Disk space:** Ensure 10+ GB free space
- **Permissions:** Run as administrator if needed

### **Memory Issues:**
- **Close other applications**
- **Restart computer**
- **Use smaller model:** Set `F5TTS_MODEL=F5TTS_Small`

### **Audio Quality Issues:**
- **Use high-quality reference audio**
- **Match reference text accurately**
- **Adjust parameters (speed, cfg_strength)**

---

## 🎯 **Quick Test Commands**

### **Check Server Status:**
```powershell
Invoke-WebRequest -Uri "http://localhost:8000/health" -Method GET
```

### **Test with Sample Audio:**
```powershell
# Use the harvard.wav file
$filePath = "C:\Users\Sunny\Downloads\harvard.wav"
# ... (use the PowerShell script above)
```

### **Save Generated Audio:**
```powershell
# The response will be binary WAV data
$response.Content | Set-Content -Path "my_generated_audio.wav" -Encoding Byte
```

---

## 📊 **Server Comparison**

| Feature | Testing Server | Full F5-TTS Server |
|---------|----------------|-------------------|
| **Startup Time** | Instant | 5-15 minutes |
| **Memory Usage** | ~50 MB | 2-4 GB |
| **Disk Usage** | Minimal | 5-10 GB |
| **Audio Output** | Mock JSON | Real WAV files |
| **Use Case** | API testing | Production |

---

## 🎉 **Success Indicators**

### **Full Server Running:**
✅ Server starts without errors
✅ Health endpoint returns 200 OK
✅ TTS endpoint returns binary WAV data
✅ Generated audio file plays correctly

### **Audio Generation Working:**
✅ Response is binary WAV data (not JSON)
✅ File size is reasonable (100KB - 10MB)
✅ Audio plays in media player
✅ Voice matches reference audio characteristics

---

## 🚀 **Next Steps**

1. **Wait for model loading** (5-15 minutes)
2. **Test with real audio generation**
3. **Save and play generated audio**
4. **Connect frontend to full server**
5. **Deploy to production** (Render)

Your F5-TTS server is now loading the full model for real audio generation! 🎵
