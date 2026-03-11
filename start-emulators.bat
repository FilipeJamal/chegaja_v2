@echo off
setlocal
echo ========================================
echo Starting Firebase Emulators
echo ========================================
echo.
echo NOTE: Firebase Emulators require Java 21 or higher.
echo If they fail to start, check your 'java -version'.
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

echo.
echo Checking Java version...

echo.
echo Checking Java version...

REM Try to find Java 21 in common locations
set "TARGET_JAVA_HOME=C:\Program Files\Microsoft\jdk-21.0.9.10-hotspot"

if exist "%TARGET_JAVA_HOME%" (
  echo Found Microsoft OpenJDK 21 at: %TARGET_JAVA_HOME%
  echo Setting JAVA_HOME for this session...
  set "JAVA_HOME=%TARGET_JAVA_HOME%"
  goto :SetPath
)

echo Microsoft OpenJDK 21 not found in default location.
echo Using system Java (hopefully version 21+)...
goto :CheckJava

:SetPath
set "PATH=%JAVA_HOME%\bin;%PATH%"

:CheckJava
java -version

echo.
echo Starting Firebase Emulators...
echo.

REM Increase discovery timeout (helps on Windows)
set FUNCTIONS_DISCOVERY_TIMEOUT=60

REM Use firebase.cmd to avoid PowerShell ExecutionPolicy issues
REM Prefer local config when available (uses firestore.rules.local)
set "FIREBASE_CONFIG="
if exist firebase.local.json (
  set "FIREBASE_CONFIG=firebase.local.json"
)
if defined FIREBASE_CONFIG (
  firebase.cmd emulators:start --config "%FIREBASE_CONFIG%"
) else (
  firebase.cmd emulators:start
)

endlocal
pause
