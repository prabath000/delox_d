import 'package:flutter/material.dart';
import 'dart:io';
import '../services/database_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class User {
  final String name;
  final String email;
  final String password;
  final String? photoUrl;
  final String? website;

  User({
    required this.name, 
    required this.email, 
    required this.password, 
    this.photoUrl,
    this.website,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'password': password,
    'photoUrl': photoUrl,
    'website': website,
  };

  factory User.fromMap(Map<String, dynamic> map) => User(
    name: map['name'],
    email: map['email'],
    password: map['password'],
    photoUrl: map['photoUrl'],
    website: map['website'],
  );
}

class UserProvider with ChangeNotifier {
  User? _currentUser;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: Platform.isIOS 
      ? '326808345238-1lp0uag72hdjbjf6c3hqsr5tsl365n3v.apps.googleusercontent.com' 
      : null,
  );
  static const String _userEmailKey = 'user_email';
  static const String _userPhotoKey = 'user_photo';
  static const String _userNameKey = 'user_name';

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(_userEmailKey);
    
    if (savedEmail != null && savedEmail.isNotEmpty) {
      final normalizedEmail = savedEmail.trim().toLowerCase();
      final userMap = await DatabaseService.instance.getUserByEmail(normalizedEmail);
      if (userMap != null) {
        // Restore photo + name from prefs (may be more current than DB)
        final savedPhoto = prefs.getString(_userPhotoKey);
        final savedName = prefs.getString(_userNameKey);
        final user = User.fromMap(userMap);
        _currentUser = User(
          name: savedName ?? user.name,
          email: user.email,
          password: user.password,
          photoUrl: savedPhoto ?? user.photoUrl,
          website: user.website,
        );
        notifyListeners();
        debugPrint('Session restored for: $normalizedEmail');
      }
    }
  }

  Future<String> signInWithGoogle() async {
    try {
      // Clear any previous sign-in state to prevent intermittent failures
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return "cancelled";

      final String email = googleUser.email.toLowerCase();
      final String name = googleUser.displayName ?? "Google User";
      final String? photoUrl = googleUser.photoUrl;

      // Check if user exists in DB
      var userMap = await DatabaseService.instance.getUserByEmail(email);
      
      User user;
      if (userMap == null) {
        // Create new user for Google Sign-In (no password needed)
        user = User(name: name, email: email, password: "GOOGLE_AUTH", photoUrl: photoUrl);
        await DatabaseService.instance.insertUser(user.toMap());
      } else {
        user = User.fromMap(userMap);
        // Update photoUrl if it's new
        if (photoUrl != null && user.photoUrl != photoUrl) {
           user = User(name: user.name, email: user.email, password: user.password, photoUrl: photoUrl);
           await DatabaseService.instance.insertUser(user.toMap());
        }
      }

      _currentUser = user;
      
      // Save session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userEmailKey, email);
      if (user.photoUrl != null) await prefs.setString(_userPhotoKey, user.photoUrl!);
      await prefs.setString(_userNameKey, user.name);

      notifyListeners();
      return "success";
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      return "Google Sign-In failed: $e";
    }
  }

  Future<String> register(String name, String email, String password) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      
      // Check if user exists in DB
      final existingUser = await DatabaseService.instance.getUserByEmail(normalizedEmail);
      if (existingUser != null) {
        return "Email already registered";
      }

      final newUser = User(name: name, email: normalizedEmail, password: password);
      await DatabaseService.instance.insertUser(newUser.toMap());
      
      notifyListeners();
      return "success";
    } catch (e) {
      debugPrint('Registration Error: $e');
      return "Registration failed: $e";
    }
  }

  Future<String> login(String email, String password) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      debugPrint('Attempting login for: $normalizedEmail');
      
      final userMap = await DatabaseService.instance.getUserByEmail(normalizedEmail);
      if (userMap == null) {
        debugPrint('Login: User not found in DB');
        return "User not found";
      }

      final user = User.fromMap(userMap);
      if (user.password != password) {
        debugPrint('Login: Incorrect password');
        return "Incorrect password";
      }

      _currentUser = user;
      
      // Save session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userEmailKey, normalizedEmail);
      await prefs.setString(_userNameKey, user.name);

      notifyListeners();
      debugPrint('Login: Success for ${user.email}');
      return "success";
    } catch (e) {
      debugPrint('Login Error: $e');
      return "Login failed: $e";
    }
  }

  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google Sign-Out Error: $e');
    }
    
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updateWebsite(String url) async {
    if (_currentUser == null) return;
    
    final updatedUser = User(
      name: _currentUser!.name,
      email: _currentUser!.email,
      password: _currentUser!.password,
      photoUrl: _currentUser!.photoUrl,
      website: url,
    );
    
    await DatabaseService.instance.insertUser(updatedUser.toMap());
    _currentUser = updatedUser;
    notifyListeners();
  }
}
