# Deploy das Edge Functions TotalPass (Booking + check-in).
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

$supabase = Join-Path $root "scripts\supabase.ps1"

Write-Host "Deploy validate-partner-access ..."
& $supabase functions deploy validate-partner-access
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Deploy totalpass-webhook (verify_jwt=false) ..."
& $supabase functions deploy totalpass-webhook --no-verify-jwt
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Deploy totalpass-sync ..."
& $supabase functions deploy totalpass-sync
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "OK." -ForegroundColor Green
Write-Host "Webhook TotalPass:"
Write-Host "  https://tvztfgjmhxmwjzsnugic.supabase.co/functions/v1/totalpass-webhook"
