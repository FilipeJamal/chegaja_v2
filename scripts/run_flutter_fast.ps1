param(
    [string]$Device = 'chrome',
    [string]$Target = 'lib/main_dev.dart',
    [string]$WebHost = '127.0.0.1',
    [int]$WebPort = 7357,
    [switch]$FullBoot,
    [switch]$Precache,
    [switch]$TraceStartup,
    [switch]$ForcePubGet,
    [switch]$PrintOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $repoRoot

function Test-PubGetNeeded {
    $packageConfig = Join-Path $repoRoot '.dart_tool\package_config.json'
    if (-not (Test-Path $packageConfig)) {
        return $true
    }

    $packageConfigTime = (Get-Item $packageConfig).LastWriteTimeUtc
    foreach ($input in @('pubspec.yaml', 'pubspec.lock')) {
        $fullPath = Join-Path $repoRoot $input
        if ((Test-Path $fullPath) -and ((Get-Item $fullPath).LastWriteTimeUtc -gt $packageConfigTime)) {
            return $true
        }
    }

    return $false
}

function Invoke-Step {
    param(
        [string]$Label,
        [string[]]$Arguments
    )

    Write-Host "==> $Label" -ForegroundColor Cyan
    Write-Host ("flutter " + ($Arguments -join ' ')) -ForegroundColor DarkGray

    if ($PrintOnly) {
        return
    }

    & flutter @Arguments
}

$webDevices = @('chrome', 'edge', 'web-server')
$isWebDevice = $webDevices -contains $Device.ToLowerInvariant()

if ($Precache -and $isWebDevice) {
    Invoke-Step -Label 'Precache web toolchain' -Arguments @('precache', '--web')
}

$shouldRunPubGet = $ForcePubGet.IsPresent -or (Test-PubGetNeeded)
if ($shouldRunPubGet) {
    Invoke-Step -Label 'Resolve Dart and Flutter packages' -Arguments @('pub', 'get')
}

$runArgs = New-Object System.Collections.Generic.List[string]
foreach ($arg in @('run', '-d', $Device, '--target', $Target)) {
    $runArgs.Add([string]$arg)
}
$runArgs.Add('--dart-define=RUN_FIREBASE_EMULATOR_TESTS=true')

if (-not $FullBoot) {
    $runArgs.Add('--dart-define=FAST_DEV_MODE=true')
}

if (-not $shouldRunPubGet) {
    $runArgs.Add('--no-pub')
}

if ($isWebDevice) {
    foreach ($arg in @(
        '--web-hostname', $WebHost,
        '--web-port', $WebPort.ToString(),
        '--no-wasm-dry-run'
    )) {
        $runArgs.Add([string]$arg)
    }
}

if ($TraceStartup) {
    $runArgs.Add('--trace-startup')
}

Invoke-Step -Label 'Run app' -Arguments $runArgs
