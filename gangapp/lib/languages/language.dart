import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;
import 'english.dart';
import 'arabic.dart';

class Language extends ChangeNotifier {
  static const String _languageKey = 'language_code';
  late SharedPreferences _prefs;
  late Map<String, String> _currentLanguage;
  bool _isInitialized = false;
  late Map<String, Map<String, String>> _translations;

  Language() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadLanguage();
    _isInitialized = true;
    notifyListeners();
    _initializeTranslations();
  }

  bool get isInitialized => _isInitialized;
  bool get isRTL => _currentLanguage == Arabic.values;

  Future<void> _loadLanguage() async {
    String? savedLanguage = _prefs.getString(_languageKey);
    if (savedLanguage != null) {
      _currentLanguage = savedLanguage == 'ar' ? Arabic.values : English.values;
    } else {
      // Use device locale if no saved preference
      String deviceLanguage = ui.window.locale.languageCode;
      _currentLanguage =
          deviceLanguage == 'ar' ? Arabic.values : English.values;
      await _prefs.setString(_languageKey, deviceLanguage);
    }
  }

  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode == 'ar' ? Arabic.values : English.values;
    await _prefs.setString(_languageKey, languageCode);
    notifyListeners();
  }

  String get(String key) {
    return _currentLanguage[key] ?? key;
  }

  // Helper method to get the current language code
  String get currentLanguageCode =>
      _currentLanguage == Arabic.values ? 'ar' : 'en';

  void _initializeTranslations() {
    _translations = {
      'en': {
        // ... existing translations ...
        'write_comment': 'Write a comment...',
        'reply': 'Reply',
        // ... existing translations ...
      },
      'ar': {
        // ... existing translations ...
        'write_comment': 'اكتب تعليقاً...',
        'reply': 'رد',
        // ... existing translations ...
      },
    };
  }
}
