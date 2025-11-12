import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();
  final FirestoreService _firestore = FirestoreService();
  User? user;
  bool _isLoading = false;

  bool get isSignedIn => user != null && (user?.emailVerified ?? false);
  bool get isSignedInButUnverified => user != null && !(user?.emailVerified ?? false);
  bool get isLoading => _isLoading;

  AuthProvider() {
    _service.userChanges.listen((u) {
      user = u;
      notifyListeners();
    });
  }

  Future<void> reloadUser() async {
    await user?.reload();
    user = _service.currentUser;
    notifyListeners();
  }

  Future<void> signUp(String email, String password, String name) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final credential = await _service.signUp(email, password);
      if (credential.user != null) {
        await _firestore.saveUserName(credential.user!.uid, name);
        await credential.user?.sendEmailVerification();
        await credential.user?.reload();
        user = credential.user;
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final credential = await _service.signIn(email, password);
      await credential.user?.reload();
      user = credential.user;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resendVerificationEmail() async {
    await _service.resendVerificationEmail();
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _service.signOut();
      user = null;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}