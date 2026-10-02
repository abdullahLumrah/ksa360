import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import 'app_api.dart';

class AuthSession extends ChangeNotifier {
  AuthSession._();
  static final AuthSession instance = AuthSession._();

  static const _prefSignedIn = 'auth.signed_in';
  static const _secureToken = 'auth.jwt';
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );
  static const _nativeGoogle = MethodChannel('ksa360/google_sign_in');

  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  AppUser? user;
  String? token;
  bool loaded = false;
  bool busy = false;
  String? error;

  bool get isSignedIn => user != null && (token?.isNotEmpty ?? false);

  Future<void> load() async {
    if (loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final markedIn = prefs.getBool(_prefSignedIn) ?? false;
    token = await _secure.read(key: _secureToken);
    if (token != null && token!.isNotEmpty && markedIn) {
      try {
        user = await _me();
      } catch (_) {
        await clearLocal();
      }
    } else {
      await clearLocal(notify: false);
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required String dateOfBirth,
    required String gender,
  }) {
    return _authPost('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      'confirmPassword': confirmPassword,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
    });
  }

  Future<void> login({required String email, required String password}) {
    return _authPost('/auth/login', {'email': email, 'password': password});
  }

  Future<String> _googleWebClientId() async {
    if (googleServerClientId.isNotEmpty) return googleServerClientId;
    try {
      final res = await AppApi.get(AppApi.uri('/auth/google-config'));
      if (res.statusCode == 200) {
        final map = jsonDecode(res.body) as Map<String, dynamic>;
        final id = (map['clientId'] as String?)?.trim() ?? '';
        if (id.isNotEmpty) return id;
      }
    } catch (_) {}
    throw Exception(
      'Google sign-in is not set up yet. Create a Web OAuth client in Google Cloud and add GOOGLE_CLIENT_ID to the backend .env.',
    );
  }

  Future<void> loginWithGoogle() async {
    try {
      final clientId = await _googleWebClientId();
      final tokens = Platform.isAndroid
          ? await _nativeGoogleTokens(clientId)
          : await _pluginGoogleTokens(clientId);
      if (tokens == null) return;
      await _authPost('/auth/google', {
        'idToken': tokens.idToken,
        if (tokens.accessToken.isNotEmpty) 'accessToken': tokens.accessToken,
      });
    } catch (e) {
      throw Exception(_googleError(e));
    }
  }

  Future<({String idToken, String accessToken})?> _nativeGoogleTokens(
    String clientId,
  ) async {
    try {
      final raw = await _nativeGoogle.invokeMethod('signIn', {
        'serverClientId': clientId,
      });
      if (raw == null) return null;
      if (raw is String) {
        if (raw.isEmpty) return null;
        return (idToken: raw, accessToken: '');
      }
      final map = Map<String, dynamic>.from(raw as Map);
      final idToken = (map['idToken'] as String?)?.trim() ?? '';
      if (idToken.isEmpty) return null;
      return (
        idToken: idToken,
        accessToken: (map['accessToken'] as String?)?.trim() ?? '',
      );
    } on MissingPluginException {
      return _pluginGoogleTokens(clientId);
    }
  }

  Future<({String idToken, String accessToken})?> _pluginGoogleTokens(
    String clientId,
  ) async {
    final google = GoogleSignIn(
      scopes: const [
        'email',
        'profile',
        'https://www.googleapis.com/auth/user.birthday.read',
        'https://www.googleapis.com/auth/user.gender.read',
      ],
      serverClientId: clientId,
    );
    final account = await google.signIn();
    if (account == null) return null;
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Google did not return a sign-in token');
    }
    return (idToken: idToken, accessToken: auth.accessToken ?? '');
  }

  Future<void> updateProfile({
    required String name,
    required String dateOfBirth,
    required String gender,
  }) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final res = await AppApi.patch(
        AppApi.uri('/auth/me'),
        body: jsonEncode({
          'name': name,
          'dateOfBirth': dateOfBirth,
          'gender': gender,
        }),
      );
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode >= 400) {
        throw Exception(map['error'] as String? ?? 'Could not save profile');
      }
      user = AppUser.fromJson(map);
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  static String _googleError(Object e) {
    final raw = e.toString();
    if (raw.contains('google_10') || raw.contains('ApiException: 10')) {
      return 'Google rejected the Android client. Confirm package com.ksaguide.ksa360 and SHA-1 D6:4E:44:D0:0B:C4:13:1C:8D:D7:62:1B:08:B7:97:2D:31:13:5E:D8, and add this Gmail as a test user.';
    }
    if (raw.contains('google_7') || raw.contains('NETWORK_ERROR')) {
      return 'Google sign-in needs a network connection.';
    }
    if (raw.contains('google_12500') || raw.contains('ApiException: 12500')) {
      return 'This Google account is blocked until you add it as a test user or publish the consent screen.';
    }
    return raw
        .replaceFirst('Exception: ', '')
        .replaceFirst(RegExp(r'PlatformException\([^)]*\)'), 'Google sign-in failed');
  }

  Future<void> signOut() async {
    try {
      if (token != null) {
        await AppApi.post(AppApi.uri('/auth/logout'));
      }
    } catch (_) {}
    try {
      if (Platform.isAndroid) {
        await _nativeGoogle.invokeMethod<bool>('signOut', {
          'serverClientId': await _googleWebClientId(),
        });
      } else {
        await GoogleSignIn().signOut();
      }
    } catch (_) {}
    await clearLocal();
  }

  Future<void> clearLocal({bool notify = true}) async {
    user = null;
    token = null;
    error = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefSignedIn);
    await prefs.remove('auth_token');
    await _secure.delete(key: _secureToken);
    if (notify && loaded) notifyListeners();
  }

  Future<void> _authPost(String path, Map<String, String> body) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final res = await AppApi.post(
        AppApi.uri(path),
        body: jsonEncode(body),
      );
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode >= 400) {
        throw Exception(map['error'] as String? ?? 'Could not continue');
      }
      final nextToken = map['token'] as String?;
      if (nextToken == null || nextToken.isEmpty) {
        throw Exception('Sign-in did not return a session');
      }
      token = nextToken;
      user = AppUser.fromJson(map['user'] as Map<String, dynamic>);
      await _secure.write(key: _secureToken, value: nextToken);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefSignedIn, true);
      await prefs.remove('auth_token');
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<AppUser> _me() async {
    final res = await AppApi.get(AppApi.uri('/auth/me'));
    if (res.statusCode != 200) {
      throw Exception('Session expired');
    }
    return AppUser.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
