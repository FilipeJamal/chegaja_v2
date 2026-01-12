#!/bin/bash

echo "========================================"
echo "Starting Firebase Emulators"
echo "========================================"
echo ""
echo "This will start the following emulators:"
echo "- Auth Emulator (port 9099)"
echo "- Firestore Emulator (port 8080)"
echo "- Functions Emulator (port 5001)"
echo "- Storage Emulator (port 9199)"
echo "- Emulator UI (port 4000)"
echo ""
echo "Press Ctrl+C to stop the emulators"
echo "========================================"
echo ""

# Increase discovery timeout (helps on slower machines)
export FUNCTIONS_DISCOVERY_TIMEOUT=60

firebase emulators:start
