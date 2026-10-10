import 'package:intl/intl.dart';

import '../domain/souq_models.dart';

class SouqFormat {
  static const _arabicDigits = {
    '٠': '0',
    '١': '1',
    '٢': '2',
    '٣': '3',
    '٤': '4',
    '٥': '5',
    '٦': '6',
    '٧': '7',
    '٨': '8',
    '٩': '9',
    '۰': '0',
    '۱': '1',
    '۲': '2',
    '۳': '3',
    '۴': '4',
    '۵': '5',
    '۶': '6',
    '۷': '7',
    '۸': '8',
    '۹': '9',
  };

  static const _tashkeel = r'[\u064B-\u065F\u0670\u06D6-\u06ED]';

  static String westernDigits(String input) {
    final buf = StringBuffer();
    for (final rune in input.runes) {
      final ch = String.fromCharCode(rune);
      buf.write(_arabicDigits[ch] ?? ch);
    }
    return buf.toString();
  }

  static String normalizeSearch(String input) {
    var s = westernDigits(input).toLowerCase().trim();
    s = s.replaceAll(RegExp(_tashkeel), '');
    s = s
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي');
    return s;
  }

  static bool matches(String haystack, String needle) {
    if (needle.trim().isEmpty) return true;
    return normalizeSearch(haystack).contains(normalizeSearch(needle));
  }

  static double? parsePrice(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) {
      final v = raw.toDouble();
      if (v <= 0 || v == 1 || v == 12 || v == 1111111) return null;
      return v;
    }
    var s = westernDigits('$raw').trim();
    if (s.isEmpty) return null;
    final lower = s.toLowerCase();
    if (lower.contains('سوم') ||
        lower.contains('negot') ||
        lower.contains('best offer') ||
        lower.contains('على السوم')) {
      return null;
    }
    final labeled = RegExp(
      r'(?:SAR|SR|USD|AED|ر\.?\s*س)\s*([\d,]+(?:\.\d+)?)',
      caseSensitive: false,
    ).firstMatch(s);
    if (labeled != null) {
      final n = double.tryParse(labeled.group(1)!.replaceAll(',', ''));
      if (n != null && n > 0) return n;
    }
    final thousands = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:ألف|الف|(?<![A-Za-z])[kK](?![A-Za-z]))',
    ).firstMatch(s);
    if (thousands != null) {
      final n = double.tryParse(thousands.group(1)!);
      if (n != null && n > 0 && n < 1000) return n * 1000;
      if (n != null && n >= 1000) return n;
    }
    final first = RegExp(r'[\d,]+(?:\.\d+)?').firstMatch(s);
    if (first == null) return null;
    final n = double.tryParse(first.group(0)!.replaceAll(',', ''));
    if (n == null || n <= 0 || n == 1 || n == 12) return null;
    return n;
  }

  static String sar(double? price, {bool ar = false, bool negotiable = false}) {
    if (price == null) {
      return ar ? 'على السوم' : 'Best offer';
    }
    final formatted = NumberFormat('#,##0', 'en').format(price.round());
    if (ar) return '$formatted ر.س';
    return 'SAR $formatted';
  }

  static String compactSar(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(price % 1000000 == 0 ? 0 : 1)}M';
    }
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(price % 1000 == 0 ? 0 : 1)}k';
    }
    return NumberFormat('#,##0', 'en').format(price.round());
  }

  static String relativeTime(DateTime at, {bool ar = false}) {
    final now = DateTime.now();
    final diff = now.difference(at);
    if (diff.inMinutes < 1) return ar ? 'الآن' : 'Just now';
    if (diff.inMinutes < 60) {
      return ar ? 'قبل ${diff.inMinutes} د' : '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return ar ? 'قبل ${diff.inHours} س' : '${diff.inHours}h ago';
    }
    if (diff.inDays < 7) {
      return ar ? 'قبل ${diff.inDays} يوم' : '${diff.inDays}d ago';
    }
    return DateFormat('d MMM').format(at);
  }

  static String km(int? mileage) {
    if (mileage == null) return '';
    return '${NumberFormat('#,##0', 'en').format(mileage)} km';
  }

  static String conditionLabel(AdCondition c, {bool ar = false}) {
    return switch (c) {
      AdCondition.brandNew => ar ? 'جديد' : 'New',
      AdCondition.likeNew => ar ? 'كالجديد' : 'Like new',
      AdCondition.good => ar ? 'جيد' : 'Good',
      AdCondition.fair => ar ? 'مقبول' : 'Fair',
      AdCondition.forParts => ar ? 'للتشليح' : 'For parts',
    };
  }

  static String suggestCarTitle({
    String? make,
    String? model,
    int? year,
    int? mileage,
  }) {
    final parts = <String>[
      if (make != null && make.isNotEmpty) make,
      if (model != null && model.isNotEmpty) model,
      if (year != null) '$year',
    ];
    var title = parts.join(' ');
    if (mileage != null && mileage > 0) {
      title = '$title – ${NumberFormat('#,##0', 'en').format(mileage)} km';
    }
    return title;
  }

  static const prohibited = [
    'weapon',
    'gun',
    'pistol',
    'ammunition',
    'drug',
    'hashish',
    'cocaine',
    'alcohol',
    'beer',
    'wine',
    'whisky',
    'سلاح',
    'مسدس',
    'ذخيرة',
    'مخدر',
    'حشيش',
    'خمر',
    'كحول',
  ];

  static bool looksProhibited(String text) {
    final n = normalizeSearch(text);
    return prohibited.any((w) => n.contains(normalizeSearch(w)));
  }
}
