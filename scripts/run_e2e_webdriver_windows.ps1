param(
  [string]$ProjectId = 'chegaja-ac88d',
  [int]$StartupTimeoutSec = 240,
  [switch]$SkipFunctions,
  [switch]$KeepProcesses
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

function Test-PortListening {
  param([int]$Port)
  $match = netstat -ano | Select-String ":$Port\s+.*LISTENING"
  return [bool]$match
}

function Wait-Port {
  param(
    [int]$Port,
    [int]$TimeoutSec,
    [string]$Name
  )

  $deadline = (Get-Date).AddSeconds($TimeoutSec)
  while ((Get-Date) -lt $deadline) {
    if (Test-PortListening -Port $Port) {
      Write-Host "[E2E] $Name is listening on port $Port."
      return
    }
    Start-Sleep -Seconds 2
  }

  throw "[E2E] Timeout waiting for $Name on port $Port."
}

function Require-Command {
  param([string]$Name)

  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "[E2E] Required command not found: $Name"
  }
}

function Resolve-ChromeDriverBinary {
  $chromedriverCmd = Get-Command chromedriver -ErrorAction SilentlyContinue
  if (-not $chromedriverCmd) {
    throw '[E2E] Required command not found: chromedriver'
  }

  $baseDir = Split-Path $chromedriverCmd.Source -Parent
  $candidates = @(
    (Join-Path $baseDir 'node_modules\chromedriver\lib\chromedriver\chromedriver.exe'),
    (Join-Path $baseDir 'node_modules\chromedriver\lib\chromedriver\chromedriver')
  )

  foreach ($candidate in $candidates) {
    if (Test-Path $candidate) {
      return $candidate
    }
  }

  throw '[E2E] Could not locate the ChromeDriver binary next to the installed wrapper command.'
}

function Invoke-Checked {
  param(
    [string]$Command,
    [string]$Label
  )

  Write-Host "[E2E] Running $Label..."
  & cmd.exe /c $Command
  if ($LASTEXITCODE -ne 0) {
    throw "[E2E] $Label failed with exit code $LASTEXITCODE."
  }
}

$logDir = Join-Path $repoRoot 'artifacts\e2e'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$firebaseOut = Join-Path $logDir "firebase-emulators-$timestamp.out.log"
$firebaseErr = Join-Path $logDir "firebase-emulators-$timestamp.err.log"
$chromedriverOut = Join-Path $logDir "chromedriver-$timestamp.out.log"
$chromedriverErr = Join-Path $logDir "chromedriver-$timestamp.err.log"

$startedEmulators = $false
$startedChromedriver = $false
$emulatorProc = $null
$chromedriverProc = $null

try {
  Require-Command -Name 'flutter'
  Require-Command -Name 'firebase.cmd'
  Require-Command -Name 'chromedriver'
  Require-Command -Name 'npm'

  $chromeDriverBinary = Resolve-ChromeDriverBinary

  $hasFirestore = Test-PortListening -Port 8080
  $hasAuth = Test-PortListening -Port 9099
  if ($hasFirestore -xor $hasAuth) {
    throw '[E2E] Partial emulator state detected (only one of 8080/9099 is open). Stop stale emulator processes and retry.'
  }

  if (-not $hasFirestore -and -not $hasAuth) {
    Write-Host '[E2E] Starting Firebase emulators (auth,firestore)...'
    $emulatorProc = Start-Process `
      -FilePath 'cmd.exe' `
      -ArgumentList "/c firebase.cmd emulators:start --only auth,firestore --project $ProjectId" `
      -WorkingDirectory $repoRoot `
      -PassThru `
      -RedirectStandardOutput $firebaseOut `
      -RedirectStandardError $firebaseErr
    $startedEmulators = $true
  } else {
    Write-Host '[E2E] Reusing existing Firebase emulators (ports 8080 and 9099).'
  }

  Wait-Port -Port 8080 -TimeoutSec $StartupTimeoutSec -Name 'Firestore emulator'
  Wait-Port -Port 9099 -TimeoutSec $StartupTimeoutSec -Name 'Auth emulator'

  if (-not (Test-PortListening -Port 4444)) {
    Write-Host '[E2E] Starting ChromeDriver on port 4444...'
    $chromedriverProc = Start-Process `
      -FilePath $chromeDriverBinary `
      -ArgumentList '--port=4444 --allowed-origins=*' `
      -WorkingDirectory $repoRoot `
      -PassThru `
      -RedirectStandardOutput $chromedriverOut `
      -RedirectStandardError $chromedriverErr
    $startedChromedriver = $true
  } else {
    Write-Host '[E2E] Reusing existing ChromeDriver on port 4444.'
  }

  Wait-Port -Port 4444 -TimeoutSec 30 -Name 'ChromeDriver'

  if (-not $SkipFunctions) {
    Invoke-Checked `
      -Command 'npm --prefix functions test -- --timeout 120000' `
      -Label 'Functions tests'
  } else {
    Write-Host '[E2E] Skipping functions tests by request.'
  }

  Invoke-Checked `
    -Command 'flutter drive --no-pub --profile --driver=test_driver/integration_test.dart --target=integration_test/pedido_flow_emulator_test.dart -d web-server --browser-name=chrome --web-hostname=127.0.0.1 --web-port=7357 --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true' `
    -Label 'Web E2E via WebDriver'

  Write-Host '[E2E] All checks passed.'
}
finally {
  if ($KeepProcesses) {
    Write-Host '[E2E] Keeping background processes as requested.'
  } else {
    if ($startedChromedriver -and $chromedriverProc -ne $null) {
      & taskkill /PID $chromedriverProc.Id /T /F | Out-Null
    }
    if ($startedEmulators -and $emulatorProc -ne $null) {
      & taskkill /PID $emulatorProc.Id /T /F | Out-Null
    }
  }
}
