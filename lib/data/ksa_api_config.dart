import 'ksa_api_secret.dart';

/// AnythingLLM running on this Mac (Ollama, workspace `my-workspace`).
///
/// A USB phone reaches it through `adb reverse tcp:3001 tcp:3001`.
/// For Wi-Fi without USB, run:
/// flutter run --dart-define=KSA_API_BASE=https://your-host.trycloudflare.com
class KsaApiConfig {
  static const workspaceOverride = String.fromEnvironment('KSA_API_WORKSPACE');
  static const keyOverride = String.fromEnvironment('KSA_API_KEY');
  static const baseOverride = String.fromEnvironment('KSA_API_BASE');

  static const workspaceDefault = 'my-workspace';

  static String get workspace =>
      workspaceOverride.isNotEmpty ? workspaceOverride : workspaceDefault;

  static String get apiKey =>
      keyOverride.isNotEmpty ? keyOverride : KsaApiSecret.key;

  static String get baseUrl {
    if (baseOverride.isNotEmpty) {
      return baseOverride.replaceAll(RegExp(r'/+$'), '');
    }
    // Physical Android uses 127.0.0.1 through `adb reverse tcp:3001 tcp:3001`.
    // The emulator would need http://10.0.2.2:3001 instead.
    return 'http://127.0.0.1:3001';
  }
}
