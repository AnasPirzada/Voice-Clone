'use client';

import { useState, useRef, useEffect } from 'react';
import { Upload, Play, Pause, Download, Settings } from 'lucide-react';
import { f5ttsClient, TTSRequest } from '../lib/api';

interface TTSInterfaceProps {
  className?: string;
}

export default function TTSInterface({ className = '' }: TTSInterfaceProps) {
  const [refAudio, setRefAudio] = useState<File | null>(null);
  const [refText, setRefText] = useState('');
  const [genText, setGenText] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [generatedAudio, setGeneratedAudio] = useState<Blob | null>(null);
  const [audioUrl, setAudioUrl] = useState<string | null>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [showAdvanced, setShowAdvanced] = useState(false);
  const [apiConnected, setApiConnected] = useState<boolean | null>(null);

  // Advanced parameters
  const [targetRms, setTargetRms] = useState(0.1);
  const [crossFadeDuration, setCrossFadeDuration] = useState(0.15);
  const [swaySamplingCoef] = useState(-1);
  const [cfgStrength, setCfgStrength] = useState(2);
  const [nfeStep, setNfeStep] = useState(32);
  const [speed, setSpeed] = useState(1.0);
  const [fixDuration] = useState<number | undefined>(undefined);
  const [removeSilence, setRemoveSilence] = useState(false);

  const audioRef = useRef<HTMLAudioElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Check API connection on component mount
  useEffect(() => {
    console.log('TTSInterface: Checking API connection...');
    f5ttsClient.healthCheck().then((result) => {
      console.log('API connection result:', result);
      setApiConnected(result);
    });
  }, []);

  const handleFileUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      setRefAudio(file);
      setError(null);
    }
  };

  const handleGenerate = async () => {
    if (!refAudio || !genText.trim()) {
      setError('Please upload a reference audio file and enter text to generate');
      return;
    }

    setIsLoading(true);
    setError(null);

    const request: TTSRequest = {
      ref_audio: refAudio,
      ref_text: refText.trim() || undefined,
      gen_text: genText.trim(),
      target_rms: targetRms,
      cross_fade_duration: crossFadeDuration,
      sway_sampling_coef: swaySamplingCoef,
      cfg_strength: cfgStrength,
      nfe_step: nfeStep,
      speed: speed,
      fix_duration: fixDuration,
      remove_silence: removeSilence,
    };

    try {
      const response = await f5ttsClient.generateSpeech(request);
      
      if (response.error) {
        setError(response.error);
      } else {
        setGeneratedAudio(response.audio);
        const url = URL.createObjectURL(response.audio);
        setAudioUrl(url);
        setError(null);
      }
    } catch {
      setError('Failed to generate speech. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  const handlePlayPause = () => {
    if (!audioRef.current || !audioUrl) return;

    if (isPlaying) {
      audioRef.current.pause();
      setIsPlaying(false);
    } else {
      audioRef.current.play();
      setIsPlaying(true);
    }
  };

  const handleDownload = () => {
    if (!generatedAudio) return;

    const url = URL.createObjectURL(generatedAudio);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'generated_speech.wav';
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  const handleAudioEnded = () => {
    setIsPlaying(false);
  };

  return (
    <div className={`max-w-4xl mx-auto p-6 space-y-6 ${className}`}>
      {/* Header */}
      <div className="text-center">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">F5-TTS Interface</h1>
        <p className="text-gray-600">Generate speech using F5-TTS API</p>
        
        {/* API Status */}
        <div className="mt-4">
          {apiConnected === null ? (
            <span className="text-yellow-600">Checking API connection...</span>
          ) : apiConnected ? (
            <span className="text-green-600">✓ API Connected</span>
          ) : (
            <span className="text-red-600">✗ API Not Available</span>
          )}
        </div>
      </div>

      {/* Error Display */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <p className="text-red-800">{error}</p>
        </div>
      )}

      {/* Main Form */}
      <div className="bg-white rounded-lg shadow-lg p-6 space-y-6">
        {/* Reference Audio Upload */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Reference Audio File
          </label>
          <div className="flex items-center space-x-4">
            <input
              ref={fileInputRef}
              type="file"
              accept="audio/*"
              onChange={handleFileUpload}
              className="hidden"
            />
            <button
              onClick={() => fileInputRef.current?.click()}
              className="flex items-center space-x-2 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
            >
              <Upload className="w-4 h-4" />
              <span>Choose Audio File</span>
            </button>
            {refAudio && (
              <span className="text-sm text-gray-600">
                {refAudio.name} ({(refAudio.size / 1024 / 1024).toFixed(2)} MB)
              </span>
            )}
          </div>
        </div>

        {/* Reference Text */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Reference Text (Optional)
          </label>
          <textarea
            value={refText}
            onChange={(e) => setRefText(e.target.value)}
            placeholder="Enter the text content of the reference audio (optional, will be transcribed if not provided)"
            className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none"
            rows={3}
          />
        </div>

        {/* Text to Generate */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Text to Generate *
          </label>
          <textarea
            value={genText}
            onChange={(e) => setGenText(e.target.value)}
            placeholder="Enter the text you want to generate as speech"
            className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none"
            rows={4}
            required
          />
        </div>

        {/* Advanced Settings Toggle */}
        <div className="flex items-center space-x-2">
          <button
            onClick={() => setShowAdvanced(!showAdvanced)}
            className="flex items-center space-x-2 text-sm text-blue-600 hover:text-blue-800"
          >
            <Settings className="w-4 h-4" />
            <span>Advanced Settings</span>
          </button>
        </div>

        {/* Advanced Settings */}
        {showAdvanced && (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 p-4 bg-gray-50 rounded-lg">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Target RMS: {targetRms}
              </label>
              <input
                type="range"
                min="0.01"
                max="0.5"
                step="0.01"
                value={targetRms}
                onChange={(e) => setTargetRms(parseFloat(e.target.value))}
                className="w-full"
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Cross Fade Duration: {crossFadeDuration}
              </label>
              <input
                type="range"
                min="0.01"
                max="0.5"
                step="0.01"
                value={crossFadeDuration}
                onChange={(e) => setCrossFadeDuration(parseFloat(e.target.value))}
                className="w-full"
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                CFG Strength: {cfgStrength}
              </label>
              <input
                type="range"
                min="1"
                max="5"
                step="0.1"
                value={cfgStrength}
                onChange={(e) => setCfgStrength(parseFloat(e.target.value))}
                className="w-full"
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                NFE Steps: {nfeStep}
              </label>
              <input
                type="range"
                min="8"
                max="64"
                step="1"
                value={nfeStep}
                onChange={(e) => setNfeStep(parseInt(e.target.value))}
                className="w-full"
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Speed: {speed}x
              </label>
              <input
                type="range"
                min="0.5"
                max="2.0"
                step="0.1"
                value={speed}
                onChange={(e) => setSpeed(parseFloat(e.target.value))}
                className="w-full"
              />
            </div>
            
            <div className="flex items-center space-x-2">
              <input
                type="checkbox"
                id="removeSilence"
                checked={removeSilence}
                onChange={(e) => setRemoveSilence(e.target.checked)}
                className="rounded"
              />
              <label htmlFor="removeSilence" className="text-sm font-medium text-gray-700">
                Remove Silence
              </label>
            </div>
          </div>
        )}

        {/* Generate Button */}
        <button
          onClick={handleGenerate}
          disabled={isLoading || !refAudio || !genText.trim()}
          className="w-full bg-blue-600 text-white py-3 px-6 rounded-lg font-medium hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed transition-colors"
        >
          {isLoading ? 'Generating...' : 'Generate Speech'}
        </button>
      </div>

      {/* Audio Player */}
      {audioUrl && (
        <div className="bg-white rounded-lg shadow-lg p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Generated Audio</h3>
          <div className="flex items-center space-x-4">
            <button
              onClick={handlePlayPause}
              className="flex items-center justify-center w-12 h-12 bg-blue-600 text-white rounded-full hover:bg-blue-700 transition-colors"
            >
              {isPlaying ? <Pause className="w-6 h-6" /> : <Play className="w-6 h-6" />}
            </button>
            <button
              onClick={handleDownload}
              className="flex items-center space-x-2 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
            >
              <Download className="w-4 h-4" />
              <span>Download</span>
            </button>
          </div>
          <audio
            ref={audioRef}
            src={audioUrl}
            onEnded={handleAudioEnded}
            className="hidden"
          />
        </div>
      )}
    </div>
  );
}