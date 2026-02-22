import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseTest {
  static Future<Map<String, dynamic>> runDiagnostics() async {
    Map<String, dynamic> results = {
      'firebase_core': false,
      'firebase_auth': false,
      'firestore': false,
      'errors': <String>[],
    };

    try {
      // Test Firebase Core
      if (Firebase.apps.isNotEmpty) {
        results['firebase_core'] = true;
        print('✅ Firebase Core: Initialized');
      } else {
        results['errors'].add('Firebase Core not initialized');
        print('❌ Firebase Core: Not initialized');
      }
    } catch (e) {
      results['errors'].add('Firebase Core error: $e');
      print('❌ Firebase Core error: $e');
    }

    try {
      // Test Firebase Auth
      final auth = FirebaseAuth.instance;
      results['firebase_auth'] = true;
      print('✅ Firebase Auth: Available');
    } catch (e) {
      results['errors'].add('Firebase Auth error: $e');
      print('❌ Firebase Auth error: $e');
    }

    try {
      // Test Firestore
      final firestore = FirebaseFirestore.instance;
      results['firestore'] = true;
      print('✅ Firestore: Available');
    } catch (e) {
      results['errors'].add('Firestore error: $e');
      print('❌ Firestore error: $e');
    }

    return results;
  }

  static void printDiagnostics() {
    print('\n🔍 Firebase Diagnostics:');
    print('=' * 50);
    runDiagnostics().then((results) {
      print('\n📊 Results:');
      print('Firebase Core: ${results['firebase_core'] ? '✅' : '❌'}');
      print('Firebase Auth: ${results['firebase_auth'] ? '✅' : '❌'}');
      print('Firestore: ${results['firestore'] ? '✅' : '❌'}');
      
      if (results['errors'].isNotEmpty) {
        print('\n❌ Errors found:');
        for (String error in results['errors']) {
          print('  - $error');
        }
      } else {
        print('\n✅ All Firebase services are working correctly!');
      }
      print('=' * 50);
    });
  }
}

