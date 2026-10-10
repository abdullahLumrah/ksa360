/// Live API. Override only when you need the Mac backend:
/// flutter run --dart-define=APP_API_BASE=http://127.0.0.1:4000
class AppApiConfig {
  static const baseOverride = String.fromEnvironment('APP_API_BASE');

  static String get baseUrl {
    if (baseOverride.isNotEmpty) {
      return baseOverride.replaceAll(RegExp(r'/+$'), '');
    }
    return 'https://api.lumrah.co';
  }

  /// Turns `/uploads/...` into a full API URL. Leaves http(s) links alone.
  static String mediaUrl(String path) {
    final value = path.trim();
    if (value.isEmpty) return '';
    if (value.startsWith('http://') || value.startsWith('https://')) return value;
    if (value.startsWith('/uploads/')) return '$baseUrl$value';
    return value;
  }
}
