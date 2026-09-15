# Wrapper Supabase CLI no Windows (evita bloqueio do supabase.ps1 do PATH).
$ErrorActionPreference = "Stop"
$npmCmd = Join-Path $env:APPDATA "npm\supabase.cmd"
$npxCmd = Join-Path $env:APPDATA "npm\npx.cmd"

if (Test-Path $npmCmd) {
    & $npmCmd @args
    exit $LASTEXITCODE
}

$fromPath = Get-Command supabase -ErrorAction SilentlyContinue
if ($fromPath) {
    & $fromPath.Source @args
    exit $LASTEXITCODE
}

if (Test-Path $npxCmd) {
    & $npxCmd --yes supabase @args
    exit $LASTEXITCODE
}

$npxFromPath = Get-Command npx.cmd -ErrorAction SilentlyContinue
if (-not $npxFromPath) {
    $npxFromPath = Get-Command npx -ErrorAction SilentlyContinue
}
if ($npxFromPath) {
    & $npxFromPath.Source --yes supabase @args
    exit $LASTEXITCODE
}

$npxNode = Join-Path $env:ProgramFiles "nodejs\npx.cmd"
if (Test-Path $npxNode) {
    & $npxNode --yes supabase @args
    exit $LASTEXITCODE
}

Write-Host "Supabase CLI nao encontrado. Instale com: npm i -g supabase" -ForegroundColor Red
Write-Host "Depois faca login: npx supabase login"
exit 1
