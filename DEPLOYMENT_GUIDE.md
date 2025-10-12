# F5-TTS Deployment Guide

## 🚀 Complete Deployment Guide for F5-TTS Voice Cloning

This guide covers deploying both the F5-TTS API server and the React UI to make your voice cloning application live.

---

## 📋 Table of Contents

1. [Current Issue Resolution](#current-issue-resolution)
2. [Local Development Setup](#local-development-setup)
3. [API Server Deployment](#api-server-deployment)
4. [UI Deployment](#ui-deployment)
5. [Production Configuration](#production-configuration)
6. [Troubleshooting](#troubleshooting)

---

## 🔧 Current Issue Resolution

### **Problem:** UI showing "503 Service Unavailable"
**Error:** `GET http://localhost:3000/api/health 503 (Service Unavailable)`

### **Root Cause:**
- UI is trying to connect to `http://localhost:3000/api/health`
- F5-TTS server is running on `http://127.0.0.1:8000/health`
- **Port mismatch:** 3000 vs 8000
- **Endpoint mismatch:** `/api/health` vs `/health`

### **Solution Applied:**
✅ Updated API configuration to use correct URL: `http://127.0.0.1:8000`
✅ Added auto-detection for local vs production environments
✅ Added debugging logs to track API calls

---

## 🏠 Local Development Setup

### **Step 1: Start F5-TTS Server**
```bash
# In your F5-TTS project directory
cd "C:\Users\Sunny\Desktop\Personal Projects\F5-TTS"

# Start the F5-TTS server (this takes 5-15 minutes to load the model)
f5-tts_api
# OR
python src/f5_tts/server.py
```

**Expected Output:**
```
* Serving Flask app 'f5_tts.server'
* Debug mode: off
* Running on http://127.0.0.1:8000
```

### **Step 2: Start UI Development Server**
```bash
# In a new terminal, navigate to UI directory
cd "C:\Users\Sunny\Desktop\Personal Projects\F5-TTS\f5-tts-ui"

# Install dependencies (if not already done)
npm install

# Start the development server
npm run dev
```

**Expected Output:**
```
- Local:        http://localhost:3000
- Network:      http://192.168.x.x:3000
```

### **Step 3: Verify Connection**
1. Open `http://localhost:3000` in your browser
2. Check browser console for:
   ```
   Checking API health at: http://127.0.0.1:8000/health
   Health check response: 200 OK
   API connection result: true
   ```
3. You should see "✓ API Connected" in the UI

---

## 🌐 API Server Deployment Options

### **Option 1: Render.com (Recommended for Free Tier)**

#### **1.1 Prepare for Render Deployment**
```bash
# Ensure you have these files in your project root:
# - app.py (for Render)
# - requirements.txt
# - wsgi.py
# - vercel.json (if using Vercel for UI)
```

#### **1.2 Deploy to Render**
1. **Connect GitHub Repository:**
   - Go to [render.com](https://render.com)
   - Connect your GitHub account
   - Select your `Voice-Clone` repository

2. **Create Web Service:**
   - **Name:** `f5tts-api`
   - **Environment:** `Python 3`
   - **Build Command:** `pip install -r requirements.txt`
   - **Start Command:** `python app.py`
   - **Plan:** Free (or paid for better performance)

3. **Environment Variables:**
   ```
   PORT=8000
   F5TTS_MODEL=F5TTS_v1_Base
   F5TTS_DEVICE=cpu
   ```

4. **Deploy:**
   - Click "Create Web Service"
   - Wait for deployment (10-15 minutes)
   - Note the URL: `https://your-app-name.onrender.com`

#### **1.3 Update UI Configuration**
```typescript
// In f5-tts-ui/src/config/api.ts
export const API_CONFIG = {
  LOCAL_URL: 'http://127.0.0.1:8000',
  PRODUCTION_URL: 'https://your-app-name.onrender.com', // Update this
  // ... rest of config
};
```

### **Option 2: Railway**

#### **2.1 Deploy to Railway**
1. **Connect Repository:**
   - Go to [railway.app](https://railway.app)
   - Connect GitHub and select your repository

2. **Configure Service:**
   - **Build Command:** `pip install -r requirements.txt`
   - **Start Command:** `python app.py`
   - **Port:** Auto-detect

3. **Environment Variables:**
   ```
   F5TTS_MODEL=F5TTS_v1_Base
   F5TTS_DEVICE=cpu
   ```

### **Option 3: Google Cloud Run**

#### **3.1 Prepare Dockerfile**
```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["python", "app.py"]
```

#### **3.2 Deploy to Cloud Run**
```bash
# Build and deploy
gcloud run deploy f5tts-api \
  --source . \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --memory 4Gi \
  --cpu 2 \
  --timeout 3600
```

---

## 🎨 UI Deployment Options

### **Option 1: Vercel (Recommended)**

#### **1.1 Deploy to Vercel**
```bash
# In f5-tts-ui directory
cd f5-tts-ui

# Install Vercel CLI
npm i -g vercel

# Deploy
vercel

# Follow prompts:
# - Link to existing project? No
# - Project name: f5tts-ui
# - Directory: ./
# - Override settings? No
```

#### **1.2 Configure Environment Variables**
In Vercel dashboard:
1. Go to your project settings
2. Add environment variable:
   ```
   NEXT_PUBLIC_API_URL=https://your-api-url.onrender.com
   ```
3. Redeploy

### **Option 2: Netlify**

#### **2.1 Deploy to Netlify**
```bash
# Build the project
npm run build

# Deploy to Netlify
npx netlify deploy --prod --dir=out
```

#### **2.2 Configure Environment Variables**
In Netlify dashboard:
1. Go to Site settings > Environment variables
2. Add:
   ```
   NEXT_PUBLIC_API_URL=https://your-api-url.onrender.com
   ```

### **Option 3: GitHub Pages**

#### **3.1 Configure for GitHub Pages**
```bash
# Install gh-pages
npm install --save-dev gh-pages

# Add to package.json scripts:
"deploy": "gh-pages -d out"
```

#### **3.2 Deploy**
```bash
npm run build
npm run deploy
```

---

## ⚙️ Production Configuration

### **API Server Configuration**

#### **Environment Variables for Production:**
```bash
# Required
PORT=8000
F5TTS_MODEL=F5TTS_v1_Base

# Optional
F5TTS_DEVICE=cpu
F5TTS_API_HOST=0.0.0.0
F5TTS_API_DEBUG=false
HF_HOME=/tmp/huggingface
```

#### **Optimized app.py for Production:**
```python
#!/usr/bin/env python3
"""
Production F5-TTS API for deployment
"""
import os
import sys
import io
import json
from flask import Flask, jsonify, request, send_file
from flask_cors import CORS

# Add src to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Global model variable for lazy loading
_model = None

def get_model():
    global _model
    if _model is None:
        try:
            from f5_tts.api import F5TTS
            print("Loading F5-TTS model...")
            _model = F5TTS(
                model=os.getenv("F5TTS_MODEL", "F5TTS_v1_Base"),
                device=os.getenv("F5TTS_DEVICE", "cpu")
            )
            print("Model loaded successfully!")
        except Exception as e:
            print(f"Error loading model: {e}")
            _model = None
    return _model

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        "status": "ok", 
        "message": "F5-TTS API is running",
        "version": "1.0.0",
        "model_loaded": get_model() is not None
    })

@app.route('/tts', methods=['POST', 'OPTIONS'])
def tts():
    """TTS endpoint with real voice cloning"""
    
    # Handle CORS preflight
    if request.method == 'OPTIONS':
        response = jsonify({'status': 'ok'})
        response.headers.add('Access-Control-Allow-Origin', '*')
        response.headers.add('Access-Control-Allow-Headers', 'Content-Type')
        response.headers.add('Access-Control-Allow-Methods', 'POST, OPTIONS')
        return response
    
    try:
        model = get_model()
        if model is None:
            return jsonify({"error": "Model not loaded"}), 500
        
        # Check if files are provided
        if 'ref_audio' not in request.files:
            return jsonify({"error": "ref_audio file is required"}), 400
        
        ref_audio_file = request.files['ref_audio']
        if ref_audio_file.filename == "":
            return jsonify({"error": "ref_audio file is required"}), 400
        
        # Get form data
        ref_text = request.form.get('ref_text', '')
        gen_text = request.form.get('gen_text', '')
        
        if not gen_text:
            return jsonify({"error": "gen_text is required"}), 400
        
        # Get query parameters
        speed = float(request.args.get('speed', '1.0'))
        cfg_strength = float(request.args.get('cfg_strength', '2.0'))
        nfe_step = int(request.args.get('nfe_step', '32'))
        
        # Save uploaded file temporarily
        import tempfile
        with tempfile.NamedTemporaryFile(delete=False, suffix='.wav') as tmp_file:
            ref_audio_file.save(tmp_file.name)
            
            # Generate speech
            wav, sr, _ = model.infer(
                ref_file=tmp_file.name,
                ref_text=ref_text,
                gen_text=gen_text,
                speed=speed,
                cfg_strength=cfg_strength,
                nfe_step=nfe_step,
                show_info=lambda *args, **kwargs: None,
                progress=None
            )
            
            # Clean up temp file
            os.unlink(tmp_file.name)
        
        # Convert to WAV bytes
        import soundfile as sf
        buf = io.BytesIO()
        sf.write(buf, wav, sr, format="WAV")
        buf.seek(0)
        
        return send_file(buf, mimetype="audio/wav", as_attachment=False, download_name="tts.wav")
        
    except Exception as e:
        error_response = {
            "error": f"Internal server error: {str(e)}",
            "status": "error"
        }
        response = jsonify(error_response)
        response.headers.add('Access-Control-Allow-Origin', '*')
        return response, 500

@app.route('/', methods=['GET'])
def root():
    """Root endpoint"""
    return jsonify({
        "message": "F5-TTS API",
        "endpoints": {
            "health": "/health",
            "tts": "/tts"
        },
        "status": "running"
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8000))
    app.run(host='0.0.0.0', port=port, debug=False)
```

### **UI Production Configuration**

#### **Next.js Configuration (next.config.js):**
```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'export',
  trailingSlash: true,
  images: {
    unoptimized: true
  },
  env: {
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL || 'http://127.0.0.1:8000'
  }
}

module.exports = nextConfig
```

#### **Package.json Scripts:**
```json
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "export": "next build && next export",
    "deploy": "npm run build && vercel --prod"
  }
}
```

---

## 🔍 Troubleshooting

### **Common Issues and Solutions**

#### **1. API Connection Issues**

**Problem:** UI shows "API Not Available"
**Solutions:**
```bash
# Check if F5-TTS server is running
curl http://127.0.0.1:8000/health

# Check server logs for errors
# Look for model loading issues

# Verify port is not blocked
netstat -ano | findstr :8000
```

#### **2. CORS Issues**

**Problem:** Browser blocks API requests
**Solution:** Ensure CORS is enabled in Flask app:
```python
from flask_cors import CORS
app = Flask(__name__)
CORS(app)
```

#### **3. Model Loading Issues**

**Problem:** Model fails to load in production
**Solutions:**
- Increase memory allocation (4GB+ recommended)
- Use CPU instead of GPU for compatibility
- Check Hugging Face model download permissions

#### **4. Audio Generation Timeout**

**Problem:** Requests timeout after 30+ minutes
**Solutions:**
- Reduce `nfe_step` parameter (16 instead of 32)
- Use shorter reference audio files
- Implement request queuing for production

#### **5. Deployment Memory Issues**

**Problem:** Out of memory errors
**Solutions:**
- Use smaller model: `F5TTS_Base` instead of `F5TTS_v1_Base`
- Increase deployment memory to 4GB+
- Implement model caching

---

## 📊 Performance Optimization

### **API Server Optimization:**
```python
# Add to app.py for better performance
import gc
import threading

# Model caching
_model_lock = threading.Lock()

def get_model():
    global _model
    with _model_lock:
        if _model is None:
            # Load model here
            pass
    return _model

# Memory cleanup after each request
@app.after_request
def cleanup(response):
    gc.collect()
    return response
```

### **UI Optimization:**
```typescript
// Add request timeout and retry logic
const API_TIMEOUT = 300000; // 5 minutes

async function generateSpeechWithRetry(request: TTSRequest, retries = 3) {
  for (let i = 0; i < retries; i++) {
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), API_TIMEOUT);
      
      const response = await fetch(url, {
        method: 'POST',
        body: formData,
        signal: controller.signal
      });
      
      clearTimeout(timeoutId);
      return response;
    } catch (error) {
      if (i === retries - 1) throw error;
      await new Promise(resolve => setTimeout(resolve, 1000 * (i + 1)));
    }
  }
}
```

---

## 🚀 Quick Deployment Checklist

### **Before Deployment:**
- [ ] F5-TTS server runs locally without errors
- [ ] UI connects to local API successfully
- [ ] Audio generation works end-to-end
- [ ] All environment variables configured
- [ ] CORS properly configured
- [ ] Error handling implemented

### **API Deployment:**
- [ ] Choose hosting platform (Render/Railway/Cloud Run)
- [ ] Configure environment variables
- [ ] Deploy and test health endpoint
- [ ] Test TTS endpoint with sample data
- [ ] Monitor memory usage and performance

### **UI Deployment:**
- [ ] Update API URL in configuration
- [ ] Build and test locally
- [ ] Deploy to Vercel/Netlify/GitHub Pages
- [ ] Test end-to-end functionality
- [ ] Configure custom domain (optional)

### **Post-Deployment:**
- [ ] Monitor API performance and memory usage
- [ ] Set up error tracking (Sentry, etc.)
- [ ] Configure analytics (Google Analytics, etc.)
- [ ] Set up monitoring and alerts
- [ ] Document API endpoints for users

---

## 📞 Support and Resources

### **Useful Commands:**
```bash
# Check server status
curl https://your-api-url.com/health

# Test TTS endpoint
curl -X POST https://your-api-url.com/tts \
  -F "ref_audio=@test.wav" \
  -F "gen_text=Hello world" \
  --output generated.wav

# Check deployment logs
# Render: Dashboard > Your Service > Logs
# Railway: Dashboard > Your Service > Deployments > View Logs
# Vercel: Dashboard > Your Project > Functions > View Logs
```

### **GitHub Repository:**
Your code is already pushed to: `https://github.com/AnasPirzada/Voice-Clone.git`

### **Next Steps:**
1. **Fix the current API connection issue** (already done)
2. **Test locally** to ensure everything works
3. **Deploy API server** to Render/Railway
4. **Deploy UI** to Vercel/Netlify
5. **Update configuration** with production URLs
6. **Test end-to-end** in production

---

This guide should resolve your current 503 error and provide a complete path to deployment. The key fix was updating the API URL from `localhost:3000` to `127.0.0.1:8000` to match your F5-TTS server.
