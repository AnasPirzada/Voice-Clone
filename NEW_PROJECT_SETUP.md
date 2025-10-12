# New Next.js Project Setup Guide

## Quick Start Commands

### 1. Create New Next.js Project
```bash
# Create new Next.js project with TypeScript and Tailwind
npx create-next-app@latest f5-tts-ui --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"

# Navigate to project directory
cd f5-tts-ui
```

### 2. Install Additional Dependencies
```bash
# Install Lucide React for icons
npm install lucide-react

# Install additional types (if needed)
npm install --save-dev @types/react @types/react-dom
```

### 3. Project Structure
```
f5-tts-ui/
├── src/
│   ├── app/
│   │   ├── globals.css
│   │   ├── layout.tsx
│   │   └── page.tsx
│   ├── components/
│   │   ├── TTSInterface.tsx
│   │   ├── AudioPlayer.tsx
│   │   ├── FileUpload.tsx
│   │   └── ParameterPanel.tsx
│   ├── lib/
│   │   └── api.ts
│   └── types/
│       └── index.ts
├── public/
├── package.json
├── tailwind.config.ts
├── tsconfig.json
└── next.config.js
```

---

## Step-by-Step Implementation

### Step 1: Create Type Definitions
Create `src/types/index.ts`:
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

export interface TTSParameters {
  target_rms: number;
  cross_fade_duration: number;
  sway_sampling_coef: number;
  cfg_strength: number;
  nfe_step: number;
  speed: number;
  fix_duration?: number;
  remove_silence: boolean;
}

export interface TTSState {
  selectedFile: File | null;
  isUploading: boolean;
  referenceText: string;
  generationText: string;
  parameters: TTSParameters;
  isGenerating: boolean;
  generatedAudio: string | null;
  apiConnected: boolean;
  error: string | null;
  success: string | null;
}
```

### Step 2: Create API Client
Create `src/lib/api.ts`:
```typescript
import { TTSRequest, TTSResponse } from '@/types';

export class F5TTSClient {
  private baseUrl: string;

  constructor(baseUrl?: string) {
    this.baseUrl = baseUrl || process.env.NEXT_PUBLIC_API_URL || 'https://voice-clone-3pyz.onrender.com';
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

export const f5ttsClient = new F5TTSClient();
```

### Step 3: Create File Upload Component
Create `src/components/FileUpload.tsx`:
```typescript
'use client';

import { useState, useRef } from 'react';
import { Upload, FileAudio, X } from 'lucide-react';

interface FileUploadProps {
  onFileSelect: (file: File) => void;
  selectedFile: File | null;
  onRemove: () => void;
}

export default function FileUpload({ onFileSelect, selectedFile, onRemove }: FileUploadProps) {
  const [isDragOver, setIsDragOver] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragOver(true);
  };

  const handleDragLeave = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragOver(false);
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragOver(false);
    
    const files = Array.from(e.dataTransfer.files);
    const audioFile = files.find(file => file.type.startsWith('audio/'));
    
    if (audioFile) {
      onFileSelect(audioFile);
    }
  };

  const handleFileInput = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      onFileSelect(file);
    }
  };

  const openFileDialog = () => {
    fileInputRef.current?.click();
  };

  return (
    <div className="w-full">
      {selectedFile ? (
        <div className="border-2 border-green-500 border-dashed rounded-lg p-6 bg-green-50">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <FileAudio className="h-8 w-8 text-green-600" />
              <div>
                <p className="text-sm font-medium text-green-800">{selectedFile.name}</p>
                <p className="text-xs text-green-600">
                  {(selectedFile.size / 1024 / 1024).toFixed(2)} MB
                </p>
              </div>
            </div>
            <button
              onClick={onRemove}
              className="p-1 hover:bg-green-200 rounded-full transition-colors"
            >
              <X className="h-4 w-4 text-green-600" />
            </button>
          </div>
        </div>
      ) : (
        <div
          className={`border-2 border-dashed rounded-lg p-8 text-center cursor-pointer transition-colors ${
            isDragOver
              ? 'border-blue-500 bg-blue-50'
              : 'border-gray-300 hover:border-gray-400'
          }`}
          onDragOver={handleDragOver}
          onDragLeave={handleDragLeave}
          onDrop={handleDrop}
          onClick={openFileDialog}
        >
          <Upload className="h-12 w-12 text-gray-400 mx-auto mb-4" />
          <p className="text-lg font-medium text-gray-700 mb-2">
            Upload Reference Audio
          </p>
          <p className="text-sm text-gray-500 mb-4">
            Drag and drop an audio file here, or click to browse
          </p>
          <p className="text-xs text-gray-400">
            Supports WAV, MP3, FLAC, M4A (Max 50MB)
          </p>
          <input
            ref={fileInputRef}
            type="file"
            accept="audio/*"
            onChange={handleFileInput}
            className="hidden"
          />
        </div>
      )}
    </div>
  );
}
```

### Step 4: Create Audio Player Component
Create `src/components/AudioPlayer.tsx`:
```typescript
'use client';

import { useState, useRef, useEffect } from 'react';
import { Play, Pause, Download, Volume2 } from 'lucide-react';

interface AudioPlayerProps {
  audioUrl: string;
  fileName?: string;
}

export default function AudioPlayer({ audioUrl, fileName = 'generated_audio.wav' }: AudioPlayerProps) {
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);
  const [volume, setVolume] = useState(1);
  const audioRef = useRef<HTMLAudioElement>(null);

  useEffect(() => {
    const audio = audioRef.current;
    if (!audio) return;

    const updateTime = () => setCurrentTime(audio.currentTime);
    const updateDuration = () => setDuration(audio.duration);

    audio.addEventListener('timeupdate', updateTime);
    audio.addEventListener('loadedmetadata', updateDuration);
    audio.addEventListener('ended', () => setIsPlaying(false));

    return () => {
      audio.removeEventListener('timeupdate', updateTime);
      audio.removeEventListener('loadedmetadata', updateDuration);
      audio.removeEventListener('ended', () => setIsPlaying(false));
    };
  }, []);

  const togglePlayPause = () => {
    const audio = audioRef.current;
    if (!audio) return;

    if (isPlaying) {
      audio.pause();
    } else {
      audio.play();
    }
    setIsPlaying(!isPlaying);
  };

  const handleSeek = (e: React.ChangeEvent<HTMLInputElement>) => {
    const audio = audioRef.current;
    if (!audio) return;

    const newTime = parseFloat(e.target.value);
    audio.currentTime = newTime;
    setCurrentTime(newTime);
  };

  const handleVolumeChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const audio = audioRef.current;
    if (!audio) return;

    const newVolume = parseFloat(e.target.value);
    audio.volume = newVolume;
    setVolume(newVolume);
  };

  const downloadAudio = () => {
    const link = document.createElement('a');
    link.href = audioUrl;
    link.download = fileName;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const formatTime = (time: number) => {
    const minutes = Math.floor(time / 60);
    const seconds = Math.floor(time % 60);
    return `${minutes}:${seconds.toString().padStart(2, '0')}`;
  };

  return (
    <div className="bg-white rounded-lg border border-gray-200 p-6">
      <div className="flex items-center space-x-4 mb-4">
        <button
          onClick={togglePlayPause}
          className="flex items-center justify-center w-12 h-12 bg-blue-600 text-white rounded-full hover:bg-blue-700 transition-colors"
        >
          {isPlaying ? (
            <Pause className="h-6 w-6" />
          ) : (
            <Play className="h-6 w-6 ml-1" />
          )}
        </button>
        
        <div className="flex-1">
          <div className="flex items-center space-x-2 mb-2">
            <input
              type="range"
              min="0"
              max={duration || 0}
              value={currentTime}
              onChange={handleSeek}
              className="flex-1 h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer"
            />
            <span className="text-sm text-gray-500 min-w-[80px]">
              {formatTime(currentTime)} / {formatTime(duration)}
            </span>
          </div>
        </div>

        <div className="flex items-center space-x-2">
          <Volume2 className="h-4 w-4 text-gray-500" />
          <input
            type="range"
            min="0"
            max="1"
            step="0.1"
            value={volume}
            onChange={handleVolumeChange}
            className="w-20 h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer"
          />
        </div>

        <button
          onClick={downloadAudio}
          className="flex items-center space-x-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
        >
          <Download className="h-4 w-4" />
          <span>Download</span>
        </button>
      </div>

      <audio ref={audioRef} src={audioUrl} preload="metadata" />
    </div>
  );
}
```

### Step 5: Create Parameter Panel Component
Create `src/components/ParameterPanel.tsx`:
```typescript
'use client';

import { useState } from 'react';
import { ChevronDown, ChevronUp } from 'lucide-react';
import { TTSParameters } from '@/types';

interface ParameterPanelProps {
  parameters: TTSParameters;
  onParametersChange: (parameters: TTSParameters) => void;
}

export default function ParameterPanel({ parameters, onParametersChange }: ParameterPanelProps) {
  const [isExpanded, setIsExpanded] = useState(false);

  const updateParameter = (key: keyof TTSParameters, value: number | boolean) => {
    onParametersChange({
      ...parameters,
      [key]: value,
    });
  };

  return (
    <div className="bg-white rounded-lg border border-gray-200">
      <button
        onClick={() => setIsExpanded(!isExpanded)}
        className="w-full flex items-center justify-between p-4 hover:bg-gray-50 transition-colors"
      >
        <h3 className="text-lg font-medium text-gray-900">Advanced Parameters</h3>
        {isExpanded ? (
          <ChevronUp className="h-5 w-5 text-gray-500" />
        ) : (
          <ChevronDown className="h-5 w-5 text-gray-500" />
        )}
      </button>

      {isExpanded && (
        <div className="p-4 border-t border-gray-200 space-y-6">
          {/* Speed */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Speed: {parameters.speed}x
            </label>
            <input
              type="range"
              min="0.5"
              max="2.0"
              step="0.1"
              value={parameters.speed}
              onChange={(e) => updateParameter('speed', parseFloat(e.target.value))}
              className="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer"
            />
            <div className="flex justify-between text-xs text-gray-500 mt-1">
              <span>0.5x</span>
              <span>2.0x</span>
            </div>
          </div>

          {/* CFG Strength */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              CFG Strength: {parameters.cfg_strength}
            </label>
            <input
              type="range"
              min="1.0"
              max="5.0"
              step="0.1"
              value={parameters.cfg_strength}
              onChange={(e) => updateParameter('cfg_strength', parseFloat(e.target.value))}
              className="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer"
            />
            <div className="flex justify-between text-xs text-gray-500 mt-1">
              <span>1.0</span>
              <span>5.0</span>
            </div>
          </div>

          {/* NFE Steps */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              NFE Steps: {parameters.nfe_step}
            </label>
            <input
              type="range"
              min="8"
              max="64"
              step="1"
              value={parameters.nfe_step}
              onChange={(e) => updateParameter('nfe_step', parseInt(e.target.value))}
              className="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer"
            />
            <div className="flex justify-between text-xs text-gray-500 mt-1">
              <span>8</span>
              <span>64</span>
            </div>
          </div>

          {/* Target RMS */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Target RMS: {parameters.target_rms}
            </label>
            <input
              type="range"
              min="0.05"
              max="0.3"
              step="0.01"
              value={parameters.target_rms}
              onChange={(e) => updateParameter('target_rms', parseFloat(e.target.value))}
              className="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer"
            />
            <div className="flex justify-between text-xs text-gray-500 mt-1">
              <span>0.05</span>
              <span>0.3</span>
            </div>
          </div>

          {/* Remove Silence */}
          <div className="flex items-center space-x-3">
            <input
              type="checkbox"
              id="remove_silence"
              checked={parameters.remove_silence}
              onChange={(e) => updateParameter('remove_silence', e.target.checked)}
              className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
            />
            <label htmlFor="remove_silence" className="text-sm font-medium text-gray-700">
              Remove silence from output
            </label>
          </div>
        </div>
      )}
    </div>
  );
}
```

### Step 6: Create Main TTS Interface
Create `src/components/TTSInterface.tsx`:
```typescript
'use client';

import { useState, useEffect } from 'react';
import { Mic, MicOff, Loader2, CheckCircle, AlertCircle } from 'lucide-react';
import { f5ttsClient } from '@/lib/api';
import { TTSState, TTSParameters } from '@/types';
import FileUpload from './FileUpload';
import AudioPlayer from './AudioPlayer';
import ParameterPanel from './ParameterPanel';

const defaultParameters: TTSParameters = {
  target_rms: 0.1,
  cross_fade_duration: 0.15,
  sway_sampling_coef: -1.0,
  cfg_strength: 2.0,
  nfe_step: 32,
  speed: 1.0,
  remove_silence: false,
};

export default function TTSInterface() {
  const [state, setState] = useState<TTSState>({
    selectedFile: null,
    isUploading: false,
    referenceText: '',
    generationText: '',
    parameters: defaultParameters,
    isGenerating: false,
    generatedAudio: null,
    apiConnected: false,
    error: null,
    success: null,
  });

  // Check API connection on mount
  useEffect(() => {
    const checkAPI = async () => {
      const isConnected = await f5ttsClient.healthCheck();
      setState(prev => ({ ...prev, apiConnected: isConnected }));
    };
    checkAPI();
  }, []);

  const handleFileSelect = (file: File) => {
    setState(prev => ({ ...prev, selectedFile: file, error: null }));
  };

  const handleFileRemove = () => {
    setState(prev => ({ ...prev, selectedFile: null }));
  };

  const handleGenerate = async () => {
    if (!state.selectedFile || !state.generationText.trim()) {
      setState(prev => ({ 
        ...prev, 
        error: 'Please select an audio file and enter text to generate' 
      }));
      return;
    }

    setState(prev => ({ ...prev, isGenerating: true, error: null, success: null }));

    try {
      const result = await f5ttsClient.generateSpeech({
        ref_audio: state.selectedFile,
        ref_text: state.referenceText,
        gen_text: state.generationText,
        ...state.parameters,
      });

      if (result.error) {
        setState(prev => ({ ...prev, error: result.error, isGenerating: false }));
      } else {
        const audioUrl = URL.createObjectURL(result.audio);
        setState(prev => ({ 
          ...prev, 
          generatedAudio: audioUrl, 
          isGenerating: false,
          success: 'Speech generated successfully!'
        }));
      }
    } catch (error) {
      setState(prev => ({ 
        ...prev, 
        error: 'Failed to generate speech. Please try again.',
        isGenerating: false 
      }));
    }
  };

  return (
    <div className="max-w-4xl mx-auto p-6 space-y-6">
      {/* Header */}
      <div className="text-center">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">F5-TTS Voice Cloning</h1>
        <p className="text-gray-600">Generate speech from text using reference audio</p>
        
        {/* API Status */}
        <div className="flex items-center justify-center space-x-2 mt-4">
          {state.apiConnected ? (
            <>
              <CheckCircle className="h-5 w-5 text-green-500" />
              <span className="text-green-600 font-medium">API Connected</span>
            </>
          ) : (
            <>
              <AlertCircle className="h-5 w-5 text-red-500" />
              <span className="text-red-600 font-medium">API Disconnected</span>
            </>
          )}
        </div>
      </div>

      {/* File Upload */}
      <div>
        <h2 className="text-xl font-semibold text-gray-900 mb-4">1. Upload Reference Audio</h2>
        <FileUpload
          onFileSelect={handleFileSelect}
          selectedFile={state.selectedFile}
          onRemove={handleFileRemove}
        />
      </div>

      {/* Text Inputs */}
      <div className="grid md:grid-cols-2 gap-6">
        <div>
          <h2 className="text-xl font-semibold text-gray-900 mb-4">2. Reference Text (Optional)</h2>
          <textarea
            value={state.referenceText}
            onChange={(e) => setState(prev => ({ ...prev, referenceText: e.target.value }))}
            placeholder="Enter the text content of your reference audio..."
            className="w-full h-32 p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none"
          />
        </div>

        <div>
          <h2 className="text-xl font-semibold text-gray-900 mb-4">3. Text to Generate</h2>
          <textarea
            value={state.generationText}
            onChange={(e) => setState(prev => ({ ...prev, generationText: e.target.value }))}
            placeholder="Enter the text you want to generate speech for..."
            className="w-full h-32 p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none"
            required
          />
        </div>
      </div>

      {/* Advanced Parameters */}
      <div>
        <h2 className="text-xl font-semibold text-gray-900 mb-4">4. Advanced Parameters</h2>
        <ParameterPanel
          parameters={state.parameters}
          onParametersChange={(parameters) => setState(prev => ({ ...prev, parameters }))}
        />
      </div>

      {/* Generate Button */}
      <div className="text-center">
        <button
          onClick={handleGenerate}
          disabled={state.isGenerating || !state.apiConnected}
          className="inline-flex items-center space-x-2 px-8 py-3 bg-blue-600 text-white font-medium rounded-lg hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed transition-colors"
        >
          {state.isGenerating ? (
            <>
              <Loader2 className="h-5 w-5 animate-spin" />
              <span>Generating...</span>
            </>
          ) : (
            <>
              <Mic className="h-5 w-5" />
              <span>Generate Speech</span>
            </>
          )}
        </button>
      </div>

      {/* Status Messages */}
      {state.error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <div className="flex items-center space-x-2">
            <AlertCircle className="h-5 w-5 text-red-500" />
            <span className="text-red-700">{state.error}</span>
          </div>
        </div>
      )}

      {state.success && (
        <div className="bg-green-50 border border-green-200 rounded-lg p-4">
          <div className="flex items-center space-x-2">
            <CheckCircle className="h-5 w-5 text-green-500" />
            <span className="text-green-700">{state.success}</span>
          </div>
        </div>
      )}

      {/* Audio Player */}
      {state.generatedAudio && (
        <div>
          <h2 className="text-xl font-semibold text-gray-900 mb-4">Generated Audio</h2>
          <AudioPlayer audioUrl={state.generatedAudio} />
        </div>
      )}
    </div>
  );
}
```

### Step 7: Update Main Page
Update `src/app/page.tsx`:
```typescript
import TTSInterface from '@/components/TTSInterface';

export default function Home() {
  return (
    <main className="min-h-screen bg-gray-50">
      <TTSInterface />
    </main>
  );
}
```

### Step 8: Environment Configuration
Create `.env.local`:
```env
NEXT_PUBLIC_API_URL=https://voice-clone-3pyz.onrender.com
```

Create `.env.example`:
```env
NEXT_PUBLIC_API_URL=https://voice-clone-3pyz.onrender.com
```

### Step 9: Vercel Configuration
Create `vercel.json`:
```json
{
  "framework": "nextjs",
  "buildCommand": "npm run build",
  "outputDirectory": ".next",
  "installCommand": "npm install",
  "env": {
    "NEXT_PUBLIC_API_URL": "https://voice-clone-3pyz.onrender.com"
  }
}
```

---

## Development Commands

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build

# Start production server
npm start

# Run linting
npm run lint
```

---

## Deployment to Vercel

1. **Push to GitHub:**
   ```bash
   git add .
   git commit -m "Initial F5-TTS UI setup"
   git push origin main
   ```

2. **Deploy to Vercel:**
   - Go to [vercel.com](https://vercel.com)
   - Import your GitHub repository
   - Set root directory to your project folder
   - Add environment variable: `NEXT_PUBLIC_API_URL=https://voice-clone-3pyz.onrender.com`
   - Deploy

---

## Features Included

✅ **File Upload** - Drag & drop audio files
✅ **Text Input** - Reference and generation text
✅ **Advanced Parameters** - Speed, CFG strength, etc.
✅ **Audio Player** - Play, pause, seek, download
✅ **API Integration** - Connected to Render backend
✅ **Error Handling** - User-friendly error messages
✅ **Loading States** - Progress indicators
✅ **Responsive Design** - Mobile-friendly
✅ **TypeScript** - Type safety
✅ **Tailwind CSS** - Modern styling

Your new F5-TTS UI project is now ready! 🚀
