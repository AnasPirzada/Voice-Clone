# Generate Real F5-TTS Audio
# This script waits for the full F5-TTS server and generates actual audio files

param(
    [string]$AudioFile = "C:\Users\Sunny\Downloads\harvard.wav",
    [string]$RefText = "The subtitle or transcription of reference audio.",
    [string]$GenText = "hi i am anas how are you",
    [string]$OutputFile = "generated_audio_$(Get-Date -Format 'yyyyMMdd_HHmmss').wav"
)

Write-Host "🎵 F5-TTS Real Audio Generator" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green
Write-Host "📁 Reference audio: $AudioFile" -ForegroundColor Cyan
Write-Host "📝 Reference text: $RefText" -ForegroundColor Cyan
Write-Host "💬 Generation text: $GenText" -ForegroundColor Cyan
Write-Host "💾 Output file: $OutputFile" -ForegroundColor Cyan
Write-Host ""

# Check if file exists
if (-not (Test-Path $AudioFile)) {
    Write-Host "❌ Audio file not found: $AudioFile" -ForegroundColor Red
    exit 1
}

# Wait for server to be ready
Write-Host "⏳ Waiting for F5-TTS server to be ready..." -ForegroundColor Yellow
Write-Host "   This may take 5-15 minutes for first-time model loading..." -ForegroundColor Yellow

$maxAttempts = 60  # 10 minutes max wait
$attempt = 0

do {
    $attempt++
    Write-Host "🔍 Attempt $attempt/$maxAttempts - Checking server..." -ForegroundColor Yellow
    
    try {
        $healthResponse = Invoke-WebRequest -Uri "http://localhost:8000/health" -Method GET -TimeoutSec 10
        Write-Host "✅ Server is ready!" -ForegroundColor Green
        break
    } catch {
        if ($attempt -ge $maxAttempts) {
            Write-Host "❌ Server failed to start after $maxAttempts attempts" -ForegroundColor Red
            Write-Host "💡 Try starting manually: python src/f5_tts/server.py" -ForegroundColor Yellow
            exit 1
        }
        Write-Host "⏳ Server not ready yet, waiting 10 seconds..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
    }
} while ($attempt -lt $maxAttempts)

Write-Host ""
Write-Host "🚀 Starting audio generation..." -ForegroundColor Green

try {
    # Start timing
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Create multipart form data
    $boundary = [System.Guid]::NewGuid().ToString()
    $LF = "`r`n"
    
    $bodyLines = @(
        "--$boundary",
        "Content-Disposition: form-data; name=`"ref_audio`"; filename=`"$(Split-Path $AudioFile -Leaf)`"",
        "Content-Type: audio/wav",
        "",
        [System.IO.File]::ReadAllBytes($AudioFile),
        "--$boundary",
        "Content-Disposition: form-data; name=`"ref_text`"",
        "",
        $RefText,
        "--$boundary",
        "Content-Disposition: form-data; name=`"gen_text`"",
        "",
        $GenText,
        "--$boundary--",
        ""
    ) -join $LF
    
    # Make the request
    Write-Host "📤 Sending request to F5-TTS server..." -ForegroundColor Yellow
    $response = Invoke-WebRequest -Uri "http://localhost:8000/tts" -Method Post -Body $bodyLines -ContentType "multipart/form-data; boundary=$boundary"
    
    # Stop timing
    $stopwatch.Stop()
    $elapsedTime = $stopwatch.Elapsed
    
    # Check response type
    $contentType = $response.Headers["Content-Type"]
    $contentLength = $response.Headers["Content-Length"]
    
    Write-Host ""
    Write-Host "⏱️ GENERATION COMPLETE!" -ForegroundColor Green
    Write-Host "🕐 Time taken: $($elapsedTime.TotalSeconds.ToString('F2')) seconds" -ForegroundColor Cyan
    Write-Host "📄 Content-Type: $contentType" -ForegroundColor Cyan
    Write-Host "📏 Content-Length: $contentLength bytes" -ForegroundColor Cyan
    
    if ($contentType -like "*audio*" -or $contentType -like "*wav*") {
        # Save the audio file
        $response.Content | Set-Content -Path $OutputFile -Encoding Byte
        $fileSize = (Get-Item $OutputFile).Length
        
        Write-Host ""
        Write-Host "🎵 AUDIO GENERATED SUCCESSFULLY!" -ForegroundColor Green
        Write-Host "📁 Saved as: $OutputFile" -ForegroundColor Cyan
        Write-Host "📊 File size: $([math]::Round($fileSize/1KB, 2)) KB" -ForegroundColor Cyan
        Write-Host "🎧 You can now play the audio file!" -ForegroundColor Magenta
        
        # Try to open the file
        if (Test-Path $OutputFile) {
            Write-Host "🔊 Opening audio file..." -ForegroundColor Yellow
            Start-Process $OutputFile
        }
        
        Write-Host ""
        Write-Host "🎉 SUCCESS! Real audio file generated!" -ForegroundColor Green
        Write-Host "🎵 The audio should sound like your reference voice saying: '$GenText'" -ForegroundColor Magenta
        
    } else {
        # Response is JSON (testing server)
        Write-Host ""
        Write-Host "⚠️ Received JSON response (testing server)" -ForegroundColor Yellow
        Write-Host "📋 Response:" -ForegroundColor Cyan
        $response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 3 | Write-Host -ForegroundColor White
        Write-Host ""
        Write-Host "💡 The full F5-TTS server may not be fully loaded yet." -ForegroundColor Yellow
        Write-Host "   Try running this script again in a few minutes." -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "❌ Error occurred during generation:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response body: $responseBody" -ForegroundColor Red
    }
}

