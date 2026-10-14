import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService extends ChangeNotifier {
  static const String authorizedEmail = 'mytravels@gmail.com';
  static const List<String> allowedEmails = [
    'mytravels@gmail.com',
    'aerosphere@gmail.com',
  ];

  static bool isEmailAllowed(String? email) {
    if (email == null) return false;
    final clean = email.trim().toLowerCase();
    return allowedEmails.any((e) => e.toLowerCase() == clean);
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<User?>? _sub;
  bool _isInitialized = false;

  bool get isAuthenticated {
    final user = _auth.currentUser;
    return user != null && isEmailAllowed(user.email);
  }

  User? get currentUser => _auth.currentUser;
  String? get currentUserEmail => _auth.currentUser?.email;
  bool get isInitialized => _isInitialized;

  AuthService() {
    _initAuthListener();
  }

  void _initAuthListener() {
    _sub = _auth.authStateChanges().listen((User? user) {
      _isInitialized = true;
      notifyListeners();
    });
  }

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      if (_auth.currentUser != null) {
        _isInitialized = true;
        return;
      }
      await _auth
          .authStateChanges()
          .first
          .timeout(const Duration(milliseconds: 1500));
    } catch (_) {}
    _isInitialized = true;
    notifyListeners();
  }

  /// Returns null on success, or an error message string on failure.
  Future<String?> login(String email, String password) async {
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();

    // Strict access control: only authorized email permitted
    if (!isEmailAllowed(cleanEmail)) {
      return 'Access Denied: Only $authorizedEmail is authorized to access this portal.';
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      final user = credential.user;
      if (user == null || !isEmailAllowed(user.email)) {
        await _auth.signOut();
        return 'Access Denied: Unauthorized account.';
      }

      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error [${e.code}]: ${e.message}');
      switch (e.code) {
        case 'user-not-found':
          return 'User not found in Firebase. Please create $authorizedEmail in Firebase Console.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Invalid password. Please enter the correct password.';
        case 'invalid-email':
          return 'Invalid email address format.';
        case 'user-disabled':
          return 'This user account has been disabled in Firebase.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment and try again.';
        case 'operation-not-allowed':
          return 'Email/Password sign-in is not enabled in Firebase Console (Authentication > Sign-in method).';
        default:
          return e.message ?? 'Authentication failed (${e.code}).';
      }
    } catch (e) {
      debugPrint('Login unexpected error: $e');
      return 'Authentication error: ${e.toString()}';
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final authServiceInstance = AuthService();
