import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted UI language. English is the default and the only fallback.
///
/// First launch, a missing key, or any invalid saved code all resolve to `en`.
/// The device locale is never applied automatically.
class LocaleController extends ChangeNotifier {
  LocaleController._();
  static final LocaleController instance = LocaleController._();

  static const prefKey = 'app_locale';
  static const defaultCode = 'en';
  static const supportedCodes = ['en', 'ar'];

  static const english = Locale('en');
  static const arabic = Locale('ar');

  Locale locale = english;
  bool loaded = false;

  bool get isArabic => locale.languageCode == 'ar';

  static Locale parse(String? raw) {
    final code = (raw ?? '').trim().toLowerCase();
    if (code == 'ar' || code.startsWith('ar-') || code.startsWith('ar_')) {
      return arabic;
    }
    return english;
  }

  Future<void> load() async {
    if (loaded) return;
    final prefs = await SharedPreferences.getInstance();
    locale = parse(prefs.getString(prefKey));
    loaded = true;
    notifyListeners();
  }

  Future<void> setCode(String code) async {
    final next = parse(code);
    if (next == locale && loaded) return;
    locale = next;
    loaded = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKey, next.languageCode);
  }
}
