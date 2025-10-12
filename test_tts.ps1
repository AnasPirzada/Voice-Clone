# F5-TTS API Test Script
# Usage: .\test_tts.ps1 "C:\path\to\audio.wav" "reference text" "text to generate"

param(
    [Parameter(Mandatory=$true)]
    [string]$AudioFile,
    
    [Parameter(Mandatory=$false)]
    [string]$RefText = "The subtitle or transcription of reference audio.",
    
    [Parameter(Mandatory=$true)]
    [string]$GenText,
    
    [Parameter(Mandatory=$false)]
    [string]$ApiUrl = "http://localhost:8000/tts",
    
    [Parameter(Mandatory=$false)]
    [float]$Speed = 1.0,
    
    [Parameter(Mandatory=$false)]
    [float]$CfgStrength = 2.0
)

# Check if file exists
if (-not (Test-Path $AudioFile)) {
    Write-Error "Audio file not found: $AudioFile"
    exit 1
}

Write-Host "🎤 Testing F5-TTS API..." -ForegroundColor Green
Write-Host "📁 Audio file: $AudioFile" -ForegroundColor Cyan
Write-Host "📝 Reference text: $RefText" -ForegroundColor Cyan
Write-Host "💬 Generation text: $GenText" -ForegroundColor Cyan
Write-Host "⚡ Speed: $Speed" -ForegroundColor Cyan
Write-Host "🔧 CFG Strength: $CfgStrength" -ForegroundColor Cyan
Write-Host ""

try {
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
    
    # Add query parameters
    $uri = "$ApiUrl" + "?speed=$Speed" + "&" + "cfg_strength=$CfgStrength"
    
    # Make the request
    Write-Host "🚀 Sending request to: $uri" -ForegroundColor Yellow
    $response = Invoke-RestMethod -Uri $uri -Method Post -Body $bodyLines -ContentType "multipart/form-data; boundary=$boundary"
    
    Write-Host "✅ Success!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Response:" -ForegroundColor Magenta
    $response | ConvertTo-Json -Depth 3 | Write-Host -ForegroundColor White
    
} catch {
    Write-Host "❌ Error occurred:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response body: $responseBody" -ForegroundColor Red
    }
}
