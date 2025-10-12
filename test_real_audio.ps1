# Test Real F5-TTS Audio Generation
# This script will generate and save actual audio files

param(
    [string]$AudioFile = "C:\Users\Sunny\Downloads\harvard.wav",
    [string]$RefText = "The subtitle or transcription of reference audio.",
    [string]$GenText = "hi i am anas how are you",
    [string]$OutputFile = "generated_audio.wav"
)

Write-Host "🎵 Testing Real F5-TTS Audio Generation..." -ForegroundColor Green
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

# Check if server is running
Write-Host "🔍 Checking server status..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-WebRequest -Uri "http://localhost:8000/health" -Method GET -TimeoutSec 5
    Write-Host "✅ Server is running" -ForegroundColor Green
} catch {
    Write-Host "❌ Server is not running or not ready" -ForegroundColor Red
    Write-Host "Please start the full F5-TTS server: python src/f5_tts/server.py" -ForegroundColor Yellow
    exit 1
}

try {
    Write-Host "🚀 Generating audio..." -ForegroundColor Yellow
    
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
    
    # Check if response is audio or JSON
    $contentType = $response.Headers["Content-Type"]
    
    if ($contentType -like "*audio*" -or $contentType -like "*wav*") {
        # Save the audio file
        $response.Content | Set-Content -Path $OutputFile -Encoding Byte
        $fileSize = (Get-Item $OutputFile).Length
        
        Write-Host "✅ Audio generated successfully!" -ForegroundColor Green
        Write-Host "📁 Saved as: $OutputFile" -ForegroundColor Cyan
        Write-Host "📊 File size: $([math]::Round($fileSize/1KB, 2)) KB" -ForegroundColor Cyan
        Write-Host "🎵 You can now play the audio file!" -ForegroundColor Magenta
        
        # Try to open the file
        if (Test-Path $OutputFile) {
            Write-Host "🔊 Opening audio file..." -ForegroundColor Yellow
            Start-Process $OutputFile
        }
        
    } else {
        # Response is JSON (testing server)
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
