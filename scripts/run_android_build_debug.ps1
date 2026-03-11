Param(
    [int]$TimeoutMinutes = 45
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$androidDir = Join-Path $repoRoot "android"
$artifactsDir = Join-Path $repoRoot "artifacts\e2e"
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$stdoutPath = Join-Path $artifactsDir "gradle-assemble-debug-$stamp.out.log"
$stderrPath = Join-Path $artifactsDir "gradle-assemble-debug-$stamp.err.log"

New-Item -ItemType Directory -Force -Path $artifactsDir | Out-Null

$arguments = "app:assembleDebug --stacktrace --no-daemon --console=plain"
$gradlewPath = Join-Path $androidDir "gradlew.bat"
$process = Start-Process `
    -FilePath $gradlewPath `
    -ArgumentList $arguments `
    -WorkingDirectory $androidDir `
    -RedirectStandardOutput $stdoutPath `
    -RedirectStandardError $stderrPath `
    -PassThru

Write-Output "Started Gradle PID=$($process.Id)"
Write-Output "Stdout: $stdoutPath"
Write-Output "Stderr: $stderrPath"

$deadline = (Get-Date).AddMinutes($TimeoutMinutes)
$lastSize = 0L

while (-not $process.HasExited -and (Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 20
    $process.Refresh()

    if (Test-Path $stdoutPath) {
        $size = (Get-Item $stdoutPath).Length
        if ($size -ne $lastSize) {
            $lastSize = $size
            Write-Output "--- gradle tail ---"
            Get-Content $stdoutPath -Tail 30
            if (Test-Path $stderrPath) {
                $errSize = (Get-Item $stderrPath).Length
                if ($errSize -gt 0) {
                    Write-Output "--- gradle stderr tail ---"
                    Get-Content $stderrPath -Tail 20
                }
            }
        }
    }
}

if (-not $process.HasExited) {
    Write-Output "Timeout reached. Killing PID=$($process.Id)"
    Stop-Process -Id $process.Id -Force
    if (Test-Path $stdoutPath) {
        Get-Content $stdoutPath -Tail 120
    }
    if (Test-Path $stderrPath) {
        Get-Content $stderrPath -Tail 120
    }
    exit 124
}

Write-Output "Gradle exited with code $($process.ExitCode)"
if (Test-Path $stdoutPath) {
    Get-Content $stdoutPath -Tail 180
}
if (Test-Path $stderrPath) {
    Get-Content $stderrPath -Tail 180
}

exit $process.ExitCode
