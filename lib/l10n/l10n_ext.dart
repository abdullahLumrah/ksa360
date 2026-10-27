import '../data/prayer_service.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

extension AppL10nLookups on AppLocalizations {
  String prayer(String key) {
    switch (key) {
      case 'Fajr':
        return prayerFajr;
      case 'Sunrise':
        return prayerSunrise;
      case 'Dhuhr':
        return prayerDhuhr;
      case 'Asr':
        return prayerAsr;
      case 'Maghrib':
        return prayerMaghrib;
      case 'Isha':
        return prayerIsha;
      default:
        return key;
    }
  }

  String topic(String name) {
    switch (name) {
      case 'General':
        return topicGeneral;
      case 'Food':
        return topicFood;
      case 'Culture':
        return topicCulture;
      case 'Expats':
        return topicExpats;
      case 'Sports':
        return topicSports;
      case 'Business':
        return topicBusiness;
      case 'Family':
        return topicFamily;
      case 'Education':
        return topicEducation;
      case 'Faith':
        return topicFaith;
      case 'Neighbourhood':
        return topicNeighbourhood;
      case 'Other':
        return topicOther;
      default:
        return name;
    }
  }

  String countdown(DateTime next) {
    final now = PrayerService.ksaNow();
    var diff = next.difference(now);
    if (diff.isNegative) diff = Duration.zero;
    final hours = diff.inHours;
    final mins = diff.inMinutes.remainder(60);
    if (hours <= 0) return countdownMins(mins);
    return countdownHours(hours, mins);
  }
}
