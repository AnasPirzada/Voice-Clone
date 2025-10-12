#!/usr/bin/env python3
"""
Optimized F5-TTS API for Render deployment
This version is designed to work within Render's free tier limitations
"""
import os
import sys
import io
import json
import time
import threading
from flask import Flask, jsonify, request, send_file
from flask_cors import CORS

# Add src to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

app = Flask(__name__)
CORS(app)

# Global variables for model management
_model = None
_model_loading = False
_model_loaded = False
_model_error = None

def load_model_async():
    """Load F5-TTS model in background thread"""
    global _model, _model_loading, _model_loaded, _model_error
    
    try:
        print("Starting F5-TTS model loading...")
        _model_loading = True
        
        # Use smaller model for Render free tier
        from f5_tts.api import F5TTS
        _model = F5TTS(
            model="F5TTS_Base",  # Smaller model than F5TTS_v1_Base
            device="cpu",        # Force CPU to avoid GPU issues
            ode_method="euler",  # Faster inference
            use_ema=True
        )
        
        _model_loaded = True
        _model_loading = False
        print("F5-TTS model loaded successfully!")
        
    except Exception as e:
        _model_error = str(e)
        _model_loading = False
        print(f"Error loading F5-TTS model: {e}")

def get_model_status():
    """Get current model status"""
    if _model_loaded:
        return "loaded"
    elif _model_loading:
        return "loading"
    elif _model_error:
        return f"error: {_model_error}"
    else:
        return "not_started"

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint with model status"""
    model_status = get_model_status()
    
    return jsonify({
        "status": "ok" if model_status == "loaded" else "loading",
        "message": "F5-TTS API is running on Render",
        "version": "1.0.0",
        "model_status": model_status,
        "model_loading": _model_loading,
        "model_loaded": _model_loaded
    })

@app.route('/tts', methods=['POST', 'OPTIONS'])
def tts():
    """TTS endpoint - optimized for Render"""
    
    # Handle CORS preflight
    if request.method == 'OPTIONS':
        response = jsonify({'status': 'ok'})
        response.headers.add('Access-Control-Allow-Origin', '*')
        response.headers.add('Access-Control-Allow-Headers', 'Content-Type')
        response.headers.add('Access-Control-Allow-Methods', 'POST, OPTIONS')
        return response
    
    # Check if model is ready
    if not _model_loaded:
        if _model_loading:
            return jsonify({
                "error": "Model is still loading. Please wait a few minutes and try again.",
                "status": "loading",
                "model_status": get_model_status()
            }), 202  # Accepted but processing
        elif _model_error:
            return jsonify({
                "error": f"Model failed to load: {_model_error}",
                "status": "error"
            }), 500
        else:
            return jsonify({
                "error": "Model not initialized. Please try again in a few minutes.",
                "status": "not_ready"
            }), 503
    
    try:
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
        
        # Get query parameters with optimized defaults for Render
        speed = float(request.args.get('speed', '1.0'))
        cfg_strength = float(request.args.get('cfg_strength', '1.5'))  # Lower for faster generation
        nfe_step = int(request.args.get('nfe_step', '16'))  # Lower for faster generation
        
        # Limit text length for Render free tier
        if len(gen_text) > 200:
            return jsonify({
                "error": "Text too long. Please limit to 200 characters for free tier.",
                "status": "error"
            }), 400
        
        # Save uploaded file temporarily
        import tempfile
        with tempfile.NamedTemporaryFile(delete=False, suffix='.wav') as tmp_file:
            ref_audio_file.save(tmp_file.name)
            
            try:
                # Generate speech with optimized parameters
                wav, sr, _ = _model.infer(
                    ref_file=tmp_file.name,
                    ref_text=ref_text,
                    gen_text=gen_text,
                    speed=speed,
                    cfg_strength=cfg_strength,
                    nfe_step=nfe_step,
                    show_info=lambda *args, **kwargs: None,
                    progress=None,
                    target_rms=0.1,
                    cross_fade_duration=0.1,
                    remove_silence=False
                )
                
                # Clean up temp file
                os.unlink(tmp_file.name)
                
            except Exception as e:
                # Clean up temp file on error
                if os.path.exists(tmp_file.name):
                    os.unlink(tmp_file.name)
                raise e
        
        # Convert to WAV bytes
        import soundfile as sf
        buf = io.BytesIO()
        sf.write(buf, wav, sr, format="WAV")
        buf.seek(0)
        
        return send_file(buf, mimetype="audio/wav", as_attachment=False, download_name="tts.wav")
        
    except Exception as e:
        error_response = {
            "error": f"Generation failed: {str(e)}",
            "status": "error",
            "model_status": get_model_status()
        }
        response = jsonify(error_response)
        response.headers.add('Access-Control-Allow-Origin', '*')
        return response, 500

@app.route('/', methods=['GET'])
def root():
    """Root endpoint"""
    return jsonify({
        "message": "F5-TTS API - Render Optimized",
        "endpoints": {
            "health": "/health",
            "tts": "/tts"
        },
        "status": "running",
        "model_status": get_model_status(),
        "note": "This is an optimized version for Render free tier deployment"
    })

def start_model_loading():
    """Start model loading in background"""
    global _model_loading
    if not _model_loading and not _model_loaded:
        thread = threading.Thread(target=load_model_async)
        thread.daemon = True
        thread.start()

if __name__ == '__main__':
    # Start model loading immediately
    start_model_loading()
    
    port = int(os.environ.get('PORT', 8000))
    app.run(host='0.0.0.0', port=port, debug=False)
