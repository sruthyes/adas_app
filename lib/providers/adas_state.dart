import 'package:flutter/material.dart';

class AdasState extends ChangeNotifier {
  bool _isActive = false;

  bool get isActive => _isActive;

  void toggleAdas() {
    _isActive = !_isActive;
    notifyListeners();
  }

  void activate() {
    _isActive = true;
    notifyListeners();
  }

  void deactivate() {
    _isActive = false;
    notifyListeners();
  }
}