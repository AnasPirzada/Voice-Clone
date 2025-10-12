# Time F5-TTS Audio Generation
# This script measures how long it takes to generate audio

param(
    [string]$AudioFile = "C:\Users\Sunny\Downloads\harvard.wav",
    [string]$RefText = "The subtitle or transcription of reference audio.",
    [string]$GenText = "hi i am anas how are you"
)

Write-Host "⏱️  Timing F5-TTS Audio Generation..." -ForegroundColor Green
Write-Host "📁 Reference audio: $AudioFile" -ForegroundColor Cyan
Write-Host "📝 Reference text: $RefText" -ForegroundColor Cyan
Write-Host "💬 Generation text: $GenText" -ForegroundColor Cyan
Write-Host ""

# Check if file exists
if (-not (Test-Path $AudioFile)) {
    Write-Host "❌ Audio file not found: $AudioFile" -ForegroundColor Red
    exit 1
}

# Check if server is running
Write-Host "🔍 Checking server status..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-WebRequest -Uri "http://localhost:8000/health" -Method GET -TimeoutSec 5
    Write-Host "✅ Server is running" -ForegroundColor Green
} catch {
    Write-Host "❌ Server is not running or not ready" -ForegroundColor Red
    Write-Host "Please start the server: python local_server.py" -ForegroundColor Yellow
    exit 1
}

try {
    Write-Host "🚀 Starting audio generation..." -ForegroundColor Yellow
    
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
    $response = Invoke-WebRequest -Uri "http://localhost:8000/tts" -Method Post -Body $bodyLines -ContentType "multipart/form-data; boundary=$boundary"
    
    # Stop timing
    $stopwatch.Stop()
    $elapsedTime = $stopwatch.Elapsed
    
    # Display timing results
    Write-Host ""
    Write-Host "⏱️  TIMING RESULTS:" -ForegroundColor Magenta
    Write-Host "🕐 Total time: $($elapsedTime.TotalSeconds.ToString('F2')) seconds" -ForegroundColor Green
    Write-Host "🕐 Total time: $($elapsedTime.TotalMilliseconds.ToString('F0')) milliseconds" -ForegroundColor Green
    Write-Host "🕐 Formatted: $($elapsedTime.ToString('hh\:mm\:ss\.fff'))" -ForegroundColor Green
    
    # Check response type
    $contentType = $response.Headers["Content-Type"]
    $contentLength = $response.Headers["Content-Length"]
    
    Write-Host ""
    Write-Host "📊 RESPONSE INFO:" -ForegroundColor Magenta
    Write-Host "📄 Content-Type: $contentType" -ForegroundColor Cyan
    Write-Host "📏 Content-Length: $contentLength bytes" -ForegroundColor Cyan
    Write-Host "📈 Status Code: $($response.StatusCode)" -ForegroundColor Cyan
    
    if ($contentType -like "*audio*" -or $contentType -like "*wav*") {
        # Save the audio file
        $outputFile = "generated_audio_$(Get-Date -Format 'yyyyMMdd_HHmmss').wav"
        $response.Content | Set-Content -Path $outputFile -Encoding Byte
        $fileSize = (Get-Item $outputFile).Length
        
        Write-Host ""
        Write-Host "✅ Audio generated successfully!" -ForegroundColor Green
        Write-Host "📁 Saved as: $outputFile" -ForegroundColor Cyan
        Write-Host "📊 File size: $([math]::Round($fileSize/1KB, 2)) KB" -ForegroundColor Cyan
        Write-Host "🎵 You can now play the audio file!" -ForegroundColor Magenta
        
        # Try to open the file
        if (Test-Path $outputFile) {
            Write-Host "🔊 Opening audio file..." -ForegroundColor Yellow
            Start-Process $outputFile
        }
        
    } else {
        # Response is JSON (testing server)
        Write-Host ""
        Write-Host "⚠️  Received JSON response (testing server)" -ForegroundColor Yellow
        Write-Host "📋 Response:" -ForegroundColor Cyan
        $response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 3 | Write-Host -ForegroundColor White
        Write-Host ""
        Write-Host "💡 To get real audio, start the full F5-TTS server:" -ForegroundColor Yellow
        Write-Host "   python src/f5_tts/server.py" -ForegroundColor White
    }
    
} catch {
    Write-Host "❌ Error occurred:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response body: $responseBody" -ForegroundColor Red
    }
}

