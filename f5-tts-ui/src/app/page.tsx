'use client';

import { useState, useEffect } from 'react';

export default function Home() {
  const [apiConnected, setApiConnected] = useState<boolean | null>(null);
  const [apiUrl] = useState(process.env.NEXT_PUBLIC_API_URL || 'http://127.0.0.1:8000');

  useEffect(() => {
    // Test API connection
    fetch(`${apiUrl}/health`)
      .then(response => response.ok)
      .then(setApiConnected)
      .catch(() => setApiConnected(false));
  }, [apiUrl]);

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="max-w-4xl mx-auto">
        <div className="text-center mb-8">
          <h1 className="text-4xl font-bold text-gray-900 mb-4">F5-TTS Interface</h1>
          <p className="text-lg text-gray-600 mb-4">Generate speech using F5-TTS API</p>
          
          {/* API Status */}
          <div className="mb-6">
            {apiConnected === null ? (
              <span className="text-yellow-600">Checking API connection...</span>
            ) : apiConnected ? (
              <span className="text-green-600 text-lg font-semibold">✓ API Connected</span>
            ) : (
              <span className="text-red-600 text-lg font-semibold">✗ API Not Available</span>
            )}
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-lg p-8">
          <h2 className="text-2xl font-semibold text-gray-900 mb-6">F5-TTS Interface</h2>
          
          <div className="space-y-4">
            <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
              <h3 className="font-semibold text-blue-900 mb-2">API Information</h3>
              <p className="text-blue-800">
                <strong>Backend URL:</strong> {apiUrl}
              </p>
              <p className="text-blue-800">
                <strong>Status:</strong> {apiConnected ? 'Connected' : 'Not Connected'}
              </p>
            </div>

            <div className="p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
              <h3 className="font-semibold text-yellow-900 mb-2">Note</h3>
              <p className="text-yellow-800">
                This is a simplified interface for testing the F5-TTS API deployment. 
                The full TTS functionality requires a more powerful hosting solution than Vercel's free tier.
              </p>
            </div>

            <div className="p-4 bg-green-50 border border-green-200 rounded-lg">
              <h3 className="font-semibold text-green-900 mb-2">Available Endpoints</h3>
              <ul className="text-green-800 space-y-1">
                <li>• <code>{apiUrl}/</code> - Root endpoint</li>
                <li>• <code>{apiUrl}/health</code> - Health check</li>
                <li>• <code>{apiUrl}/tts</code> - TTS endpoint (simplified)</li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
