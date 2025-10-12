#!/usr/bin/env python3
"""
Simple Flask app for Render deployment
"""
import os
import sys
import io
import json
from flask import Flask, jsonify, request, send_file

# Add src to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

app = Flask(__name__)

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        "status": "ok", 
        "message": "F5-TTS API is running on Render",
        "version": "1.0.0"
    })

@app.route('/tts', methods=['POST', 'OPTIONS'])
def tts():
    """TTS endpoint - simplified for Render deployment"""
    
    # Handle CORS preflight
    if request.method == 'OPTIONS':
        response = jsonify({'status': 'ok'})
        response.headers.add('Access-Control-Allow-Origin', '*')
        response.headers.add('Access-Control-Allow-Headers', 'Content-Type')
        response.headers.add('Access-Control-Allow-Methods', 'POST, OPTIONS')
        return response
    
    try:
        # For now, return a mock response since F5-TTS requires significant resources
        # In production, you'd want to use a more powerful service
        response_data = {
            "message": "F5-TTS API endpoint is available but requires more resources for full functionality.",
            "suggestion": "Consider using Google Cloud Run, AWS Lambda with more memory, or a dedicated server for F5-TTS deployment.",
            "status": "limited",
            "note": "This is a simplified version for testing deployment on Render"
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
