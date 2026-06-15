# Build APK release — Supabase embutido automaticamente (zero config no celular).
# Uso opcional com override: $env:SUPABASE_URL="..."; $env:SUPABASE_ANON_KEY="..."; .\scripts\build_apk.ps1

$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

$pubspec = Get-Content 'pubspec.yaml' -Raw
if ($pubspec -match 'version:\s*(\d+\.\d+\.\d+)\+(\d+)') {
  $versionName = $Matches[1]
  $buildNumber = $Matches[2]
  Write-Host "Build Pulguinha v$versionName (build $buildNumber)"
} else {
  Write-Error 'version não encontrada em pubspec.yaml'
}

$url = $env:SUPABASE_URL
$key = $env:SUPABASE_ANON_KEY

if ($url -and $key) {
  Write-Host "Build com override Supabase via dart-define."
  flutter build apk --release `
    --build-name=$versionName `
    --build-number=$buildNumber `
    --dart-define=SUPABASE_URL=$url `
    --dart-define=SUPABASE_ANON_KEY=$key
} else {
  Write-Host "Build com credenciais embutidas em lib/config/supabase_config.dart (padrão Pulguinha)."
  flutter build apk --release `
    --build-name=$versionName `
    --build-number=$buildNumber
}

$src = 'build\app\outputs\flutter-apk\app-release.apk'
$dest = "build\app\outputs\flutter-apk\pulguinha-$versionName-build$buildNumber.apk"
Copy-Item $src $dest -Force

Write-Host "APK: $src"
Write-Host "Cópia versionada: $dest"
