# Build APK release — Supabase embutido automaticamente (zero config no celular).
# Uso opcional com override: $env:SUPABASE_URL="..."; $env:SUPABASE_ANON_KEY="..."; .\scripts\build_apk.ps1

$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

$url = $env:SUPABASE_URL
$key = $env:SUPABASE_ANON_KEY

if ($url -and $key) {
  Write-Host "Build com override Supabase via dart-define."
  flutter build apk --release `
    --dart-define=SUPABASE_URL=$url `
    --dart-define=SUPABASE_ANON_KEY=$key
} else {
  Write-Host "Build com credenciais embutidas em lib/config/supabase_config.dart (padrão Pulguinha)."
  flutter build apk --release
}

Write-Host "APK: build\app\outputs\flutter-apk\app-release.apk"
