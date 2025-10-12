#!/usr/bin/env python3
"""
Simplified F5-TTS API server for local testing
This version doesn't load the full F5-TTS model for quick testing
"""
import os
import io
import json
from flask import Flask, jsonify, request, send_file
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        "status": "ok",
        "message": "F5-TTS API is running locally",
        "version": "1.0.0",
        "mode": "local_testing"
    })

@app.route('/', methods=['GET'])
def root():
    """Root endpoint"""
    return jsonify({
        "message": "F5-TTS API - Local Testing Mode",
        "endpoints": {
            "health": "/health",
            "tts": "/tts"
        },
        "status": "running",
        "note": "This is a simplified version for local testing"
    })

@app.route('/tts', methods=['POST', 'OPTIONS'])
def tts():
    """TTS endpoint - simplified for local testing"""
    
    # Handle CORS preflight
    if request.method == 'OPTIONS':
        response = jsonify({'status': 'ok'})
        response.headers.add('Access-Control-Allow-Origin', '*')
        response.headers.add('Access-Control-Allow-Headers', 'Content-Type')
        response.headers.add('Access-Control-Allow-Methods', 'POST, OPTIONS')
        return response
    
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
        
        # Get query parameters
        speed = request.args.get('speed', '1.0')
        cfg_strength = request.args.get('cfg_strength', '2.0')
        
        # For local testing, return a mock response
        response_data = {
            "message": "TTS request received successfully!",
            "received_data": {
                "ref_audio_filename": ref_audio_file.filename,
                "ref_text": ref_text,
                "gen_text": gen_text,
                "speed": speed,
                "cfg_strength": cfg_strength
            },
            "note": "This is a mock response for local testing. In production, this would generate actual speech.",
            "status": "success"
        }
        
        response = jsonify(response_data)
        response.headers.add('Access-Control-Allow-Origin', '*')
        return response
        
    except Exception as e:
        error_response = {
            "error": f"Internal server error: {str(e)}",
            "status": "error"
        }
        response = jsonify(error_response)
        response.headers.add('Access-Control-Allow-Origin', '*')
        return response, 500

def main():
    """Run the Flask server"""
    host = os.getenv("F5TTS_API_HOST", "127.0.0.1")
    port = int(os.getenv("F5TTS_API_PORT", "8000"))
    debug = os.getenv("F5TTS_API_DEBUG", "true").lower() == "true"
    
    print(f"🚀 Starting F5-TTS Local Testing Server...")
    print(f"📍 Server will be available at: http://{host}:{port}")
    print(f"🔗 Health check: http://{host}:{port}/health")
    print(f"🎤 TTS endpoint: http://{host}:{port}/tts")
    print(f"📋 Root endpoint: http://{host}:{port}/")
    print(f"🐛 Debug mode: {debug}")
    print("\n" + "="*50)
    
    app.run(host=host, port=port, debug=debug)

if __name__ == '__main__':
    main()
