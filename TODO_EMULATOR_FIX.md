# Firebase Emulator Connection Fix - TODO

## Problem
Flutter app configured to use Firebase emulators but emulators are not running, causing network-request-failed errors.

## Tasks

### 1. Create Emulator Startup Scripts ✅
- [x] Create `start-emulators.bat` for Windows
- [x] Create `start-emulators.sh` for Linux/Mac
- [x] Add instructions to start emulators

### 2. Improve Error Handling in main.dart ✅
- [x] Add emulator connectivity check
- [x] Provide clear error messages when emulators aren't running
- [x] Add helpful instructions in console output
- [x] Display required emulator ports and URLs

### 3. Create Development Documentation ✅
- [x] Create DEVELOPMENT.md with setup instructions
- [x] Document correct startup sequence
- [x] Add troubleshooting section
- [x] Add common commands reference

### 4. Testing ⏳
- [ ] Test with emulators running
- [ ] Test with emulators not running (error handling)
- [ ] Verify anonymous authentication works
- [ ] Confirm Firestore queries succeed

## Current Status
✅ **Implementation complete!** Ready for testing.

All code changes and documentation have been completed. The user now needs to:
1. Start the Firebase emulators
2. Test the application
3. Verify the fixes work as expected

## Next Steps

1. **Start the Firebase Emulators:**
   ```bash
   # Windows
   start-emulators.bat
   
   # Linux/Mac
   ./start-emulators.sh
   ```

2. **Wait for "All emulators ready!" message**

3. **Run the Flutter app:**
   ```bash
   flutter run -d chrome
   ```

4. **Verify the app connects successfully**

## Files Created/Modified

### Created:
- ✅ `start-emulators.bat` - Windows script to start emulators
- ✅ `start-emulators.sh` - Linux/Mac script to start emulators  
- ✅ `DEVELOPMENT.md` - Comprehensive development guide (300+ lines)
- ✅ `QUICK_START.md` - Quick reference guide for developers
- ✅ `TODO_EMULATOR_FIX.md` - This tracking file

### Modified:
- ✅ `lib/main.dart` - Added better error handling and helpful console messages
- ✅ `README.md` - Updated emulator section with clear instructions

## Expected Behavior After Fix

### When Emulators ARE Running:
```
[AppConfig] useEmulators=true host=localhost
[Firebase] A usar emuladores em localhost
[Firebase] IMPORTANTE: Certifique-se que os emuladores estão a correr!
[Firebase] Execute: firebase emulators:start (ou start-emulators.bat)
[Firebase] Emuladores configurados com sucesso
[Auth] Utilizador autenticado com sucesso
```

### When Emulators ARE NOT Running:
```
[AppConfig] useEmulators=true host=localhost
[Firebase] A usar emuladores em localhost
[Firebase] IMPORTANTE: Certifique-se que os emuladores estão a correr!
[Firebase] Execute: firebase emulators:start (ou start-emulators.bat)
[Firebase] Emuladores configurados com sucesso
Erro ao autenticar/gravar user anónimo: [firebase_auth/network-request-failed]

═══════════════════════════════════════════════════════════════
⚠️  ERRO: Não foi possível conectar aos emuladores Firebase!
═══════════════════════════════════════════════════════════════

Os emuladores Firebase NÃO estão a correr.

SOLUÇÃO:
1. Abra um novo terminal
2. Execute: firebase emulators:start
   (ou clique duas vezes em start-emulators.bat)
3. Aguarde a mensagem "All emulators ready!"
4. Reinicie esta aplicação (pressione R)

Emuladores necessários:
- Auth Emulator: http://localhost:9099
- Firestore Emulator: http://localhost:8080
- Functions Emulator: http://localhost:5001
- Storage Emulator: http://localhost:9199
- Emulator UI: http://localhost:4000

Para mais informações, consulte DEVELOPMENT.md
═══════════════════════════════════════════════════════════════
```
