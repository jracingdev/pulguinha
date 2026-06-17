# Deploy da Edge Function validate-partner-access
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

Write-Host "Deploy validate-partner-access ..."
& "$root\scripts\supabase.ps1" functions deploy validate-partner-access
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "OK. Teste (substitua ANON_KEY):" -ForegroundColor Green
Write-Host 'curl -X POST "https://tvztfgjmhxmwjzsnugic.supabase.co/functions/v1/validate-partner-access" -H "Authorization: Bearer ANON_KEY" -H "Content-Type: application/json" -d "{\"provider\":\"wellhub\",\"identifier\":\"1000000000001\"}"'
