import 'package:adhan/adhan.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

class DayPrayers {
  const DayPrayers({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.nextName,
    required this.nextTime,
    required this.hijri,
    required this.isRamadan,
    required this.isWeekend,
    required this.gregorian,
  });

  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final String nextName;
  final DateTime nextTime;
  final String hijri;
  final bool isRamadan;
  final bool isWeekend;
  final DateTime gregorian;

  List<MapEntry<String, DateTime>> get slots => [
        MapEntry('Fajr', fajr),
        MapEntry('Sunrise', sunrise),
        MapEntry('Dhuhr', dhuhr),
        MapEntry('Asr', asr),
        MapEntry('Maghrib', maghrib),
        MapEntry('Isha', isha),
      ];
}

class PrayerService {
  static const _ksaOffset = Duration(hours: 3);

  static DateTime ksaNow() => DateTime.now().toUtc().add(_ksaOffset);

  static DayPrayers forLocation(double lat, double lng) {
    final now = ksaNow();
    final coords = Coordinates(lat, lng);
    final params = CalculationMethod.umm_al_qura.getParameters();
    final times = PrayerTimes(
      coords,
      DateComponents.from(now),
      params,
      utcOffset: _ksaOffset,
    );

    final hijri = HijriCalendar.fromDate(now);
    final next = times.nextPrayerByDateTime(now);
    var nextName = _label(next);
    var nextTime = times.timeForPrayer(next);
    if (next == Prayer.none || nextTime == null) {
      nextName = 'Fajr';
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowTimes = PrayerTimes(
        coords,
        DateComponents.from(tomorrow),
        params,
        utcOffset: _ksaOffset,
      );
      nextTime = tomorrowTimes.fajr;
    }

    return DayPrayers(
      fajr: times.fajr,
      sunrise: times.sunrise,
      dhuhr: times.dhuhr,
      asr: times.asr,
      maghrib: times.maghrib,
      isha: times.isha,
      nextName: nextName,
      nextTime: nextTime,
      hijri: hijri.toFormat('dd MMMM yyyy'),
      isRamadan: hijri.hMonth == 9,
      isWeekend: now.weekday == DateTime.friday || now.weekday == DateTime.saturday,
      gregorian: now,
    );
  }

  static String formatTime(DateTime time) => DateFormat.jm().format(time);

  static String countdown(DateTime next) {
    final now = ksaNow();
    var diff = next.difference(now);
    if (diff.isNegative) diff = Duration.zero;
    final hours = diff.inHours;
    final mins = diff.inMinutes.remainder(60);
    if (hours <= 0) return '${mins}m';
    return '${hours}h ${mins}m';
  }

  static String _label(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 'Fajr';
      case Prayer.sunrise:
        return 'Sunrise';
      case Prayer.dhuhr:
        return 'Dhuhr';
      case Prayer.asr:
        return 'Asr';
      case Prayer.maghrib:
        return 'Maghrib';
      case Prayer.isha:
        return 'Isha';
      case Prayer.none:
        return 'Fajr';
    }
  }
}
