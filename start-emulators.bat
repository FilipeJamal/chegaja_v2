@echo off
setlocal
echo ========================================
echo Starting Firebase Emulators
echo ========================================
echo.
echo This will start the following emulators:
echo - Auth Emulator (port 9099)
echo - Firestore Emulator (port 8080)
echo - Functions Emulator (port 5001)
echo - Storage Emulator (port 9199)
echo - Emulator UI (port 4000)
echo.
echo Press Ctrl+C to stop the emulators
echo ========================================
echo.

REM Increase discovery timeout (helps on Windows)
set FUNCTIONS_DISCOVERY_TIMEOUT=60

REM Use firebase.cmd to avoid PowerShell ExecutionPolicy issues
REM Prefer local config when available (uses firestore.rules.local)
set FIREBASE_CONFIG=
if exist firebase.local.json (
  set FIREBASE_CONFIG=--config firebase.local.json
)
firebase.cmd emulators:start %FIREBASE_CONFIG%

endlocal
pause
