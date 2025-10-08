@echo off
echo 🚀 F5-TTS Vercel Deployment Script
echo ==================================

echo 📦 Deploying Backend API...
echo 1. Make sure you're in the root directory of your F5-TTS project
echo 2. Run: vercel --prod
echo 3. Follow the prompts to configure your project
echo 4. Note down the deployment URL
echo.

echo 🎨 Deploying UI...
echo 1. Navigate to the f5-tts-ui directory: cd f5-tts-ui
echo 2. Run: vercel --prod
echo 3. Set environment variable NEXT_PUBLIC_API_URL to your backend URL
echo 4. Redeploy if needed
echo.

echo ⚠️  Important Notes:
echo - F5-TTS is resource-intensive and may not work well on Vercel's free tier
echo - Consider using Google Cloud Run, AWS Lambda, or Railway for the backend
echo - The current API implementation is simplified for Vercel compatibility
echo.

echo 🔗 Useful Links:
echo - Vercel Dashboard: https://vercel.com/dashboard
echo - Vercel CLI Docs: https://vercel.com/docs/cli
echo - F5-TTS Repository: https://github.com/AnasPirzada/Voice-Clone
echo.

pause
echo Deploying backend...
vercel --prod

echo.
echo ✅ Backend deployment complete!
echo 📝 Note down the deployment URL and use it for NEXT_PUBLIC_API_URL in the UI deployment
pause
