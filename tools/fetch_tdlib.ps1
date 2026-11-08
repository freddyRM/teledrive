# Descarga libtdjson.so desde la Release del repositorio (el binario no se guarda en Git).
# Uso: desde la carpeta raiz del proyecto:  powershell -ExecutionPolicy Bypass -File tools\fetch_tdlib.ps1
#
# La URL se puede cambiar con TDLIB_RELEASE_URL en app\.env. Si no esta, se usa la de abajo.

$defaultUrl = 'https://github.com/freddyRM/teledrive/releases/download/tdlib-1.8.69/libtdjson.so'

$envFile = Join-Path $PSScriptRoot '..\app\.env'
$url = $null
if (Test-Path $envFile) {
    $line = Get-Content $envFile | Where-Object { $_ -match '^TDLIB_RELEASE_URL=' } | Select-Object -First 1
    if ($line) { $url = ($line -split '=', 2)[1].Trim() }
}
if (-not $url) { $url = $defaultUrl }

$dest = Join-Path $PSScriptRoot '..\app\android\app\src\main\jniLibs\arm64-v8a\libtdjson.so'
New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null

Write-Host "Descargando libtdjson.so desde: $url"
Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing

$hash = (Get-FileHash $dest -Algorithm SHA256).Hash
Write-Host "Listo: $dest"
Write-Host "SHA-256: $hash"
Write-Host "Debe ser: 78834AD66C115D9749A49295FE6CB101E0D971ADB820DA2BEAB53A0F646FFEEE (TDLib 1.8.69)"
