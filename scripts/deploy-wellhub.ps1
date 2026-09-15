# Deploy das Edge Functions Wellhub + validate-partner-access
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

$supabase = Join-Path $root "scripts\supabase.ps1"

Write-Host "Deploy validate-partner-access ..."
& $supabase functions deploy validate-partner-access
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Deploy wellhub-webhook (verify_jwt=false) ..."
& $supabase functions deploy wellhub-webhook --no-verify-jwt
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Deploy wellhub-sync ..."
& $supabase functions deploy wellhub-sync
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "OK." -ForegroundColor Green
Write-Host "Webhook (enviar à Wellhub):"
Write-Host "  https://tvztfgjmhxmwjzsnugic.supabase.co/functions/v1/wellhub-webhook"
Write-Host "Gym ID produção (Funcional do Pulguinha): 824346"
Write-Host "Gym ID sandbox: 683"
Write-Host "IDs de teste da coleção: 1000000000001  1000000000003"
