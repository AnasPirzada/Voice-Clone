# F5-TTS UI Requirements & Components

## Project Overview
A Next.js frontend application for F5-TTS voice cloning with modern UI/UX design.

## Technology Stack

### Core Technologies
- **Framework:** Next.js 15.5.4
- **Language:** TypeScript
- **Styling:** Tailwind CSS
- **Icons:** Lucide React
- **State Management:** React Hooks (useState, useEffect)

### Dependencies
```json
{
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "next": "15.5.4",
    "lucide-react": "^0.263.1"
  },
  "devDependencies": {
    "typescript": "^5.2.2",
    "@types/node": "^20.5.2",
    "@types/react": "^18.2.20",
    "@types/react-dom": "^18.2.7",
    "tailwindcss": "^3.3.3",
    "postcss": "^8.4.28",
    "autoprefixer": "^10.4.14",
    "eslint": "^8.48.0",
    "eslint-config-next": "15.5.4"
  }
}
```

---

## Required Components

### 1. Main Interface Component (`TTSInterface.tsx`)
**Purpose:** Main TTS interface with file upload and text input

**Features:**
- Audio file upload (drag & drop)
- Text input for generation
- Reference text input (optional)
- Advanced parameters panel
- Generate button
- Audio player for results
- Download functionality

**Props:**
```typescript
interface TTSInterfaceProps {
  apiUrl?: string;
  onError?: (error: string) => void;
  onSuccess?: (audioUrl: string) => void;
}
```

### 2. API Client (`api.ts`)
**Purpose:** Handle all API communications

**Features:**
- Health check functionality
- TTS request handling
- Error handling
- File upload management
- Response processing

### 3. Audio Player Component
**Purpose:** Play generated audio files

**Features:**
- Play/pause controls
- Progress bar
- Volume control
- Download button
- Waveform visualization (optional)

### 4. File Upload Component
**Purpose:** Handle audio file uploads

**Features:**
- Drag & drop interface
- File validation
- Progress indicator
- File preview
- Supported formats: WAV, MP3, FLAC, M4A

---

## UI/UX Requirements

### Design Principles
- **Modern & Clean:** Minimalist design with focus on functionality
- **Responsive:** Works on desktop, tablet, and mobile
- **Accessible:** WCAG 2.1 AA compliance
- **Intuitive:** Easy to understand and use

### Color Scheme
```css
/* Primary Colors */
--primary: #3b82f6;      /* Blue */
--primary-dark: #1d4ed8; /* Dark Blue */
--secondary: #64748b;    /* Slate */

/* Status Colors */
--success: #10b981;      /* Green */
--error: #ef4444;        /* Red */
--warning: #f59e0b;      /* Amber */

/* Neutral Colors */
--background: #ffffff;   /* White */
--surface: #f8fafc;      /* Light Gray */
--text: #1e293b;         /* Dark Gray */
--text-muted: #64748b;   /* Medium Gray */
```

### Layout Structure
```
┌─────────────────────────────────────┐
│              Header                 │
├─────────────────────────────────────┤
│                                     │
│         Main Interface              │
│                                     │
│  ┌─────────────┐  ┌─────────────┐   │
│  │ File Upload │  │ Text Input  │   │
│  │   Area      │  │   Area      │   │
│  └─────────────┘  └─────────────┘   │
│                                     │
│  ┌─────────────────────────────────┐ │
│  │     Advanced Parameters         │ │
│  └─────────────────────────────────┘ │
│                                     │
│  ┌─────────────────────────────────┐ │
│  │        Generate Button          │ │
│  └─────────────────────────────────┘ │
│                                     │
│  ┌─────────────────────────────────┐ │
│  │       Audio Player              │ │
│  └─────────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

---

## Required Features

### 1. File Upload
- **Drag & Drop:** Visual feedback when dragging files
- **File Validation:** Check file type and size
- **Progress Indicator:** Show upload progress
- **Error Handling:** Display validation errors
- **Preview:** Show selected file information

### 2. Text Input
- **Multi-line Support:** For longer texts
- **Character Counter:** Show remaining characters
- **Auto-resize:** Expand textarea as needed
- **Placeholder Text:** Helpful examples

### 3. Advanced Parameters
- **Collapsible Panel:** Hide/show advanced options
- **Parameter Controls:**
  - Speed slider (0.5x - 2.0x)
  - CFG Strength slider (1.0 - 5.0)
  - NFE Steps input (8 - 64)
  - Target RMS slider (0.05 - 0.3)
  - Remove Silence toggle
  - Fix Duration input (optional)

### 4. Generation Process
- **Loading States:** Show progress during generation
- **Cancel Option:** Allow user to cancel request
- **Error Display:** Show detailed error messages
- **Success Feedback:** Confirm successful generation

### 5. Audio Playback
- **Player Controls:** Play, pause, stop, seek
- **Progress Bar:** Visual progress indicator
- **Volume Control:** Adjust playback volume
- **Download Button:** Save generated audio
- **Waveform Display:** Visual audio representation (optional)

### 6. Status Indicators
- **API Connection:** Show if backend is connected
- **Generation Status:** Current processing state
- **Error States:** Clear error messaging
- **Success States:** Confirmation messages

---

## State Management

### Required State Variables
```typescript
interface TTSState {
  // File handling
  selectedFile: File | null;
  isUploading: boolean;
  
  // Text input
  referenceText: string;
  generationText: string;
  
  // Parameters
  parameters: TTSParameters;
  
  // Generation
  isGenerating: boolean;
  generatedAudio: string | null;
  
  // Status
  apiConnected: boolean;
  error: string | null;
  success: string | null;
}
```

### TTSParameters Interface
```typescript
interface TTSParameters {
  target_rms: number;
  cross_fade_duration: number;
  sway_sampling_coef: number;
  cfg_strength: number;
  nfe_step: number;
  speed: number;
  fix_duration?: number;
  remove_silence: boolean;
}
```

---

## API Integration

### Environment Variables
```env
NEXT_PUBLIC_API_URL=https://voice-clone-3pyz.onrender.com
```

### API Client Usage
```typescript
import { F5TTSClient } from './lib/api';

const client = new F5TTSClient();

// Health check
const isHealthy = await client.healthCheck();

// Generate speech
const result = await client.generateSpeech({
  ref_audio: file,
  ref_text: referenceText,
  gen_text: generationText,
  speed: 1.0,
  cfg_strength: 2.0
});
```

---

## Responsive Design

### Breakpoints
```css
/* Mobile First Approach */
sm: '640px'   /* Small devices */
md: '768px'   /* Medium devices */
lg: '1024px'  /* Large devices */
xl: '1280px'  /* Extra large devices */
2xl: '1536px' /* 2X large devices */
```

### Mobile Considerations
- **Touch-friendly:** Large tap targets (44px minimum)
- **Simplified Layout:** Stack components vertically
- **Optimized Forms:** Easy text input on mobile
- **File Upload:** Native file picker integration

---

## Accessibility Requirements

### WCAG 2.1 AA Compliance
- **Keyboard Navigation:** All interactive elements accessible via keyboard
- **Screen Reader Support:** Proper ARIA labels and roles
- **Color Contrast:** Minimum 4.5:1 ratio for text
- **Focus Indicators:** Clear focus states
- **Error Messages:** Descriptive and helpful

### ARIA Labels
```typescript
// Example ARIA implementation
<button
  aria-label="Generate speech from text"
  aria-describedby="generate-help"
  disabled={isGenerating}
>
  {isGenerating ? 'Generating...' : 'Generate Speech'}
</button>
```

---

## Performance Requirements

### Loading Times
- **Initial Load:** < 3 seconds
- **File Upload:** Progress indication
- **Generation:** Loading states with estimated time
- **Audio Playback:** Instant start

### Optimization
- **Code Splitting:** Lazy load components
- **Image Optimization:** Next.js Image component
- **Bundle Size:** Keep under 500KB initial bundle
- **Caching:** Cache API responses when appropriate

---

## Error Handling

### Error Types
1. **Network Errors:** Connection issues
2. **Validation Errors:** Invalid file format, missing text
3. **API Errors:** Server-side processing errors
4. **File Errors:** Upload failures, size limits

### Error Display
```typescript
interface ErrorState {
  type: 'network' | 'validation' | 'api' | 'file';
  message: string;
  details?: string;
  retryable: boolean;
}
```

---

## Testing Requirements

### Unit Tests
- Component rendering
- State management
- API client functions
- Utility functions

### Integration Tests
- File upload flow
- API communication
- Error handling
- User interactions

### E2E Tests
- Complete user journey
- Cross-browser compatibility
- Mobile responsiveness

---

## Deployment Configuration

### Vercel Configuration
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

### Environment Variables
```env
# Production
NEXT_PUBLIC_API_URL=https://voice-clone-3pyz.onrender.com

# Development
NEXT_PUBLIC_API_URL=http://localhost:8000
```
