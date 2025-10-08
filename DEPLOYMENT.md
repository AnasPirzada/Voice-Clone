# F5-TTS Deployment Guide

This guide will help you deploy both the F5-TTS backend API and the Next.js UI to Vercel.

## ⚠️ Important Note

F5-TTS is a resource-intensive model that requires significant computational power. Vercel's serverless environment has limitations that may not be suitable for the full F5-TTS model. This deployment provides a basic API structure that you can extend with more powerful hosting solutions.

## Prerequisites

1. GitHub account with your F5-TTS repository
2. Vercel account (free tier available)
3. Git installed locally

## Step 1: Deploy Backend API to Vercel

### 1.1 Connect Repository to Vercel

1. Go to [Vercel Dashboard](https://vercel.com/dashboard)
2. Click "New Project"
3. Import your GitHub repository: `AnasPirzada/Voice-Clone`
4. Configure the project:
   - **Framework Preset**: Other
   - **Root Directory**: Leave as default (root)
   - **Build Command**: Leave empty (Vercel will auto-detect)
   - **Output Directory**: Leave empty

### 1.2 Environment Variables

Add these environment variables in Vercel dashboard:
- `F5TTS_MODEL`: `F5TTS_v1_Base`
- `F5TTS_DEVICE`: `cpu`

### 1.3 Deploy

Click "Deploy" and wait for the deployment to complete.

**Your backend API will be available at**: `https://your-project-name.vercel.app`

## Step 2: Deploy UI to Vercel

### 2.1 Create UI Repository

1. Create a new repository for the UI (or use a subfolder)
2. Copy the `f5-tts-ui` folder contents to the new repository
3. Push to GitHub

### 2.2 Deploy UI

1. Go to Vercel Dashboard
2. Click "New Project"
3. Import your UI repository
4. Configure:
   - **Framework Preset**: Next.js
   - **Root Directory**: Leave as default
   - **Build Command**: `npm run build`
   - **Output Directory**: `.next`

### 2.3 Environment Variables for UI

Add this environment variable:
- `NEXT_PUBLIC_API_URL`: `https://your-backend-project-name.vercel.app`

### 2.4 Deploy

Click "Deploy" and wait for completion.

**Your UI will be available at**: `https://your-ui-project-name.vercel.app`

## Step 3: Alternative Backend Solutions

Since Vercel has limitations for heavy ML models, consider these alternatives:

### Option 1: Google Cloud Run
```bash
# Build and deploy to Cloud Run
gcloud run deploy f5-tts-api \
  --source . \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --memory 4Gi \
  --cpu 2 \
  --timeout 900
```

### Option 2: AWS Lambda with Container
```bash
# Build Docker image
docker build -t f5-tts-api .

# Deploy to Lambda
aws lambda create-function \
  --function-name f5-tts-api \
  --package-type Image \
  --code ImageUri=your-account.dkr.ecr.region.amazonaws.com/f5-tts-api:latest \
  --role arn:aws:iam::your-account:role/lambda-execution-role \
  --memory-size 3008 \
  --timeout 900
```

### Option 3: Railway or Render
These platforms offer more resources for ML applications:
- [Railway](https://railway.app/)
- [Render](https://render.com/)

## Step 4: Update API URL

Once you have your backend deployed, update the UI's environment variable:

1. Go to your UI project in Vercel Dashboard
2. Go to Settings → Environment Variables
3. Update `NEXT_PUBLIC_API_URL` to your actual backend URL
4. Redeploy the UI

## Testing the Deployment

1. Visit your UI URL
2. Check the API status indicator (should show "✓ API Connected")
3. Try uploading an audio file and generating speech

## Troubleshooting

### Backend Issues
- **Timeout errors**: Vercel has a 10-second timeout for hobby plans
- **Memory issues**: F5-TTS requires significant memory
- **Cold starts**: Serverless functions may have slow cold starts

### UI Issues
- **CORS errors**: Make sure your backend includes CORS headers
- **API not found**: Check the `NEXT_PUBLIC_API_URL` environment variable

## Production Recommendations

For a production deployment, consider:

1. **Use a dedicated server** or **GPU-enabled cloud instance**
2. **Implement caching** for generated audio
3. **Add authentication** and **rate limiting**
4. **Use a CDN** for static assets
5. **Monitor performance** and **set up logging**

## Support

If you encounter issues:
1. Check the Vercel deployment logs
2. Verify environment variables are set correctly
3. Test the API endpoints directly using curl or Postman
4. Consider using a more powerful hosting solution for the backend
