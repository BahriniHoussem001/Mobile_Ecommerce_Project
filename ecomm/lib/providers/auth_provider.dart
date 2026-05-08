// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading, error }

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AppUser? _user;
  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;

  AppUser? get user => _user;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isAdmin => _user?.isAdmin ?? false;

  AuthProvider() {
    // Listen to Firebase Auth state changes — fires on cold restart too
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
      _status = AuthStatus.unauthenticated;
    } else {
      try {
        final doc = await _db.collection('users').doc(firebaseUser.uid).get();
        if (doc.exists) {
          _user = AppUser.fromMap(doc.data()!, firebaseUser.uid);
        } else {
          _user = AppUser(
            uid: firebaseUser.uid,
            name: firebaseUser.displayName ?? 'New Member',
            email: firebaseUser.email ?? '',
            createdAt: DateTime.now(),
          );
          await _db
              .collection('users')
              .doc(firebaseUser.uid)
              .set(_user!.toMap());
        }
        _status = AuthStatus.authenticated;
      } catch (_) {
        _status = AuthStatus.error;
        _errorMessage = 'Failed to load profile.';
      }
    }
    notifyListeners();
  }

  // ── Sign in ───────────────────────────────────────────────
  Future<bool> signIn(String email, String password) async {
    _setLoading();
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_authMessage(e.code));
      return false;
    }
  }

  // ── Sign up ───────────────────────────────────────────────
  Future<bool> signUp(String name, String email, String password) async {
    _setLoading();
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await cred.user?.updateDisplayName(name);
      final newUser = AppUser(
        uid: cred.user!.uid,
        name: name,
        email: email.trim(),
        createdAt: DateTime.now(),
      );
      await _db.collection('users').doc(cred.user!.uid).set(newUser.toMap());
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_authMessage(e.code));
      return false;
    }
  }

  // ── Password reset ────────────────────────────────────────
  Future<bool> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_authMessage(e.code));
      return false;
    }
  }

  // ── Sign out ──────────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ── Update profile (name + phone) ────────────────────────
  Future<void> updateProfile({String? name, String? phone}) async {
    if (_user == null) return;
    final updated = _user!.copyWith(name: name, phone: phone);
    await _db.collection('users').doc(_user!.uid).update(updated.toMap());
    _user = updated;
    notifyListeners();
  }

  // ── FIX: Add / replace shipping address ─────────────────
  // This was missing — the profile screen built an address but
  // called updateProfile(name, phone) which silently discarded it.
  Future<void> addAddress(ShippingAddress address) async {
    if (_user == null) return;

    // If this is set as default, clear isDefault on all others
    List<ShippingAddress> existing = List.from(_user!.addresses);
    if (address.isDefault) {
      existing = existing
          .map(
            (a) => ShippingAddress(
              id: a.id,
              label: a.label,
              fullName: a.fullName,
              street: a.street,
              city: a.city,
              postalCode: a.postalCode,
              country: a.country,
              isDefault: false,
            ),
          )
          .toList();
    }
    existing.add(address);

    final updated = _user!.copyWith(addresses: existing);
    await _db.collection('users').doc(_user!.uid).update({
      'addresses': existing.map((a) => a.toMap()).toList(),
    });
    _user = updated;
    notifyListeners();
  }

  // ── Delete address ────────────────────────────────────────
  Future<void> deleteAddress(String addressId) async {
    if (_user == null) return;
    final updated = _user!.addresses.where((a) => a.id != addressId).toList();
    await _db.collection('users').doc(_user!.uid).update({
      'addresses': updated.map((a) => a.toMap()).toList(),
    });
    _user = _user!.copyWith(addresses: updated);
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────
  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  String _authMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with that email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'Email already registered.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
