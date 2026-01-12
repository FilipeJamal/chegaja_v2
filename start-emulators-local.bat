@echo off
setlocal
cd /d %~dp0

REM Aumenta timeout de discovery (útil no Windows)
set FUNCTIONS_DISCOVERY_TIMEOUT=60

REM Usa firebase.cmd para evitar o erro do PowerShell (ExecutionPolicy)
firebase.cmd emulators:start --config firebase.local.json --only auth,firestore,functions,storage --project chegaja-ac88d

endlocal
