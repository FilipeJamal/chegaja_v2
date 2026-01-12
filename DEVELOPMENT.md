# ChegaJa V2 - Development Guide

## Prerequisites

- Flutter SDK (latest stable version)
- Firebase CLI (`npm install -g firebase-tools`)
- Node.js and npm (for Firebase Functions)
- A code editor (VS Code recommended)

## Initial Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd chegaja_v2
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Install Firebase Functions dependencies**
   ```bash
   cd functions
   npm install
   cd ..
   ```

4. **Configure environment variables**
   - Copy `.env.example` to `.env`
   - Update the values according to your setup:
     ```
     USE_FIREBASE_EMULATORS=true
     FIREBASE_EMULATOR_HOST=localhost
     FUNCTIONS_REGION=europe-west1
     # Add other required keys...
     ```

5. **Login to Firebase**
   ```bash
   firebase login
   ```

## Running the Application with Emulators

### ⚠️ IMPORTANT: Start Emulators First!

The application is configured to use Firebase emulators in development mode. You **MUST** start the emulators before running the Flutter app, otherwise you'll get network connection errors.

### Step 1: Start Firebase Emulators

**On Windows:**
```bash
start-emulators.bat
```

**On Linux/Mac:**
```bash
chmod +x start-emulators.sh
./start-emulators.sh
```

**Or manually:**
```bash
firebase emulators:start
```

This will start:
- **Auth Emulator** on `http://localhost:9099`
- **Firestore Emulator** on `http://localhost:8080`
- **Functions Emulator** on `http://localhost:5001`
- **Storage Emulator** on `http://localhost:9199`
- **Emulator UI** on `http://localhost:4000`

### Step 2: Run the Flutter App

**In a new terminal window**, run:

```bash
# For Chrome (Web)
flutter run -d chrome

# For Android emulator
flutter run -d android

# For iOS simulator (Mac only)
flutter run -d ios
```

## Emulator UI

Once the emulators are running, you can access the Firebase Emulator UI at:
```
http://localhost:4000
```

This provides a web interface to:
- View and manage Auth users
- Browse Firestore collections
- Monitor Functions logs
- Inspect Storage files

## Troubleshooting

### Error: "network-request-failed" when starting the app

**Cause:** Firebase emulators are not running.

**Solution:** 
1. Make sure you started the emulators first (see Step 1 above)
2. Wait for the message "All emulators ready!" before running the Flutter app
3. Keep the emulator terminal window open while developing

### Error: "Address already in use"

**Cause:** Another process is using one of the emulator ports.

**Solution:**
1. Stop any running emulators: Press `Ctrl+C` in the emulator terminal
2. Check for processes using the ports:
   ```bash
   # Windows
   netstat -ano | findstr :9099
   netstat -ano | findstr :8080
   
   # Linux/Mac
   lsof -i :9099
   lsof -i :8080
   ```
3. Kill the processes or change the ports in `firebase.json`

### Emulators won't start

**Cause:** Firebase CLI not installed or not logged in.

**Solution:**
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Verify installation
firebase --version
```

### PowerShell blocks firebase.ps1

**Cause:** Windows ExecutionPolicy blocks running the Firebase PowerShell shim.

**Solution (pick one):**
```bash
# Option 1: Use the batch shim
firebase.cmd emulators:start

# Option 2: Use npx
npx firebase-tools emulators:start
```

### App connects to production instead of emulators

**Cause:** `USE_FIREBASE_EMULATORS` is not set to `true` in `.env`

**Solution:**
1. Check your `.env` file
2. Ensure `USE_FIREBASE_EMULATORS=true`
3. Restart the Flutter app

## Development Workflow

1. **Start emulators** (keep running in one terminal)
   ```bash
   firebase emulators:start
   ```

2. **Run Flutter app** (in another terminal)
   ```bash
   flutter run -d chrome
   ```

3. **Make changes** to your code

4. **Hot reload** - Press `r` in the Flutter terminal for quick updates

5. **Hot restart** - Press `R` for a full restart

6. **View logs** - Check both terminals for errors

## Testing

### Running Tests
```bash
flutter test
```

### Testing with Emulators
The emulators provide a clean, isolated environment for testing without affecting production data.

## Switching to Production

To connect to production Firebase instead of emulators:

1. Update `.env`:
   ```
   USE_FIREBASE_EMULATORS=false
   ```

2. Restart the Flutter app

⚠️ **Warning:** Be careful when testing with production data!

## Common Commands

```bash
# Start emulators
firebase emulators:start

# Start emulators with specific services
firebase emulators:start --only auth,firestore

# Export emulator data
firebase emulators:export ./emulator-data

# Import emulator data
firebase emulators:start --import=./emulator-data

# Clear emulator data
# Just restart the emulators (data is not persisted by default)

# Deploy to production
firebase deploy

# Deploy specific services
firebase deploy --only functions
firebase deploy --only firestore:rules
```

## Project Structure

```
chegaja_v2/
├── lib/
│   ├── core/
│   │   ├── config/        # App configuration
│   │   ├── models/        # Data models
│   │   ├── repositories/  # Data access layer
│   │   ├── services/      # Business logic
│   │   └── theme/         # UI theme
│   ├── features/
│   │   ├── auth/          # Authentication screens
│   │   ├── cliente/       # Client features
│   │   ├── prestador/     # Service provider features
│   │   └── common/        # Shared features
│   └── main.dart          # App entry point
├── functions/             # Firebase Cloud Functions
├── web/                   # Web-specific files
├── android/               # Android-specific files
├── ios/                   # iOS-specific files
└── test/                  # Tests

```

## Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Firebase Emulator Suite](https://firebase.google.com/docs/emulator-suite)

## Support

If you encounter issues not covered in this guide, please:
1. Check the Firebase Emulator logs
2. Check the Flutter console output
3. Review the troubleshooting section above
4. Contact the development team
