import 'package:flutter/widgets.dart';

class SouqL10n {
  SouqL10n(this.ar);
  final bool ar;

  factory SouqL10n.of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return SouqL10n(code == 'ar');
  }

  String get souq => ar ? 'السوق' : 'Souq';
  String get greeting => ar ? 'بيع واشترِ بالقرب منك' : 'Buy and sell nearby';
  String get searchHint => ar ? 'ابحث في السوق' : 'Search Souq';
  String get featured => ar ? 'سيارات مميزة' : 'Featured cars';
  String get recent => ar ? 'أضيف حديثاً' : 'Recently added';
  String get nearYou => ar ? 'بالقرب منك' : 'Near you';
  String get sell => ar ? 'بيع' : 'Sell';
  String get placeAd => ar ? 'ضع إعلاناً' : 'Place an ad';
  String get categories => ar ? 'الأقسام' : 'Categories';
  String get categoriesSub =>
      ar ? 'تصفح حسب النوع' : 'Browse by what you need';
  String get featuredSub => ar ? 'من حراج' : 'From Haraj';
  String get recentSub =>
      ar ? 'أحدث الإعلانات في السوق' : 'Fresh listings across Souq';
  String get browseCars => ar ? 'تصفح السيارات' : 'Browse cars';
  String get filters => ar ? 'تصفية' : 'Filters';
  String get sort => ar ? 'ترتيب' : 'Sort';
  String get favorites => ar ? 'المفضلة' : 'Favorites';
  String get myAds => ar ? 'إعلاناتي' : 'My ads';
  String get chats => ar ? 'الدردشات' : 'Chats';
  String get signInToChat =>
      ar ? 'سجّل الدخول للمحادثة' : 'Sign in to chat';
  String get onlyOwnerReplies =>
      ar ? 'صاحب الإعلان فقط يرد' : 'Only the seller can reply';
  String get inquiries => ar ? 'الاستفسارات' : 'Inquiries';
  String get bestOffer => ar ? 'على السوم' : 'Best offer';
  String get negotiable => ar ? 'قابل للتفاوض' : 'Negotiable';
  String get haraj => 'Haraj';
  String get expatriates => 'Expat';
  String get featuredBadge => ar ? 'مميز' : 'Featured';
  String get sold => ar ? 'تم البيع' : 'Sold';
  String get call => ar ? 'اتصال' : 'Call';
  String get whatsapp => 'WhatsApp';
  String get chat => ar ? 'محادثة' : 'Chat';
  String get share => ar ? 'مشاركة' : 'Share';
  String get report => ar ? 'إبلاغ' : 'Report';
  String get viewOriginal => ar ? 'عرض الإعلان على حراج' : 'View original on Haraj';
  String get viewOriginalExpat =>
      ar ? 'عرض الإعلان على expatriates.com' : 'View original on expatriates.com';
  String get safety => ar ? 'نصائح الأمان' : 'Safety tips';
  String get safetyBody => ar
      ? 'التقوا في مكان عام، افحصوا السلعة قبل الدفع، ولا تحولوا مالاً مقدماً.'
      : 'Meet in public, inspect before paying, and never transfer money in advance.';
  String get emptyCat => ar ? 'كن أول من يبيع هنا' : 'Be the first to sell here';
  String get postAd => ar ? 'أضف إعلاناً' : 'Post an ad';
  String get showResults => ar ? 'عرض النتائج' : 'Show results';
  String get reset => ar ? 'إعادة ضبط' : 'Reset';
  String get saveSearch => ar ? 'حفظ البحث' : 'Save search';
  String get next => ar ? 'التالي' : 'Next';
  String get back => ar ? 'رجوع' : 'Back';
  String get publish => ar ? 'نشر' : 'Publish';
  String get draftBanner => ar ? 'متابعة المسودة؟' : 'Continue your draft?';
  String get photos => ar ? 'الصور' : 'Photos';
  String get details => ar ? 'التفاصيل' : 'Details';
  String get price => ar ? 'السعر' : 'Price';
  String get location => ar ? 'الموقع' : 'Location';
  String get review => ar ? 'مراجعة' : 'Review';
  String get chooseCategory => ar ? 'اختر القسم' : 'Choose category';
  String get cover => ar ? 'الغلاف' : 'Cover';
  String get free => ar ? 'مجاناً' : 'Free / giveaway';
  String get active => ar ? 'نشط' : 'Active';
  String get drafts => ar ? 'مسودات' : 'Drafts';
  String get expired => ar ? 'منتهي' : 'Expired';
  String get paused => ar ? 'متوقف' : 'Paused';
  String get markSold => ar ? 'تم البيع' : 'Mark as sold';
  String get renew => ar ? 'تجديد' : 'Renew';
  String get delete => ar ? 'حذف' : 'Delete';
  String get edit => ar ? 'تعديل' : 'Edit';
  String get pause => ar ? 'إيقاف' : 'Pause';
  String get resume => ar ? 'استئناف' : 'Resume';
  String get similar => ar ? 'إعلانات مشابهة' : 'Similar ads';
  String get seller => ar ? 'البائع' : 'Seller';
  String get viewSeller => ar ? 'كل إعلانات البائع' : 'View all ads by seller';
  String get rules => ar
      ? 'أؤكد أن الإعلان صادق ولا يشمل ممنوعات.'
      : 'I confirm this listing is honest and not a prohibited item.';
  String get published =>
      ar ? 'إعلانك بانتظار الموافقة' : 'Your ad is awaiting approval';
  String get awaitingApproval => ar ? 'بانتظار الموافقة' : 'Awaiting approval';
  String get pending => ar ? 'قيد المراجعة' : 'Pending';
  String get approved => ar ? 'مقبول' : 'Approved';
  String get declined => ar ? 'مرفوض' : 'Declined';
  String get signInToSell =>
      ar ? 'سجّل الدخول لنشر إعلان' : 'Sign in to post an ad';
  String get subtitle => ar ? 'العنوان الفرعي' : 'Subtitle';
  String get addVideo => ar ? 'أضف فيديو' : 'Add video';
  String get videoHint =>
      ar ? 'حتى ٤٥ ثانية، سيتم ضغطه' : 'Up to 45 seconds, we compress it';
  String get myViews => ar ? 'مشاهدات إعلاناتك' : 'Views on your ads';
  String get viewAd => ar ? 'عرض إعلاني' : 'View my ad';
  String get postAnother => ar ? 'إعلان آخر' : 'Post another';
  String get noFavorites => ar ? 'لا مفضلات بعد' : 'No favorites yet';
  String get noChats => ar ? 'لا محادثات بعد' : 'No chats yet';
  String get stillAvailable => ar ? 'هل ما زال متاحاً؟' : 'Is it still available?';
  String get finalPrice => ar ? 'آخر سعر؟' : 'Final price?';
  String get whereSee => ar ? 'وين أقدر أشوفه؟' : 'Where can I see it?';
  String get useSuggestion => ar ? 'استخدم الاقتراح' : 'Use suggestion';
  String get newest => ar ? 'الأحدث' : 'Newest';
  String get priceUp => ar ? 'السعر ↑' : 'Price ↑';
  String get priceDown => ar ? 'السعر ↓' : 'Price ↓';
  String get mileageDown => ar ? 'العداد ↓' : 'Mileage ↓';
  String get yearDown => ar ? 'السنة ↓' : 'Year ↓';
  String get withPhotos => ar ? 'بصور فقط' : 'With photos only';
  String get city => ar ? 'المدينة' : 'City';
  String get condition => ar ? 'الحالة' : 'Condition';
  String get browseMake => ar ? 'تصفح حسب الشركة' : 'Browse by make';
  String adsCount(int n, String name) =>
      ar ? '$n $name' : '$n $name';
  String interested(String title) => ar
      ? 'مرحبا، مهتم بإعلانك: $title'
      : "Hi, I'm interested in your ad: $title";
}
