import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'saudi_cities.dart';

enum Lifestyle { family, bachelor }

class LifeSettings extends ChangeNotifier {
  LifeSettings._();
  static final LifeSettings instance = LifeSettings._();

  static const _cityKey = 'life_city_id';
  static const _gpsKey = 'life_use_gps';
  static const _modeKey = 'life_lifestyle';
  static const _currencyKey = 'life_home_currency';
  static const _nationKey = 'life_nationality';

  bool loaded = false;
  bool useGps = true;
  String cityId = SaudiCities.riyadh.id;
  double? gpsLat;
  double? gpsLng;
  Lifestyle lifestyle = Lifestyle.family;
  String homeCurrency = 'PKR';
  String nationality = 'pakistan';
  String? locationError;

  SaudiCity get city => SaudiCities.byId(cityId);

  double get prayerLat =>
      useGps && gpsLat != null ? gpsLat! : city.lat;

  double get prayerLng =>
      useGps && gpsLng != null ? gpsLng! : city.lng;

  String get locationLabel {
    if (useGps && gpsLat != null && gpsLng != null) {
      if (SaudiCities.insideKingdom(gpsLat!, gpsLng!)) {
        final near = SaudiCities.nearest(gpsLat!, gpsLng!);
        return 'Near ${near.name}';
      }
      return 'Outside KSA · using ${city.name}';
    }
    return city.name;
  }

  Future<void> load() async {
    if (loaded) return;
    final prefs = await SharedPreferences.getInstance();
    cityId = prefs.getString(_cityKey) ?? SaudiCities.riyadh.id;
    useGps = prefs.getBool(_gpsKey) ?? true;
    homeCurrency = prefs.getString(_currencyKey) ?? 'PKR';
    nationality = prefs.getString(_nationKey) ?? 'pakistan';
    lifestyle = prefs.getString(_modeKey) == 'bachelor'
        ? Lifestyle.bachelor
        : Lifestyle.family;
    loaded = true;
    notifyListeners();
  }

  Future<void> refreshGps({bool request = true}) async {
    locationError = null;
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        locationError = 'Location is turned off';
        notifyListeners();
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && request) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        locationError = 'Location permission needed';
        notifyListeners();
        return;
      }
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        gpsLat = last.latitude;
        gpsLng = last.longitude;
        useGps = true;
        if (SaudiCities.insideKingdom(last.latitude, last.longitude)) {
          cityId = SaudiCities.nearest(last.latitude, last.longitude).id;
        }
        notifyListeners();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      gpsLat = pos.latitude;
      gpsLng = pos.longitude;
      useGps = true;
      if (SaudiCities.insideKingdom(pos.latitude, pos.longitude)) {
        cityId = SaudiCities.nearest(pos.latitude, pos.longitude).id;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cityKey, cityId);
      }
    } catch (_) {
      if (gpsLat == null) {
        locationError = 'Could not read GPS';
      }
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_gpsKey, useGps);
  }

  Future<void> selectCity(String id) async {
    cityId = id;
    useGps = false;
    gpsLat = null;
    gpsLng = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cityKey, id);
    await prefs.setBool(_gpsKey, false);
  }

  Future<void> setLifestyle(Lifestyle value) async {
    lifestyle = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _modeKey,
      value == Lifestyle.bachelor ? 'bachelor' : 'family',
    );
  }

  Future<void> setHomeCurrency(String code) async {
    homeCurrency = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, code);
  }

  Future<void> setNationality(String id) async {
    nationality = id;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nationKey, id);
  }
}
