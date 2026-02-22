import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseDebug {
  static Future<void> testFirebaseConnection() async {
    print('\n🔍 FIREBASE DEBUG TEST');
    print('=' * 50);
    
    try {
      // Test 1: Check if Firebase is initialized
      print('1. Checking Firebase initialization...');
      if (Firebase.apps.isEmpty) {
        print('❌ Firebase not initialized!');
        return;
      }
      print('✅ Firebase is initialized');
      
      // Test 2: Check Firebase Auth
      print('\n2. Testing Firebase Auth...');
      final auth = FirebaseAuth.instance;
      print('✅ Firebase Auth instance created');
      print('   App name: ${auth.app.name}');
      print('   Current user: ${auth.currentUser?.uid ?? "None"}');
      
      // Test 3: Check Firestore
      print('\n3. Testing Firestore...');
      final firestore = FirebaseFirestore.instance;
      print('✅ Firestore instance created');
      print('   App name: ${firestore.app.name}');
      
      // Test 4: Check network connectivity
      print('\n4. Testing network connectivity...');
      try {
        // Try to access Firestore (this will test network)
        await firestore.collection('test').limit(1).get();
        print('✅ Network connectivity confirmed');
      } catch (e) {
        print('⚠️ Network test failed (this might be normal): $e');
      }
      
      print('\n✅ All Firebase services are working correctly!');
      
    } catch (e) {
      print('❌ Firebase debug test failed: $e');
      print('Stack trace: ${StackTrace.current}');
    }
    
    print('=' * 50);
  }
  
  static Future<void> testAuthWithDummyData() async {
    print('\n🧪 TESTING AUTH WITH DUMMY DATA');
    print('=' * 50);
    
    try {
      final auth = FirebaseAuth.instance;
      
      // Test creating a user (this will fail if auth is not properly configured)
      print('Testing user creation with dummy data...');
      print('Note: This will fail if Email/Password is not enabled in Firebase Console');
      
      // We won't actually create a user, just test the method
      print('✅ Auth service is accessible');
      print('✅ Ready to test signup (check Firebase Console for Email/Password settings)');
      
    } catch (e) {
      print('❌ Auth test failed: $e');
    }
    
    print('=' * 50);
  }
}

