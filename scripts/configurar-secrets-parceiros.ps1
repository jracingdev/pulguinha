# Envia secrets do arquivo supabase/secrets.local.env para o projeto Supabase.
# Uso:
#   1. copy supabase\secrets.local.env.example supabase\secrets.local.env
#   2. Preencha os valores
#   3. .\scripts\configurar-secrets-parceiros.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$envFile = Join-Path $root "supabase\secrets.local.env"

if (-not (Test-Path $envFile)) {
    Write-Host "Arquivo nao encontrado: $envFile" -ForegroundColor Red
    Write-Host "Copie secrets.local.env.example para secrets.local.env e preencha."
    exit 1
}

$supabase = Join-Path $root "scripts\supabase.ps1"
if (-not (Test-Path $supabase)) {
    Write-Host "scripts\supabase.ps1 nao encontrado." -ForegroundColor Red
    exit 1
}

Write-Host "Lendo $envFile ..."
Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -eq "" -or $line.StartsWith("#")) { return }
    if ($line -match "^([^=]+)=(.*)$") {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim().Trim('"')
        if ($value -eq "") {
            Write-Host "  [pular] $name (vazio)" -ForegroundColor DarkYellow
            return
        }
        Write-Host "  [set] $name"
        & $supabase secrets set "${name}=${value}"
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
}

Write-Host "Secrets enviados. Deploy da funcao:" -ForegroundColor Green
Write-Host "  cd $root"
Write-Host "  .\scripts\supabase.ps1 functions deploy validate-partner-access"
