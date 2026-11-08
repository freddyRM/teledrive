# Descarga libtdjson.so desde la Release del repositorio (el binario no se guarda en Git).
# Uso: desde la carpeta raiz del proyecto:  powershell -ExecutionPolicy Bypass -File tools\fetch_tdlib.ps1

$url = 'https://github.com/freddyRM/teledrive/releases/download/tdlib-1.8.69/libtdjson.so'
$dest = Join-Path $PSScriptRoot '..\app\android\app\src\main\jniLibs\arm64-v8a\libtdjson.so'
New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null

Write-Host "Descargando libtdjson.so desde la Release..."
Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing

$hash = (Get-FileHash $dest -Algorithm SHA256).Hash
Write-Host "Listo: $dest"
Write-Host "SHA-256: $hash"
