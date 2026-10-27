import 'package:flutter/material.dart';

import '../data/app_legal.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'in_app_browser_screen.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.termsOfUse),
        actions: [
          TextButton(
            onPressed: () => openInAppBrowser(
              context,
              url: AppLegal.termsUrl,
              title: l10n.termsOfUse,
            ),
            child: Text(l10n.privacyHowWeUse),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Text(
            l10n.termsNoAbuse,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            arabic ? _bodyAr : _bodyEn,
            style: const TextStyle(
              color: AppColors.navy,
              height: 1.5,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

const _bodyEn = '''
KSA 360 Terms of Use
Last updated: 27 October 2026
Operated by Lumrah (www.lumrah.co)

By creating an account, signing in, or using KSA 360 you agree to these Terms of Use and our Privacy Policy.

1. Who may use the app
You must be 13 or older. You are responsible for what you post and for keeping your account safe.

2. Zero tolerance for objectionable content and abusive users
KSA 360 does not tolerate objectionable content or abusive users. This includes, without limitation:
• harassment, hate, threats, or bullying
• sexual content involving minors, or any sexual exploitation
• spam, scams, fraud, or impersonation
• illegal activity, graphic violence, or content that incites harm
• anything that violates Saudi law or these terms

We may remove content, warn, suspend, or permanently ban accounts. Repeat or severe abuse leads to removal without further notice.

3. User-generated content
Community posts, comments, marketplace listings, jobs, and similar content are provided by users, not by Lumrah. You grant Lumrah a licence to host, moderate, and display that content in the app.

4. Report and Block
Use Report to flag content. Use Block to hide a person’s posts, comments, and listings from your feed immediately. Blocking also notifies the KSA 360 team so we can review the account.

5. Marketplace and community rules
List only items and services you are allowed to sell. Do not post misleading ads. Do not use community pages to attack people.

6. Our service
We provide guides, directories, prayer times, community, and marketplace tools as-is. We may change or discontinue features.

7. Account deletion
You can delete your account in Profile. After a short restore window, deletion is permanent.

8. Contact
privacy@lumrah.co · www.lumrah.co

If you do not agree, do not create an account or sign in.
''';

const _bodyAr = '''
شروط استخدام KSA 360
آخر تحديث: 27 أكتوبر 2026
تشغّله Lumrah (www.lumrah.co)

بإنشاء حساب أو تسجيل الدخول أو استخدام KSA 360 فإنك توافق على شروط الاستخدام هذه وسياسة الخصوصية.

1. من يجوز له الاستخدام
يجب أن يكون عمرك 13 سنة أو أكثر. أنت مسؤول عما تنشره وعن حماية حسابك.

2. عدم التسامح مع المحتوى المسيء والمستخدمين المسيئين
لا يتسامح KSA 360 مع المحتوى المسيء أو المستخدمين المسيئين. يشمل ذلك دون حصر:
• التحرش أو الكراهية أو التهديد أو التنمّر
• المحتوى الجنسي المتعلق بالقاصرين أو أي استغلال جنسي
• الرسائل المزعجة أو الاحتيال أو انتحال الهوية
• النشاط غير القانوني أو العنف المفرط أو التحريض على الأذى
• أي شيء يخالف أنظمة المملكة أو هذه الشروط

يجوز لنا حذف المحتوى أو التحذير أو إيقاف الحساب أو حظره نهائياً. الإساءة المتكررة أو الجسيمة تؤدي إلى الإزالة دون إشعار إضافي.

3. المحتوى الذي ينشئه المستخدمون
المنشورات والتعليقات وإعلانات السوق والوظائف يقدمها المستخدمون وليس Lumrah. تمنح Lumrah ترخيصاً لاستضافة هذا المحتوى وعرضه ومراجعته.

4. الإبلاغ والحظر
استخدم «إبلاغ» للإشارة إلى المحتوى. استخدم «حظر» لإخفاء منشورات الشخص وتعليقاته وإعلاناته من خلاصتك فوراً. الحظر يُشعر فريق KSA 360 أيضاً لمراجعة الحساب.

5. قواعد السوق والمجتمع
اعرض فقط ما يحق لك بيعه. لا تنشر إعلانات مضللة. لا تستخدم صفحات المجتمع للإساءة إلى الآخرين.

6. الخدمة
نقدم الأدلة والأدلة المحلية وأوقات الصلاة والمجتمع والسوق كما هي. قد نغيّر الميزات أو نوقفها.

7. حذف الحساب
يمكنك حذف حسابك من الملف الشخصي. بعد مهلة استعادة قصيرة يصبح الحذف نهائياً.

8. التواصل
privacy@lumrah.co · www.lumrah.co

إذا كنت لا توافق فلا تنشئ حساباً ولا تسجّل الدخول.
''';
