import 'package:flutter/material.dart';

import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  User? _user;

  User? get user => _user;

  bool get isAuthenticated => _user != null;

  void login(String email, String password) {
    // Dummy login validation (password length >= 6)
    if (password.length >= 6) {
      _user = User(
        email: email,
        name: 'Ukshita',
        age: 23,
        gender: 'Female',
      );
      notifyListeners();
    }
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}
