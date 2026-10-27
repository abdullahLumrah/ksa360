// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'KSA 360';

  @override
  String get tabHome => 'Home';

  @override
  String get tabCategories => 'Categories';

  @override
  String get tabMarketplace => 'Marketplace';

  @override
  String get tabCommunity => 'Community';

  @override
  String get tabPlay => 'Play';

  @override
  String get tabProfile => 'Profile';

  @override
  String get askKsa => 'Ask KSA';

  @override
  String get seeAll => 'See all';

  @override
  String get search => 'Search';

  @override
  String get language => 'Language';

  @override
  String get languageSubtitle =>
      'English is the default. Arabic flips the app to the right.';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get splashTagline => 'ALL IN ONE · FOR EXPATS';

  @override
  String get splashCheatCode => 'Your KSA cheat code.';

  @override
  String get splashLoadError =>
      'Could not load guides. Please restart the app.';

  @override
  String get kingdomName => 'Kingdom of Saudi Arabia';

  @override
  String get homeSearchSubtitle => 'Guides, food, play, embassies';

  @override
  String get homeDailyTitle => 'Daily in KSA · Coupons & brands';

  @override
  String get homeDailySubtitle => 'Apps, shops, and offers';

  @override
  String get homeMarketplaceTitle => 'Marketplace';

  @override
  String get homeMarketplaceSubtitle =>
      'Cars, furniture and more people are listing';

  @override
  String get homeActivitiesTitle => 'Activities near me';

  @override
  String get homeActivitiesSubtitle => 'Dunes, karting, snow, cinema, malls';

  @override
  String get homeEatTitle => 'Eat nearby';

  @override
  String get homeEatSubtitle => 'Arab, Chinese, Desi and more';

  @override
  String get homeCategoriesTitle => 'Categories';

  @override
  String get homeCategoriesSubtitle =>
      'Guides grouped the way people look them up';

  @override
  String get homeClinicsTitle => 'Find clinics';

  @override
  String get homeClinicsSubtitle => 'Hospitals and clinics around you';

  @override
  String get homeStudyTitle => 'Study in Saudi Arabia';

  @override
  String get homeStudySubtitle => 'International schools near you';

  @override
  String prayerIn(String time) {
    return 'in $time';
  }

  @override
  String nextPrayer(String name) {
    return 'Next $name';
  }

  @override
  String nextPrayerIn(String name, String time) {
    return 'Next $name in $time';
  }

  @override
  String get prayerTimes => 'Prayer times';

  @override
  String get prayerFajr => 'Fajr';

  @override
  String get prayerSunrise => 'Sunrise';

  @override
  String get prayerDhuhr => 'Dhuhr';

  @override
  String get prayerAsr => 'Asr';

  @override
  String get prayerMaghrib => 'Maghrib';

  @override
  String get prayerIsha => 'Isha';

  @override
  String get ramadan => 'Ramadan';

  @override
  String get weekendFriSat => 'Weekend (Fri–Sat)';

  @override
  String get ummAlQura => 'Umm Al-Qura';

  @override
  String get useMyLocation => 'Use my location';

  @override
  String get gps => 'GPS';

  @override
  String get manual => 'Manual';

  @override
  String nearCity(String city) {
    return 'Near $city';
  }

  @override
  String outsideKsaUsing(String city) {
    return 'Outside KSA · using $city';
  }

  @override
  String get locationOff => 'Location is turned off';

  @override
  String get locationPermissionNeeded => 'Location permission needed';

  @override
  String get locationGpsFail => 'Could not read GPS';

  @override
  String countdownHours(int hours, int mins) {
    return '${hours}h ${mins}m';
  }

  @override
  String countdownMins(int mins) {
    return '${mins}m';
  }

  @override
  String get emergency => 'Emergency';

  @override
  String get login => 'Log in';

  @override
  String get createAccount => 'Create account';

  @override
  String get signOut => 'Sign out';

  @override
  String get signInToContinue => 'Sign in to continue';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get continueWithEmail => 'Continue with email';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get signInWithApple => 'Sign in with Apple';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get welcomeBackBody =>
      'Sign in to sync your profile across this phone.';

  @override
  String get createYourAccount => 'Create your account';

  @override
  String get createYourAccountBody =>
      'A light profile so we can keep your saved places with you.';

  @override
  String get authPromoteTitle => 'Log in or create an account';

  @override
  String get authPromoteBody =>
      'Save chats, community posts, and your marketplace listings on this phone.';

  @override
  String get agreePrivacyPrefix => 'I agree to the ';

  @override
  String get agreePrivacyNeeded =>
      'Please agree to the Privacy Policy to continue';

  @override
  String get agreeTermsPrefix => 'I agree to the ';

  @override
  String get agreeAnd => ' and ';

  @override
  String get agreeTermsNeeded =>
      'Please agree to the Terms of Use and Privacy Policy to continue';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get termsNoAbuse =>
      'KSA 360 has zero tolerance for objectionable content and abusive users.';

  @override
  String get blockUser => 'Block user';

  @override
  String get userBlocked =>
      'User blocked. Their content is hidden, and our team has been notified.';

  @override
  String get blockUserConfirm => 'Block this user?';

  @override
  String blockUserConfirmBody(String name) {
    return 'Hide posts, comments, and marketplace listings from $name. We will also notify the KSA 360 team.';
  }

  @override
  String get reportPost => 'Report post';

  @override
  String get reportUser => 'Report user';

  @override
  String get cancel => 'Cancel';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get name => 'Name';

  @override
  String get newHere => 'New here?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get guest => 'Guest';

  @override
  String get guestInitial => 'G';

  @override
  String get browsingKsa => 'Browsing KSA 360';

  @override
  String get guestBody =>
      'Create an account for a lighter profile — just your name when you need it.';

  @override
  String get signedInGoogle => 'Signed in with Google';

  @override
  String get signedInApple => 'Signed in with Apple';

  @override
  String get signedInEmail => 'Signed in with email';

  @override
  String get finishProfileHint =>
      'Add your mobile, date of birth, and gender to finish this profile.';

  @override
  String get manageProfile => 'Manage profile';

  @override
  String get mobile => 'Mobile';

  @override
  String get dateOfBirth => 'Date of birth';

  @override
  String get gender => 'Gender';

  @override
  String get privacyHowWeUse => 'How we use your data';

  @override
  String get loginPromptCreate => 'Create account';

  @override
  String get communityLoginTitle => 'Log in to Community';

  @override
  String get communityLoginBody =>
      'Sign in to follow pages, like and reply, and share posts with other expats.';

  @override
  String get communityTitle => 'Community';

  @override
  String get myPages => 'My pages';

  @override
  String get myPagesSubtitle => 'Pages you created';

  @override
  String get noPagesYet => 'You have not created a page yet.';

  @override
  String get createPage => 'Create page';

  @override
  String get searchPagesPosts => 'Search pages and posts';

  @override
  String get all => 'All';

  @override
  String membersCount(int count) {
    return '$count members';
  }

  @override
  String get noPostsMatch => 'No posts match that search.';

  @override
  String get noPostsYet =>
      'No posts yet. Create a page and share the first one.';

  @override
  String get postsWaitingTitle => 'Posts waiting for you';

  @override
  String get postsWaitingBody =>
      'Only you (the page owner) can approve these. They stay hidden until you accept.';

  @override
  String postsWaitingBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count posts waiting for your approval',
      one: '1 post waiting for your approval',
    );
    return '$_temp0';
  }

  @override
  String get approve => 'Approve';

  @override
  String get decline => 'Decline';

  @override
  String get like => 'Like';

  @override
  String get comment => 'Comment';

  @override
  String get join => 'Join';

  @override
  String get page => 'Page';

  @override
  String likesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count likes',
      one: '1 like',
    );
    return '$_temp0';
  }

  @override
  String commentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comments',
      one: '1 comment',
    );
    return '$_temp0';
  }

  @override
  String get topicGeneral => 'General';

  @override
  String get topicFood => 'Food';

  @override
  String get topicCulture => 'Culture';

  @override
  String get topicExpats => 'Expats';

  @override
  String get topicSports => 'Sports';

  @override
  String get topicBusiness => 'Business';

  @override
  String get topicFamily => 'Family';

  @override
  String get topicEducation => 'Education';

  @override
  String get topicFaith => 'Faith';

  @override
  String get topicNeighbourhood => 'Neighbourhood';

  @override
  String get topicOther => 'Other';

  @override
  String get jobs => 'Jobs';

  @override
  String get jobsSubtitle => 'Work in Saudi Arabia';

  @override
  String get postAJob => 'Post a job';

  @override
  String get searchJobs => 'Search jobs';

  @override
  String get anyCity => 'Any city';

  @override
  String get noJobsMatch => 'No jobs match these filters.';

  @override
  String get jobsGateBody =>
      'Sign in to browse Saudi roles, apply on the listing, or post a job for review.';

  @override
  String get featureMarketplace => 'Marketplace';

  @override
  String get featureJobs => 'Jobs';

  @override
  String get featureDaily => 'Daily in KSA';

  @override
  String get featureClinics => 'Clinics';

  @override
  String get featureStudy => 'Study here';

  @override
  String get featureEat => 'Eat nearby';

  @override
  String get featureActivities => 'Activities';

  @override
  String get featureEmergency => 'Emergency';

  @override
  String get featureGuides => 'Guides';

  @override
  String get guides => 'Guides';

  @override
  String get guidesHubBody =>
      'Posts and topics. Open a guide, or suggest one for review.';

  @override
  String get suggestAGuide => 'Suggest a guide';

  @override
  String get searchHint => 'Guides, food, play, embassies…';

  @override
  String get saved => 'Saved';

  @override
  String get playNearby => 'Nearby';

  @override
  String get playCheapest => 'Cheapest';

  @override
  String get playSaved => 'Saved';

  @override
  String spotsCount(int count) {
    return '$count spots';
  }

  @override
  String get reels => 'Reels';

  @override
  String get reelsSubtitle => 'Swipe shorts · tap to open the activity';

  @override
  String get playSearchHint => 'Movies, bowling, karting, dunes…';

  @override
  String get playAll => 'All';

  @override
  String get nearYou => 'Near you';

  @override
  String topicsCount(int count) {
    return '$count topics';
  }
}
