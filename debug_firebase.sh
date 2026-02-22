#!/bin/bash

echo "🔍 Firebase Debug Script"
echo "========================"
echo ""
echo "This script will run your Flutter app with verbose logging to help debug Firebase issues."
echo ""

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter first."
    exit 1
fi

echo "📱 Starting Flutter app with verbose logging..."
echo "Look for Firebase-related messages in the output below:"
echo ""

# Run Flutter with verbose logging
flutter run -v

echo ""
echo "🔍 Debug completed. Check the output above for Firebase error messages."
echo ""
echo "Common things to look for:"
echo "- ✅ Firebase initialized successfully"
echo "- ❌ Firebase initialization error"
echo "- 🔥 Firebase Auth Error"
echo "- Network connectivity issues"
echo ""

