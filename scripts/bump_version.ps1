# Incrementa versão no pubspec.yaml
# Uso: .\scripts\bump_version.ps1 patch|minor|major|build

param(
  [Parameter(Position = 0)]
  [ValidateSet('patch', 'minor', 'major', 'build')]
  [string]$Part = 'build'
)

$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

$pubspec = Get-Content 'pubspec.yaml' -Raw
if ($pubspec -notmatch 'version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)') {
  Write-Error 'Não foi possível ler version: X.Y.Z+N do pubspec.yaml'
}

$major = [int]$Matches[1]
$minor = [int]$Matches[2]
$patch = [int]$Matches[3]
$build = [int]$Matches[4]

switch ($Part) {
  'major' { $major++; $minor = 0; $patch = 0; $build++ }
  'minor' { $minor++; $patch = 0; $build++ }
  'patch' { $patch++; $build++ }
  'build' { $build++ }
}

$newVersion = "$major.$minor.$patch+$build"
$pubspec = $pubspec -replace 'version:\s*\d+\.\d+\.\d+\+\d+', "version: $newVersion"
Set-Content 'pubspec.yaml' $pubspec -NoNewline

Write-Host "Versão atualizada: $newVersion"
Write-Host "Atualize CHANGELOG.md e rode: .\scripts\build_apk.ps1"
