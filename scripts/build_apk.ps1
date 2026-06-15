# Build APK release com credenciais Supabase via variáveis de ambiente (não commitar chaves).
# Uso: $env:SUPABASE_URL="https://....supabase.co"; $env:SUPABASE_ANON_KEY="eyJ..."; .\scripts\build_apk.ps1

$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

$url = $env:SUPABASE_URL
$key = $env:SUPABASE_ANON_KEY

if (-not $url -or -not $key) {
  Write-Warning "SUPABASE_URL ou SUPABASE_ANON_KEY não definidos — APK será buildado em modo offline."
  Write-Warning "Admin poderá configurar em Configurações → Conexão Supabase após instalar."
  flutter build apk --release
} else {
  Write-Host "Build com Supabase embutido via dart-define (URL apenas no binário, chave anon)."
  flutter build apk --release `
    --dart-define=SUPABASE_URL=$url `
    --dart-define=SUPABASE_ANON_KEY=$key
}

Write-Host "APK: build\app\outputs\flutter-apk\app-release.apk"
