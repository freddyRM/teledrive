# Descarga libtdjson.so desde la Release del repositorio (el binario no se guarda en Git).
# Uso: desde la carpeta raiz del proyecto:  powershell -ExecutionPolicy Bypass -File tools\fetch_tdlib.ps1
#
# La URL se puede cambiar con TDLIB_RELEASE_URL en app\.env. Si no esta, se usa la de abajo.
# El archivo solo se instala si su SHA-256 coincide con el esperado.

$defaultUrl = 'https://github.com/freddyRM/teledrive/releases/download/tdlib-1.8.69/libtdjson.so'
$expectedSha = '78834AD66C115D9749A49295FE6CB101E0D971ADB820DA2BEAB53A0F646FFEEE'

$envFile = Join-Path $PSScriptRoot '..\app\.env'
$url = $null
if (Test-Path $envFile) {
    $line = Get-Content $envFile | Where-Object { $_ -match '^TDLIB_RELEASE_URL=' } | Select-Object -First 1
    if ($line) { $url = ($line -split '=', 2)[1].Trim() }
}
if (-not $url) { $url = $defaultUrl }

$dest = Join-Path $PSScriptRoot '..\app\android\app\src\main\jniLibs\arm64-v8a\libtdjson.so'
$tmp = "$dest.download"
New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null

Write-Host "Descargando libtdjson.so desde: $url"
$ok = $false
for ($attempt = 1; $attempt -le 3 -and -not $ok; $attempt++) {
    try {
        Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing
        $hash = (Get-FileHash $tmp -Algorithm SHA256).Hash
        if ($hash -eq $expectedSha) {
            $ok = $true
        } else {
            Write-Host "Intento ${attempt}: el SHA-256 no coincide ($hash). Reintentando..."
        }
    } catch {
        Write-Host "Intento $attempt fallo: $($_.Exception.Message). Reintentando..."
    }
}

if (-not $ok) {
    if (Test-Path $tmp) { Remove-Item $tmp -Force }
    Write-Error "No se pudo descargar libtdjson.so verificado. Revisa la URL o tu conexion."
    exit 1
}

Move-Item -Force $tmp $dest
Write-Host "Listo: $dest"
Write-Host "SHA-256 verificado: $expectedSha (TDLib 1.8.69)"
