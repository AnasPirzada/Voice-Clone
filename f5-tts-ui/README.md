# F5-TTS UI

A Next.js frontend for the F5-TTS voice cloning application.

## Features

- 🎤 Upload reference audio files
- 📝 Enter text to generate speech
- 🎵 Download generated audio
- 🔗 Connected to Render API backend

## API Connection

The UI is configured to connect to the Render API at:
`https://voice-clone-3pyz.onrender.com`

## Environment Variables

Set the following environment variable in Vercel:

- `NEXT_PUBLIC_API_URL`: `https://voice-clone-3pyz.onrender.com`

## Deployment

This app is configured for deployment on Vercel with automatic builds from the main branch.

## Development

```bash
npm install
npm run dev
```

## Build

```bash
npm run build
npm start
```
