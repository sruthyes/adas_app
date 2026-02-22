# 🔥 Firebase Console Checklist

## Step-by-Step Firebase Console Verification

### 1. Access Firebase Console
- Go to: https://console.firebase.google.com/
- Select your project: **adas-cfb74**

### 2. Check Project Settings
**Path:** Project Settings (gear icon) → General

✅ **Verify Project ID:** `adas-cfb74`
✅ **Check Project Status:** Should be active
✅ **Check Billing:** Ensure project has billing enabled (if required)

### 3. Enable Email/Password Authentication
**Path:** Authentication → Sign-in method

1. Click on **Email/Password**
2. Enable **Email/Password** provider
3. Click **Save**

**⚠️ CRITICAL:** This is the most common cause of signup failures!

### 4. Check Authorized Domains
**Path:** Authentication → Settings → Authorized domains

Ensure these domains are listed:
- `localhost` (for development)
- Your production domain (if applicable)

### 5. Verify App Configuration
**Path:** Project Settings → Your apps

**Android App:**
- Package name: `com.example.adas_app`
- SHA-1 fingerprint: (check if needed)

**iOS App:**
- Bundle ID: `com.example.adasApp`
- App Store ID: (if published)

**Web App:**
- App nickname: (any name)
- Web API key: Should match your firebase_options.dart

### 6. Check Firestore Database
**Path:** Firestore Database

1. **Create Database** (if not exists):
   - Click "Create database"
   - Choose "Start in test mode"
   - Select location (closest to your users)

2. **Verify Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 7. Check Storage (if using)
**Path:** Storage

1. **Create Storage** (if not exists)
2. **Verify Rules:**
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 8. Test Authentication
**Path:** Authentication → Users

1. Try creating a test user manually
2. If this fails, there's a configuration issue

## 🚨 Common Issues & Solutions

### Issue: "operation-not-allowed"
**Solution:** Email/Password authentication is not enabled
- Go to Authentication → Sign-in method
- Enable Email/Password provider

### Issue: "invalid-api-key"
**Solution:** API key mismatch
- Check firebase_options.dart
- Verify API key in Firebase Console

### Issue: "network-request-failed"
**Solution:** Network/connectivity issue
- Check internet connection
- Verify Firebase services are accessible
- Check firewall settings

### Issue: "project-not-found"
**Solution:** Wrong project ID
- Verify project ID in firebase_options.dart
- Check Firebase Console project selection

## 🔍 Debug Commands

Run these commands to test your setup:

```bash
# Run with verbose logging
flutter run -v

# Check Firebase configuration
flutterfire configure

# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

## 📱 Platform-Specific Checks

### Android
- ✅ `google-services.json` in `android/app/`
- ✅ Google Services plugin in `build.gradle`
- ✅ Package name matches Firebase Console

### iOS
- ✅ `GoogleService-Info.plist` in `ios/Runner/`
- ✅ Bundle ID matches Firebase Console
- ✅ Added to Xcode project

### macOS
- ✅ `GoogleService-Info.plist` in `macos/Runner/`
- ✅ Bundle ID matches Firebase Console
- ✅ Added to Xcode project

## ✅ Verification Checklist

- [ ] Firebase project is active
- [ ] Email/Password authentication is enabled
- [ ] Firestore database is created
- [ ] App configurations match Firebase Console
- [ ] Configuration files are in correct locations
- [ ] Network connectivity is working
- [ ] No domain restrictions blocking requests

## 🆘 Still Having Issues?

If you've checked everything above and still get errors:

1. **Check the console output** when running `flutter run -v`
2. **Look for specific error codes** (e.g., `operation-not-allowed`, `invalid-api-key`)
3. **Test with a fresh Firebase project** to isolate the issue
4. **Check Firebase status page** for service outages
5. **Verify your internet connection** and firewall settings

## 📞 Support Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Support](https://firebase.google.com/support)

