# 🚀 Quick Start Guide - ChegaJa V2

## TL;DR - Get Running in 3 Steps

### Step 1: Start Firebase Emulators
```bash
# Windows - Double click or run:
start-emulators.bat

# Linux/Mac:
./start-emulators.sh
```

**Wait for:** `✔  All emulators ready!`

### Step 2: Run the App (in a NEW terminal)
```bash
flutter run -d chrome
```

### Step 3: Access the App
- **App:** Opens automatically in Chrome
- **Emulator UI:** http://localhost:4000

---

## ⚠️ Common Issues

### Issue: "network-request-failed" error

**Cause:** Firebase emulators are not running.

**Fix:**
1. Check if emulators are running (look for the terminal with emulator logs)
2. If not running, start them: `start-emulators.bat` (Windows) or `./start-emulators.sh` (Linux/Mac)
3. Wait for "All emulators ready!"
4. Press `R` in the Flutter terminal to hot restart

---

### Issue: "Address already in use"

**Cause:** Emulator ports are already in use.

**Fix:**
1. Stop any running emulators (Ctrl+C in the emulator terminal)
2. Close any other apps using ports 4000, 5001, 8080, 9099, or 9199
3. Restart emulators

---

### Issue: App shows blank screen or errors

**Cause:** App started before emulators were ready.

**Fix:**
1. Make sure emulators show "All emulators ready!"
2. Press `R` in the Flutter terminal to hot restart
3. If still not working, press `q` to quit, then run `flutter run -d chrome` again

---

## 📋 Development Workflow

```
Terminal 1 (Emulators):          Terminal 2 (Flutter):
┌─────────────────────┐          ┌─────────────────────┐
│ start-emulators.bat │          │ flutter run -d      │
│                     │          │ chrome              │
│ [Keep running]      │          │                     │
│                     │          │ Press 'r' to reload │
│ ✔ All emulators    │          │ Press 'R' to        │
│   ready!           │          │ restart             │
└─────────────────────┘          └─────────────────────┘
```

**Keep both terminals open while developing!**

---

## 🔧 Useful Commands

### In Flutter Terminal:
- `r` - Hot reload (fast, preserves state)
- `R` - Hot restart (full restart)
- `q` - Quit the app
- `h` - Show all commands

### Emulator Management:
```bash
# Start emulators
firebase emulators:start

# Start specific emulators only
firebase emulators:start --only auth,firestore

# Export emulator data (save state)
firebase emulators:export ./emulator-data

# Import emulator data (restore state)
firebase emulators:start --import=./emulator-data
```

---

## 📚 More Information

- **Full Setup Guide:** See `DEVELOPMENT.md`
- **Troubleshooting:** See `DEVELOPMENT.md` → Troubleshooting section
- **Project Structure:** See `README.md`

---

## 🎯 What's Running?

When everything is working correctly, you should see:

### Emulator Terminal:
```
✔  All emulators ready! It is now safe to connect your app.
┌─────────────────────────────────────────────────────────────┐
│ ✔  All emulators ready! View status and logs at http://localhost:4000 │
└─────────────────────────────────────────────────────────────┘

┌───────────┬────────────────┬─────────────────────────────────┐
│ Emulator  │ Host:Port      │ View in Emulator UI             │
├───────────┼────────────────┼─────────────────────────────────┤
│ Auth      │ localhost:9099 │ http://localhost:4000/auth      │
├───────────┼────────────────┼─────────────────────────────────┤
│ Firestore │ localhost:8080 │ http://localhost:4000/firestore │
├───────────┼────────────────┼─────────────────────────────────┤
│ Functions │ localhost:5001 │ http://localhost:4000/functions │
├───────────┼────────────────┼─────────────────────────────────┤
│ Storage   │ localhost:9199 │ http://localhost:4000/storage   │
└───────────┴────────────────┴─────────────────────────────────┘
```

### Flutter Terminal:
```
[AppConfig] useEmulators=true host=localhost
[Firebase] A usar emuladores em localhost
[Firebase] Emuladores configurados com sucesso
[Auth] Utilizador autenticado com sucesso

Flutter run key commands.
r Hot reload.
R Hot restart.
```

---

## 🎉 You're Ready!

If you see the messages above, everything is working correctly. You can now:
- Make changes to the code
- Press `r` for hot reload
- Test features in the app
- View data in the Emulator UI (http://localhost:4000)

Happy coding! 🚀
