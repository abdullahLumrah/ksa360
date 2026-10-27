// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'KSA 360';

  @override
  String get tabHome => 'الرئيسية';

  @override
  String get tabCategories => 'الأقسام';

  @override
  String get tabMarketplace => 'السوق';

  @override
  String get tabCommunity => 'المجتمع';

  @override
  String get tabPlay => 'الترفيه';

  @override
  String get tabProfile => 'حسابي';

  @override
  String get askKsa => 'اسأل كيه إس إيه';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String get search => 'بحث';

  @override
  String get language => 'اللغة';

  @override
  String get languageSubtitle =>
      'الإنجليزية هي اللغة الافتراضية. العربية تقلب التطبيق لليمين.';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get splashTagline => 'كل شيء في مكان واحد · للمقيمين';

  @override
  String get splashCheatCode => 'دليلك السريع في السعودية.';

  @override
  String get splashLoadError => 'تعذر تحميل الأدلة. أعد تشغيل التطبيق.';

  @override
  String get kingdomName => 'المملكة العربية السعودية';

  @override
  String get homeSearchSubtitle => 'أدلة، طعام، ترفيه، سفارات';

  @override
  String get homeDailyTitle => 'يومياً في السعودية · كوبونات وعلامات';

  @override
  String get homeDailySubtitle => 'تطبيقات ومتاجر وعروض';

  @override
  String get homeMarketplaceTitle => 'السوق';

  @override
  String get homeMarketplaceSubtitle => 'سيارات وأثاث والمزيد مما يعرضه الناس';

  @override
  String get homeActivitiesTitle => 'أنشطة بالقرب مني';

  @override
  String get homeActivitiesSubtitle => 'كثبان، كارتينغ، ثلج، سينما، مولات';

  @override
  String get homeEatTitle => 'طعام قريب';

  @override
  String get homeEatSubtitle => 'عربي وصيني وهندي والمزيد';

  @override
  String get homeCategoriesTitle => 'الأقسام';

  @override
  String get homeCategoriesSubtitle => 'أدلة مرتبة كما يبحث عنها الناس';

  @override
  String get homeClinicsTitle => 'ابحث عن عيادات';

  @override
  String get homeClinicsSubtitle => 'مستشفيات وعيادات حولك';

  @override
  String get homeStudyTitle => 'الدراسة في السعودية';

  @override
  String get homeStudySubtitle => 'مدارس دولية بالقرب منك';

  @override
  String prayerIn(String time) {
    return 'بعد $time';
  }

  @override
  String nextPrayer(String name) {
    return 'الصلاة القادمة $name';
  }

  @override
  String nextPrayerIn(String name, String time) {
    return 'الصلاة القادمة $name بعد $time';
  }

  @override
  String get prayerTimes => 'أوقات الصلاة';

  @override
  String get prayerFajr => 'الفجر';

  @override
  String get prayerSunrise => 'الشروق';

  @override
  String get prayerDhuhr => 'الظهر';

  @override
  String get prayerAsr => 'العصر';

  @override
  String get prayerMaghrib => 'المغرب';

  @override
  String get prayerIsha => 'العشاء';

  @override
  String get ramadan => 'رمضان';

  @override
  String get weekendFriSat => 'عطلة الأسبوع (الجمعة–السبت)';

  @override
  String get ummAlQura => 'أم القرى';

  @override
  String get useMyLocation => 'استخدم موقعي';

  @override
  String get gps => 'GPS';

  @override
  String get manual => 'يدوي';

  @override
  String nearCity(String city) {
    return 'بالقرب من $city';
  }

  @override
  String outsideKsaUsing(String city) {
    return 'خارج السعودية · نستخدم $city';
  }

  @override
  String get locationOff => 'خدمة الموقع مغلقة';

  @override
  String get locationPermissionNeeded => 'يلزم إذن الموقع';

  @override
  String get locationGpsFail => 'تعذر قراءة الموقع';

  @override
  String countdownHours(int hours, int mins) {
    return '$hoursس $minsد';
  }

  @override
  String countdownMins(int mins) {
    return '$minsد';
  }

  @override
  String get emergency => 'طوارئ';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signInToContinue => 'سجّل الدخول للمتابعة';

  @override
  String get skipForNow => 'تخطَّ الآن';

  @override
  String get continueWithGoogle => 'المتابعة بحساب Google';

  @override
  String get continueWithApple => 'المتابعة بحساب Apple';

  @override
  String get continueWithEmail => 'المتابعة بالبريد';

  @override
  String get signInWithGoogle => 'تسجيل الدخول بـ Google';

  @override
  String get signInWithApple => 'تسجيل الدخول بـ Apple';

  @override
  String get welcomeBack => 'مرحباً بعودتك';

  @override
  String get welcomeBackBody => 'سجّل الدخول لمزامنة ملفك على هذا الهاتف.';

  @override
  String get createYourAccount => 'أنشئ حسابك';

  @override
  String get createYourAccountBody => 'ملف خفيف لنحفظ أماكنك المفضلة معك.';

  @override
  String get authPromoteTitle => 'سجّل الدخول أو أنشئ حساباً';

  @override
  String get authPromoteBody =>
      'احفظ المحادثات ومنشورات المجتمع وإعلانات السوق على هذا الهاتف.';

  @override
  String get agreePrivacyPrefix => 'أوافق على ';

  @override
  String get agreePrivacyNeeded => 'وافق على سياسة الخصوصية للمتابعة';

  @override
  String get agreeTermsPrefix => 'أوافق على ';

  @override
  String get agreeAnd => ' و';

  @override
  String get agreeTermsNeeded =>
      'وافق على شروط الاستخدام وسياسة الخصوصية للمتابعة';

  @override
  String get termsOfUse => 'شروط الاستخدام';

  @override
  String get termsNoAbuse =>
      'لا يتسامح KSA 360 مع المحتوى المسيء أو المستخدمين المسيئين.';

  @override
  String get blockUser => 'حظر المستخدم';

  @override
  String get userBlocked => 'تم حظر المستخدم. أُخفي محتواه وأُشعر فريقنا.';

  @override
  String get blockUserConfirm => 'حظر هذا المستخدم؟';

  @override
  String blockUserConfirmBody(String name) {
    return 'إخفاء منشورات وتعليقات وإعلانات $name. وسنُشعر فريق KSA 360 أيضاً.';
  }

  @override
  String get reportPost => 'الإبلاغ عن المنشور';

  @override
  String get reportUser => 'الإبلاغ عن المستخدم';

  @override
  String get cancel => 'إلغاء';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get name => 'الاسم';

  @override
  String get newHere => 'جديد هنا؟';

  @override
  String get alreadyHaveAccount => 'لديك حساب بالفعل؟';

  @override
  String get guest => 'زائر';

  @override
  String get guestInitial => 'ز';

  @override
  String get browsingKsa => 'تتصفح KSA 360';

  @override
  String get guestBody => 'أنشئ حساباً لملف أخف — اسمك فقط عندما تحتاجه.';

  @override
  String get signedInGoogle => 'تم الدخول بحساب Google';

  @override
  String get signedInApple => 'تم الدخول بحساب Apple';

  @override
  String get signedInEmail => 'تم الدخول بالبريد';

  @override
  String get finishProfileHint => 'أضف جوالك وتاريخ ميلادك وجنسك لإكمال الملف.';

  @override
  String get manageProfile => 'إدارة الحساب';

  @override
  String get mobile => 'الجوال';

  @override
  String get dateOfBirth => 'تاريخ الميلاد';

  @override
  String get gender => 'الجنس';

  @override
  String get privacyHowWeUse => 'كيف نستخدم بياناتك';

  @override
  String get loginPromptCreate => 'إنشاء حساب';

  @override
  String get communityLoginTitle => 'سجّل الدخول للمجتمع';

  @override
  String get communityLoginBody =>
      'سجّل الدخول لمتابعة الصفحات والإعجاب والرد ومشاركة المنشورات مع المقيمين.';

  @override
  String get communityTitle => 'المجتمع';

  @override
  String get myPages => 'صفحاتي';

  @override
  String get myPagesSubtitle => 'الصفحات التي أنشأتها';

  @override
  String get noPagesYet => 'لم تنشئ صفحة بعد.';

  @override
  String get createPage => 'إنشاء صفحة';

  @override
  String get searchPagesPosts => 'ابحث في الصفحات والمنشورات';

  @override
  String get all => 'الكل';

  @override
  String membersCount(int count) {
    return '$count أعضاء';
  }

  @override
  String get noPostsMatch => 'لا منشورات تطابق هذا البحث.';

  @override
  String get noPostsYet => 'لا منشورات بعد. أنشئ صفحة وشارك أول منشور.';

  @override
  String get postsWaitingTitle => 'منشورات بانتظارك';

  @override
  String get postsWaitingBody =>
      'أنت فقط (صاحب الصفحة) تستطيع الموافقة. تبقى مخفية حتى تقبلها.';

  @override
  String postsWaitingBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count منشور بانتظار موافقتك',
      many: '$count منشوراً بانتظار موافقتك',
      few: '$count منشورات بانتظار موافقتك',
      two: 'منشوران بانتظار موافقتك',
      one: 'منشور واحد بانتظار موافقتك',
      zero: 'لا منشورات بانتظار موافقتك',
    );
    return '$_temp0';
  }

  @override
  String get approve => 'قبول';

  @override
  String get decline => 'رفض';

  @override
  String get like => 'إعجاب';

  @override
  String get comment => 'تعليق';

  @override
  String get join => 'انضم';

  @override
  String get page => 'الصفحة';

  @override
  String likesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count إعجاب',
      many: '$count إعجاباً',
      few: '$count إعجابات',
      two: 'إعجابان',
      one: 'إعجاب واحد',
      zero: 'لا إعجابات',
    );
    return '$_temp0';
  }

  @override
  String commentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تعليق',
      many: '$count تعليقاً',
      few: '$count تعليقات',
      two: 'تعليقان',
      one: 'تعليق واحد',
      zero: 'لا تعليقات',
    );
    return '$_temp0';
  }

  @override
  String get topicGeneral => 'عام';

  @override
  String get topicFood => 'طعام';

  @override
  String get topicCulture => 'ثقافة';

  @override
  String get topicExpats => 'مقيمون';

  @override
  String get topicSports => 'رياضة';

  @override
  String get topicBusiness => 'أعمال';

  @override
  String get topicFamily => 'عائلة';

  @override
  String get topicEducation => 'تعليم';

  @override
  String get topicFaith => 'إيمان';

  @override
  String get topicNeighbourhood => 'الحي';

  @override
  String get topicOther => 'أخرى';

  @override
  String get jobs => 'الوظائف';

  @override
  String get jobsSubtitle => 'العمل في السعودية';

  @override
  String get postAJob => 'انشر وظيفة';

  @override
  String get searchJobs => 'ابحث عن وظائف';

  @override
  String get anyCity => 'أي مدينة';

  @override
  String get noJobsMatch => 'لا وظائف تطابق هذه التصفية.';

  @override
  String get jobsGateBody =>
      'سجّل الدخول لاستعراض الوظائف في السعودية، أو التقديم، أو نشر وظيفة للمراجعة.';

  @override
  String get featureMarketplace => 'السوق';

  @override
  String get featureJobs => 'وظائف';

  @override
  String get featureDaily => 'يومياً في السعودية';

  @override
  String get featureClinics => 'العيادات';

  @override
  String get featureStudy => 'الدراسة هنا';

  @override
  String get featureEat => 'طعام قريب';

  @override
  String get featureActivities => 'أنشطة';

  @override
  String get featureEmergency => 'طوارئ';

  @override
  String get featureGuides => 'الأدلة';

  @override
  String get guides => 'الأدلة';

  @override
  String get guidesHubBody =>
      'منشورات ومواضيع. افتح دليلاً، أو اقترح واحداً للمراجعة.';

  @override
  String get suggestAGuide => 'اقترح دليلاً';

  @override
  String get searchHint => 'أدلة، طعام، ترفيه، سفارات…';

  @override
  String get saved => 'المحفوظات';

  @override
  String get playNearby => 'بالقرب';

  @override
  String get playCheapest => 'الأرخص';

  @override
  String get playSaved => 'المحفوظ';

  @override
  String spotsCount(int count) {
    return '$count أماكن';
  }

  @override
  String get reels => 'ريلز';

  @override
  String get reelsSubtitle => 'اسحب المقاطع القصيرة · اضغط لفتح النشاط';

  @override
  String get playSearchHint => 'أفلام، بولينغ، كارتينغ، كثبان…';

  @override
  String get playAll => 'الكل';

  @override
  String get nearYou => 'بالقرب منك';

  @override
  String topicsCount(int count) {
    return '$count مواضيع';
  }
}
