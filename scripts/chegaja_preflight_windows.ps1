# ChegaJa preflight local - Windows PowerShell
# Executar na raiz do projeto chegaja_v2:
# powershell -NoProfile -ExecutionPolicy Bypass -File scripts\chegaja_preflight_windows.ps1

$ErrorActionPreference = "Stop"

function Invoke-Native {
  param(
    [Parameter(Mandatory = $true)]
    [string] $Command,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $Arguments
  )

  & $Command @Arguments

  if ($LASTEXITCODE -ne 0) {
    throw "Command failed with exit code ${LASTEXITCODE}: $Command $($Arguments -join ' ')"
  }
}

Write-Host "== ChegaJa preflight =="

Write-Host ""
Write-Host "1) Git status"
Invoke-Native git status --short

Write-Host ""
Write-Host "2) Flutter version"
Invoke-Native flutter --version

Write-Host ""
Write-Host "3) Flutter test"
Invoke-Native flutter test --no-pub

Write-Host ""
Write-Host "4) Scripts test"
if (Test-Path "package.json") {
  Invoke-Native npm.cmd run test:scripts
} else {
  Write-Host "package.json nao encontrado na raiz; saltando test:scripts."
}

Write-Host ""
Write-Host "5) Firebase emulator tests"
Invoke-Native npx.cmd firebase emulators:exec --only "firestore,storage,functions" "cd functions && npm.cmd test"

Write-Host ""
Write-Host "== Preflight concluido =="
