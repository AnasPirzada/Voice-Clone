#!/usr/bin/env python3
"""
WSGI entry point for Render deployment
"""
import sys
import os

# Add the src directory to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

# Import the Flask app
from f5_tts.server import app

if __name__ == "__main__":
    app.run()
