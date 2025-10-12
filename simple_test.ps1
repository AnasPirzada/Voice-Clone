# Simple F5-TTS Test Script
param(
    [string]$AudioFile = "C:\Users\Sunny\Downloads\harvard.wav",
    [string]$RefText = "The subtitle or transcription of reference audio.",
    [string]$GenText = "hi i am anas how are you"
)

Write-Host "Testing F5-TTS API..." -ForegroundColor Green
Write-Host "Audio file: $AudioFile" -ForegroundColor Cyan
Write-Host "Reference text: $RefText" -ForegroundColor Cyan
Write-Host "Generation text: $GenText" -ForegroundColor Cyan

# Check if file exists
if (-not (Test-Path $AudioFile)) {
    Write-Host "Audio file not found: $AudioFile" -ForegroundColor Red
    exit 1
}

try {
    # Create multipart form data
    $boundary = [System.Guid]::NewGuid().ToString()
    $LF = "`r`n"
    
    $bodyLines = @(
        "--$boundary",
        "Content-Disposition: form-data; name=`"ref_audio`"; filename=`"harvard.wav`"",
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
    $response = Invoke-RestMethod -Uri "http://localhost:8000/tts" -Method Post -Body $bodyLines -ContentType "multipart/form-data; boundary=$boundary"
    
    Write-Host "Success!" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 3
    
} catch {
    Write-Host "Error occurred:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}
