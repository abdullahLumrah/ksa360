/// Local Express API in the sibling `ksa-guide-backend` package.
///
/// A USB Android phone reaches it through `adb reverse tcp:4000 tcp:4000`.
/// A physical iPhone needs the Mac LAN IP:
/// flutter run --dart-define=APP_API_BASE=http://192.168.x.x:4000
class AppApiConfig {
  static const baseOverride = String.fromEnvironment('APP_API_BASE');

  static String get baseUrl {
    if (baseOverride.isNotEmpty) {
      return baseOverride.replaceAll(RegExp(r'/+$'), '');
    }
    return 'http://127.0.0.1:4000';
  }
}
