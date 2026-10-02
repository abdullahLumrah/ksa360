class Phrase {
  const Phrase({
    required this.en,
    required this.ar,
    required this.say,
  });

  final String en;
  final String ar;
  final String say;
}

class PhraseGroup {
  const PhraseGroup({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.phrases,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<Phrase> phrases;
}

const phraseGroups = <PhraseGroup>[
  PhraseGroup(
    id: 'police',
    title: 'Police & accidents',
    subtitle: 'If you are stopped or need help',
    phrases: [
      Phrase(en: 'I need the police.', ar: 'أحتاج الشرطة.', say: 'Ahtaj ash-shurta'),
      Phrase(en: 'There has been an accident.', ar: 'حصل حادث.', say: 'Hasal hadith'),
      Phrase(en: 'Please call 911.', ar: 'من فضلك اتصل بـ٩١١.', say: 'Min fadlak ittasel bi tisa miya wahid ashar'),
      Phrase(en: 'I did not do anything wrong.', ar: 'أنا ما سويت شيء غلط.', say: 'Ana ma sawwayt shay ghalat'),
      Phrase(en: 'Here is my iqama.', ar: 'هذه إقامتي.', say: 'Hathihi iqamati'),
      Phrase(en: 'I do not speak Arabic well.', ar: 'أنا لا أتكلم العربية جيداً.', say: 'Ana la atakallam al-arabiya jayyidan'),
      Phrase(en: 'Can I call my sponsor?', ar: 'ممكن أتصل على كفيلي؟', say: 'Mumkin atasel ala kafeeli?'),
    ],
  ),
  PhraseGroup(
    id: 'hospital',
    title: 'Hospital & pharmacy',
    subtitle: 'Emergency, clinic, medicine',
    phrases: [
      Phrase(en: 'I need a doctor.', ar: 'أحتاج طبيب.', say: 'Ahtaj tabeeb'),
      Phrase(en: 'It is an emergency.', ar: 'هذه حالة طارئة.', say: 'Hathihi halat tari\'a'),
      Phrase(en: 'I have pain here.', ar: 'عندي ألم هنا.', say: 'Indi alam huna'),
      Phrase(en: 'I have insurance.', ar: 'عندي تأمين.', say: 'Indi tamin'),
      Phrase(en: 'I am diabetic / allergic.', ar: 'أنا مريض سكر / عندي حساسية.', say: 'Ana mareed sukkar / indi hasasiya'),
      Phrase(en: 'Where is the pharmacy?', ar: 'وين الصيدلية؟', say: 'Wayn as-saydaliya?'),
      Phrase(en: 'I need this medicine.', ar: 'أبغى هذا الدواء.', say: 'Abgha hatha ad-dawa'),
    ],
  ),
  PhraseGroup(
    id: 'absher',
    title: 'Absher & Jawazat counters',
    subtitle: 'Iqama, visa, traffic, appointments',
    phrases: [
      Phrase(en: 'I have an Absher appointment.', ar: 'عندي موعد في أبشر.', say: 'Indi mawid fi Absher'),
      Phrase(en: 'I want to renew my iqama.', ar: 'أبغى أجدد الإقامة.', say: 'Abgha ajadded al-iqama'),
      Phrase(en: 'I need an exit/re-entry visa.', ar: 'أبغى تأشيرة خروج وعودة.', say: 'Abgha tashirat khurooj wa awda'),
      Phrase(en: 'My iqama is expired.', ar: 'إقامتي منتهية.', say: 'Iqamati muntahiya'),
      Phrase(en: 'I need to pay a traffic fine.', ar: 'أبغى أدفع مخالفة مرورية.', say: 'Abgha adfa mukhalafat murooriya'),
      Phrase(en: 'Where do I take a number?', ar: 'وين آخذ رقم؟', say: 'Wayn akhuth raqm?'),
      Phrase(en: 'Please help me, I am a resident.', ar: 'لو سمحت ساعدني، أنا مقيم.', say: 'Law samaht saadni, ana muqeem'),
    ],
  ),
  PhraseGroup(
    id: 'tawakkalna',
    title: 'Tawakkalna / Nafath',
    subtitle: 'Apps, OTP, login problems',
    phrases: [
      Phrase(en: 'Tawakkalna is not working.', ar: 'توكلنا ما يشتغل.', say: 'Tawakkalna ma yashtaghil'),
      Phrase(en: 'I did not receive the OTP.', ar: 'ما وصلني رمز التحقق.', say: 'Ma wasalni ramz at-tahaqquq'),
      Phrase(en: 'Please scan my Nafath request.', ar: 'من فضلك وافق طلب نفاذ.', say: 'Min fadlak wafiq talab Nafath'),
      Phrase(en: 'My phone number is this.', ar: 'رقم جوالي هذا.', say: 'Raqm jawwali hatha'),
      Phrase(en: 'I need to update my phone in Absher.', ar: 'أبغى أحدث رقم الجوال في أبشر.', say: 'Abgha uhaddith raqm al-jawwal fi Absher'),
    ],
  ),
  PhraseGroup(
    id: 'daily',
    title: 'Daily survival',
    subtitle: 'Taxi, shop, directions',
    phrases: [
      Phrase(en: 'Where is this place?', ar: 'وين هذا المكان؟', say: 'Wayn hatha al-makan?'),
      Phrase(en: 'How much is this?', ar: 'بكم هذا؟', say: 'Bikam hatha?'),
      Phrase(en: 'Too expensive.', ar: 'غالي مرة.', say: 'Ghali marra'),
      Phrase(en: 'Please take me to this address.', ar: 'وصلني لهذا العنوان لو سمحت.', say: 'Wassilni lihatha al-unwan law samaht'),
      Phrase(en: 'Thank you very much.', ar: 'شكراً جزيلاً.', say: 'Shukran jazeelan'),
      Phrase(en: 'Sorry / excuse me.', ar: 'عفواً / لو سمحت.', say: 'Afwan / law samaht'),
    ],
  ),
];
