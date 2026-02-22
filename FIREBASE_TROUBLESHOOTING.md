# Firebase Authentication Troubleshooting Guide

## 🔍 Common Issues and Solutions

### 1. Firebase Not Initialized
**Symptoms:** App crashes or authentication fails with "Firebase not initialized" error.

**Solutions:**
- ✅ **Fixed:** Added Firebase initialization check in `main.dart`
- ✅ **Fixed:** Added diagnostic logging to identify initialization issues
- ✅ **Fixed:** Added Firebase connectivity test utility

### 2. Missing Firebase Configuration Files
**Symptoms:** "Missing google-services.json" or "Missing GoogleService-Info.plist" errors.

**Current Status:**
- ✅ **Android:** `android/app/google-services.json` - Present and valid
- ✅ **iOS:** `ios/Runner/GoogleService-Info.plist` - Present and valid  
- ✅ **macOS:** `macos/Runner/GoogleService-Info.plist` - Present and valid

### 3. Email/Password Authentication Not Enabled
**Symptoms:** "operation-not-allowed" error during signup.

**To Fix:**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `adas-cfb74`
3. Navigate to **Authentication** → **Sign-in method**
4. Enable **Email/Password** provider
5. Save changes

### 4. Bundle ID Mismatch
**Current Issue Found:**
- **Android:** `com.example.adas_app` (with underscore)
- **iOS/macOS:** `com.example.adasApp` (camelCase)

**To Fix:**
1. Update iOS/macOS bundle ID to match Android: `com.example.adas_app`
2. Or update Android package name to match iOS: `com.example.adasApp`
3. Regenerate configuration files in Firebase Console

### 5. Network/Connectivity Issues
**Symptoms:** "network-request-failed" error.

**Solutions:**
- Check internet connection
- Verify Firebase project is active
- Check if Firebase services are accessible in your region

## 🛠️ Debugging Steps

### Step 1: Check Console Output
Run the app and look for these messages:
```
✅ Firebase initialized successfully
🔍 Firebase Diagnostics:
✅ Firebase Core: Initialized
✅ Firebase Auth: Available  
✅ Firestore: Available
```

### Step 2: Test Firebase Connection
The app now includes automatic Firebase diagnostics that will show:
- Firebase Core initialization status
- Firebase Auth availability
- Firestore connectivity
- Any specific error messages

### Step 3: Verify Firebase Console Settings
1. **Authentication → Sign-in method:**
   - Email/Password should be **Enabled**
   - Authorized domains should include your app's domain

2. **Project Settings:**
   - Verify project ID: `adas-cfb74`
   - Check that all platforms (Android, iOS, Web) are configured

### Step 4: Test with Different Credentials
Try creating a test account with:
- Simple email: `test@example.com`
- Strong password: `Test123!@#`
- Valid name: `Test User`

## 🚨 Error Codes and Solutions

| Error Code | Meaning | Solution |
|------------|---------|---------|
| `weak-password` | Password too weak | Use stronger password (6+ chars) |
| `email-already-in-use` | Account exists | Use different email or login |
| `invalid-email` | Invalid email format | Check email format |
| `operation-not-allowed` | Auth method disabled | Enable Email/Password in Firebase Console |
| `network-request-failed` | Network issue | Check internet connection |
| `user-disabled` | Account disabled | Contact support |

## 📱 Platform-Specific Issues

### Android
- ✅ Google Services plugin configured
- ✅ google-services.json present
- ✅ Package name matches: `com.example.adas_app`

### iOS
- ✅ GoogleService-Info.plist present
- ⚠️ Bundle ID mismatch: `com.example.adasApp` vs `com.example.adas_app`

### macOS  
- ✅ GoogleService-Info.plist present
- ⚠️ Bundle ID mismatch: `com.example.adasApp` vs `com.example.adas_app`

## 🔧 Quick Fixes

### Fix Bundle ID Mismatch
1. Update iOS bundle ID in Xcode:
   - Open `ios/Runner.xcodeproj`
   - Change Bundle Identifier to `com.example.adas_app`
   
2. Update macOS bundle ID:
   - Open `macos/Runner.xcodeproj`  
   - Change Bundle Identifier to `com.example.adas_app`

3. Regenerate configuration files in Firebase Console

### Enable Email/Password Authentication
1. Go to Firebase Console → Authentication → Sign-in method
2. Click on "Email/Password"
3. Enable "Email/Password" provider
4. Save changes

## 📞 Support
If issues persist after trying these solutions:
1. Check the console output for specific error messages
2. Verify Firebase Console settings
3. Test with a fresh Firebase project
4. Contact Firebase support with specific error codes

## ✅ What's Been Fixed
- ✅ Added Firebase initialization diagnostics
- ✅ Enhanced error logging in AuthService
- ✅ Added Firebase connectivity test
- ✅ Improved error handling in signup screen
- ✅ Added initialization status checks

