import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'KSA 360'**
  String get appTitle;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get tabCategories;

  /// No description provided for @tabMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get tabMarketplace;

  /// No description provided for @tabCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get tabCommunity;

  /// No description provided for @tabPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get tabPlay;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// No description provided for @askKsa.
  ///
  /// In en, this message translates to:
  /// **'Ask KSA'**
  String get askKsa;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'English is the default. Arabic flips the app to the right.'**
  String get languageSubtitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'ALL IN ONE · FOR EXPATS'**
  String get splashTagline;

  /// No description provided for @splashCheatCode.
  ///
  /// In en, this message translates to:
  /// **'Your KSA cheat code.'**
  String get splashCheatCode;

  /// No description provided for @splashLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load guides. Please restart the app.'**
  String get splashLoadError;

  /// No description provided for @kingdomName.
  ///
  /// In en, this message translates to:
  /// **'Kingdom of Saudi Arabia'**
  String get kingdomName;

  /// No description provided for @homeSearchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Guides, food, play, embassies'**
  String get homeSearchSubtitle;

  /// No description provided for @homeDailyTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily in KSA · Coupons & brands'**
  String get homeDailyTitle;

  /// No description provided for @homeDailySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Apps, shops, and offers'**
  String get homeDailySubtitle;

  /// No description provided for @homeMarketplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get homeMarketplaceTitle;

  /// No description provided for @homeMarketplaceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cars, furniture and more people are listing'**
  String get homeMarketplaceSubtitle;

  /// No description provided for @homeActivitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Activities near me'**
  String get homeActivitiesTitle;

  /// No description provided for @homeActivitiesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Dunes, karting, snow, cinema, malls'**
  String get homeActivitiesSubtitle;

  /// No description provided for @homeEatTitle.
  ///
  /// In en, this message translates to:
  /// **'Eat nearby'**
  String get homeEatTitle;

  /// No description provided for @homeEatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Arab, Chinese, Desi and more'**
  String get homeEatSubtitle;

  /// No description provided for @homeCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get homeCategoriesTitle;

  /// No description provided for @homeCategoriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Guides grouped the way people look them up'**
  String get homeCategoriesSubtitle;

  /// No description provided for @homeClinicsTitle.
  ///
  /// In en, this message translates to:
  /// **'Find clinics'**
  String get homeClinicsTitle;

  /// No description provided for @homeClinicsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hospitals and clinics around you'**
  String get homeClinicsSubtitle;

  /// No description provided for @homeStudyTitle.
  ///
  /// In en, this message translates to:
  /// **'Study in Saudi Arabia'**
  String get homeStudyTitle;

  /// No description provided for @homeStudySubtitle.
  ///
  /// In en, this message translates to:
  /// **'International schools near you'**
  String get homeStudySubtitle;

  /// No description provided for @prayerIn.
  ///
  /// In en, this message translates to:
  /// **'in {time}'**
  String prayerIn(String time);

  /// No description provided for @nextPrayer.
  ///
  /// In en, this message translates to:
  /// **'Next {name}'**
  String nextPrayer(String name);

  /// No description provided for @nextPrayerIn.
  ///
  /// In en, this message translates to:
  /// **'Next {name} in {time}'**
  String nextPrayerIn(String name, String time);

  /// No description provided for @prayerTimes.
  ///
  /// In en, this message translates to:
  /// **'Prayer times'**
  String get prayerTimes;

  /// No description provided for @prayerFajr.
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get prayerFajr;

  /// No description provided for @prayerSunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get prayerSunrise;

  /// No description provided for @prayerDhuhr.
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get prayerDhuhr;

  /// No description provided for @prayerAsr.
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get prayerAsr;

  /// No description provided for @prayerMaghrib.
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get prayerMaghrib;

  /// No description provided for @prayerIsha.
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get prayerIsha;

  /// No description provided for @ramadan.
  ///
  /// In en, this message translates to:
  /// **'Ramadan'**
  String get ramadan;

  /// No description provided for @weekendFriSat.
  ///
  /// In en, this message translates to:
  /// **'Weekend (Fri–Sat)'**
  String get weekendFriSat;

  /// No description provided for @ummAlQura.
  ///
  /// In en, this message translates to:
  /// **'Umm Al-Qura'**
  String get ummAlQura;

  /// No description provided for @useMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get useMyLocation;

  /// No description provided for @gps.
  ///
  /// In en, this message translates to:
  /// **'GPS'**
  String get gps;

  /// No description provided for @manual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manual;

  /// No description provided for @nearCity.
  ///
  /// In en, this message translates to:
  /// **'Near {city}'**
  String nearCity(String city);

  /// No description provided for @outsideKsaUsing.
  ///
  /// In en, this message translates to:
  /// **'Outside KSA · using {city}'**
  String outsideKsaUsing(String city);

  /// No description provided for @locationOff.
  ///
  /// In en, this message translates to:
  /// **'Location is turned off'**
  String get locationOff;

  /// No description provided for @locationPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Location permission needed'**
  String get locationPermissionNeeded;

  /// No description provided for @locationGpsFail.
  ///
  /// In en, this message translates to:
  /// **'Could not read GPS'**
  String get locationGpsFail;

  /// No description provided for @countdownHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {mins}m'**
  String countdownHours(int hours, int mins);

  /// No description provided for @countdownMins.
  ///
  /// In en, this message translates to:
  /// **'{mins}m'**
  String countdownMins(int mins);

  /// No description provided for @emergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get emergency;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get login;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInToContinue;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @continueWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with email'**
  String get continueWithEmail;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @signInWithApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get signInWithApple;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @welcomeBackBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync your profile across this phone.'**
  String get welcomeBackBody;

  /// No description provided for @createYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createYourAccount;

  /// No description provided for @createYourAccountBody.
  ///
  /// In en, this message translates to:
  /// **'A light profile so we can keep your saved places with you.'**
  String get createYourAccountBody;

  /// No description provided for @authPromoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Log in or create an account'**
  String get authPromoteTitle;

  /// No description provided for @authPromoteBody.
  ///
  /// In en, this message translates to:
  /// **'Save chats, community posts, and your marketplace listings on this phone.'**
  String get authPromoteBody;

  /// No description provided for @agreePrivacyPrefix.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get agreePrivacyPrefix;

  /// No description provided for @agreePrivacyNeeded.
  ///
  /// In en, this message translates to:
  /// **'Please agree to the Privacy Policy to continue'**
  String get agreePrivacyNeeded;

  /// No description provided for @agreeTermsPrefix.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get agreeTermsPrefix;

  /// No description provided for @agreeAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get agreeAnd;

  /// No description provided for @agreeTermsNeeded.
  ///
  /// In en, this message translates to:
  /// **'Please agree to the Terms of Use and Privacy Policy to continue'**
  String get agreeTermsNeeded;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @termsNoAbuse.
  ///
  /// In en, this message translates to:
  /// **'KSA 360 has zero tolerance for objectionable content and abusive users.'**
  String get termsNoAbuse;

  /// No description provided for @blockUser.
  ///
  /// In en, this message translates to:
  /// **'Block user'**
  String get blockUser;

  /// No description provided for @userBlocked.
  ///
  /// In en, this message translates to:
  /// **'User blocked. Their content is hidden, and our team has been notified.'**
  String get userBlocked;

  /// No description provided for @blockUserConfirm.
  ///
  /// In en, this message translates to:
  /// **'Block this user?'**
  String get blockUserConfirm;

  /// No description provided for @blockUserConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Hide posts, comments, and marketplace listings from {name}. We will also notify the KSA 360 team.'**
  String blockUserConfirmBody(String name);

  /// No description provided for @reportPost.
  ///
  /// In en, this message translates to:
  /// **'Report post'**
  String get reportPost;

  /// No description provided for @reportUser.
  ///
  /// In en, this message translates to:
  /// **'Report user'**
  String get reportUser;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @newHere.
  ///
  /// In en, this message translates to:
  /// **'New here?'**
  String get newHere;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @guestInitial.
  ///
  /// In en, this message translates to:
  /// **'G'**
  String get guestInitial;

  /// No description provided for @browsingKsa.
  ///
  /// In en, this message translates to:
  /// **'Browsing KSA 360'**
  String get browsingKsa;

  /// No description provided for @guestBody.
  ///
  /// In en, this message translates to:
  /// **'Create an account for a lighter profile — just your name when you need it.'**
  String get guestBody;

  /// No description provided for @signedInGoogle.
  ///
  /// In en, this message translates to:
  /// **'Signed in with Google'**
  String get signedInGoogle;

  /// No description provided for @signedInApple.
  ///
  /// In en, this message translates to:
  /// **'Signed in with Apple'**
  String get signedInApple;

  /// No description provided for @signedInEmail.
  ///
  /// In en, this message translates to:
  /// **'Signed in with email'**
  String get signedInEmail;

  /// No description provided for @finishProfileHint.
  ///
  /// In en, this message translates to:
  /// **'Add your mobile, date of birth, and gender to finish this profile.'**
  String get finishProfileHint;

  /// No description provided for @manageProfile.
  ///
  /// In en, this message translates to:
  /// **'Manage profile'**
  String get manageProfile;

  /// No description provided for @mobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get mobile;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get dateOfBirth;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @privacyHowWeUse.
  ///
  /// In en, this message translates to:
  /// **'How we use your data'**
  String get privacyHowWeUse;

  /// No description provided for @loginPromptCreate.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get loginPromptCreate;

  /// No description provided for @communityLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to Community'**
  String get communityLoginTitle;

  /// No description provided for @communityLoginBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to follow pages, like and reply, and share posts with other expats.'**
  String get communityLoginBody;

  /// No description provided for @communityTitle.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get communityTitle;

  /// No description provided for @myPages.
  ///
  /// In en, this message translates to:
  /// **'My pages'**
  String get myPages;

  /// No description provided for @myPagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pages you created'**
  String get myPagesSubtitle;

  /// No description provided for @noPagesYet.
  ///
  /// In en, this message translates to:
  /// **'You have not created a page yet.'**
  String get noPagesYet;

  /// No description provided for @createPage.
  ///
  /// In en, this message translates to:
  /// **'Create page'**
  String get createPage;

  /// No description provided for @searchPagesPosts.
  ///
  /// In en, this message translates to:
  /// **'Search pages and posts'**
  String get searchPagesPosts;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @membersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String membersCount(int count);

  /// No description provided for @noPostsMatch.
  ///
  /// In en, this message translates to:
  /// **'No posts match that search.'**
  String get noPostsMatch;

  /// No description provided for @noPostsYet.
  ///
  /// In en, this message translates to:
  /// **'No posts yet. Create a page and share the first one.'**
  String get noPostsYet;

  /// No description provided for @postsWaitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Posts waiting for you'**
  String get postsWaitingTitle;

  /// No description provided for @postsWaitingBody.
  ///
  /// In en, this message translates to:
  /// **'Only you (the page owner) can approve these. They stay hidden until you accept.'**
  String get postsWaitingBody;

  /// No description provided for @postsWaitingBanner.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 post waiting for your approval} other{{count} posts waiting for your approval}}'**
  String postsWaitingBanner(int count);

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @comment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @page.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get page;

  /// No description provided for @likesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 like} other{{count} likes}}'**
  String likesCount(int count);

  /// No description provided for @commentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 comment} other{{count} comments}}'**
  String commentsCount(int count);

  /// No description provided for @topicGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get topicGeneral;

  /// No description provided for @topicFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get topicFood;

  /// No description provided for @topicCulture.
  ///
  /// In en, this message translates to:
  /// **'Culture'**
  String get topicCulture;

  /// No description provided for @topicExpats.
  ///
  /// In en, this message translates to:
  /// **'Expats'**
  String get topicExpats;

  /// No description provided for @topicSports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get topicSports;

  /// No description provided for @topicBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get topicBusiness;

  /// No description provided for @topicFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get topicFamily;

  /// No description provided for @topicEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get topicEducation;

  /// No description provided for @topicFaith.
  ///
  /// In en, this message translates to:
  /// **'Faith'**
  String get topicFaith;

  /// No description provided for @topicNeighbourhood.
  ///
  /// In en, this message translates to:
  /// **'Neighbourhood'**
  String get topicNeighbourhood;

  /// No description provided for @topicOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get topicOther;

  /// No description provided for @jobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get jobs;

  /// No description provided for @jobsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Work in Saudi Arabia'**
  String get jobsSubtitle;

  /// No description provided for @postAJob.
  ///
  /// In en, this message translates to:
  /// **'Post a job'**
  String get postAJob;

  /// No description provided for @searchJobs.
  ///
  /// In en, this message translates to:
  /// **'Search jobs'**
  String get searchJobs;

  /// No description provided for @anyCity.
  ///
  /// In en, this message translates to:
  /// **'Any city'**
  String get anyCity;

  /// No description provided for @noJobsMatch.
  ///
  /// In en, this message translates to:
  /// **'No jobs match these filters.'**
  String get noJobsMatch;

  /// No description provided for @jobsGateBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to browse Saudi roles, apply on the listing, or post a job for review.'**
  String get jobsGateBody;

  /// No description provided for @featureMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get featureMarketplace;

  /// No description provided for @featureJobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get featureJobs;

  /// No description provided for @featureDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily in KSA'**
  String get featureDaily;

  /// No description provided for @featureClinics.
  ///
  /// In en, this message translates to:
  /// **'Clinics'**
  String get featureClinics;

  /// No description provided for @featureStudy.
  ///
  /// In en, this message translates to:
  /// **'Study here'**
  String get featureStudy;

  /// No description provided for @featureEat.
  ///
  /// In en, this message translates to:
  /// **'Eat nearby'**
  String get featureEat;

  /// No description provided for @featureActivities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get featureActivities;

  /// No description provided for @featureEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get featureEmergency;

  /// No description provided for @featureGuides.
  ///
  /// In en, this message translates to:
  /// **'Guides'**
  String get featureGuides;

  /// No description provided for @guides.
  ///
  /// In en, this message translates to:
  /// **'Guides'**
  String get guides;

  /// No description provided for @guidesHubBody.
  ///
  /// In en, this message translates to:
  /// **'Posts and topics. Open a guide, or suggest one for review.'**
  String get guidesHubBody;

  /// No description provided for @suggestAGuide.
  ///
  /// In en, this message translates to:
  /// **'Suggest a guide'**
  String get suggestAGuide;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Guides, food, play, embassies…'**
  String get searchHint;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @playNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get playNearby;

  /// No description provided for @playCheapest.
  ///
  /// In en, this message translates to:
  /// **'Cheapest'**
  String get playCheapest;

  /// No description provided for @playSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get playSaved;

  /// No description provided for @spotsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} spots'**
  String spotsCount(int count);

  /// No description provided for @reels.
  ///
  /// In en, this message translates to:
  /// **'Reels'**
  String get reels;

  /// No description provided for @reelsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Swipe shorts · tap to open the activity'**
  String get reelsSubtitle;

  /// No description provided for @playSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Movies, bowling, karting, dunes…'**
  String get playSearchHint;

  /// No description provided for @playAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get playAll;

  /// No description provided for @nearYou.
  ///
  /// In en, this message translates to:
  /// **'Near you'**
  String get nearYou;

  /// No description provided for @topicsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} topics'**
  String topicsCount(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
