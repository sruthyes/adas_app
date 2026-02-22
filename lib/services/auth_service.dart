import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if Firebase is properly initialized
  bool get isFirebaseInitialized {
    try {
      return _auth.app.name.isNotEmpty;
    } catch (e) {
      print('🔥 Firebase not initialized: $e');
      return false;
    }
  }

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
          
      // Update last login
      await _firestore.collection('users').doc(result.user!.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
      
      return result;
    } on FirebaseAuthException catch (e) {
      print(' Firebase Auth Error Code: ${e.code}');
      print(' Firebase Auth Error Message: ${e.message}');
      print('Firebase Auth Error Details: $e');
      rethrow;
    } catch (e) {
      print(' General Error: $e');
      rethrow;
    }
  }

  // Forgot password (send reset email)
      Future<void> sendPasswordResetEmail(String email) async {
        try {
          await _auth.sendPasswordResetEmail(email: email);
        } on FirebaseAuthException catch (e) {
          print(' Forgot Password Error Code: ${e.code}');
          print('Forgot Password Message: ${e.message}');
          rethrow;
        } catch (e) {
          print(' Forgot Password General Error: $e');
          rethrow;
        }
      }


  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password, String name) async {
    try {
      print('\nFIREBASE AUTH DEBUG');
      print('=' * 40);
      print(' Attempting to create user with email: $email');
      print(' Firebase Auth instance: ${_auth.app.name}');
      print(' Firebase Auth current user: ${_auth.currentUser?.uid}');
      print(' Firebase project: ${_auth.app.options.projectId}');
      
      // Test Firebase connectivity first
      print('📝 Testing Firebase connectivity...');
      try {
        await _firestore.collection('test').limit(1).get();
        print('✅ Firestore connectivity confirmed');
      } catch (e) {
        print('⚠️ Firestore connectivity test failed: $e');
      }
      
      print('📝 Creating user with Firebase Auth...');
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('✅ User created successfully: ${result.user!.uid}');
      print('📝 User email verified: ${result.user!.emailVerified}');
      print('📝 Creating user document in Firestore...');
      
      // Create user document in Firestore
      await _createUserDocument(result.user!, name);
      
      print('✅ User document created successfully');
      print('=' * 40);
      return result;
    } on FirebaseAuthException catch (e) {
      print('\n🔥 FIREBASE AUTH ERROR');
      print('=' * 40);
      print('🔥 Error Code: ${e.code}');
      print('🔥 Error Message: ${e.message}');
      print('🔥 Error Details: $e');
      print('🔥 Stack trace: ${StackTrace.current}');
      
      // Provide specific guidance based on error code
      switch (e.code) {
        case 'operation-not-allowed':
          print('💡 SOLUTION: Enable Email/Password in Firebase Console → Authentication → Sign-in method');
          break;
        case 'invalid-api-key':
          print('💡 SOLUTION: Check your firebase_options.dart API key');
          break;
        case 'network-request-failed':
          print('💡 SOLUTION: Check your internet connection and Firebase service status');
          break;
        case 'project-not-found':
          print('💡 SOLUTION: Verify your Firebase project ID in firebase_options.dart');
          break;
        default:
          print('💡 SOLUTION: Check Firebase Console settings and network connectivity');
      }
      print('=' * 40);
      rethrow;
    } catch (e) {
      print('\n🔥 GENERAL ERROR');
      print('=' * 40);
      print('🔥 Error: $e');
      print('🔥 Stack trace: ${StackTrace.current}');
      print('=' * 40);
      rethrow;
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(User user, String name) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'name': name,
        'photoUrl': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      print('🔥 Firestore Error Code: ${e.code}');
      print('🔥 Firestore Error Message: ${e.message}');
      print('🔥 Firestore Error Details: $e');
      rethrow;
    } catch (e) {
      print('🔥 Firestore General Error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print('🔥 Sign Out Error: $e');
      rethrow;
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('🔥 Get User Data Error: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      return await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      print('🔥 Update Profile Error: $e');
      rethrow;
    }
  }
}