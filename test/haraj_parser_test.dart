import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ksa_guide/features/souq/data/haraj_parser.dart';
import 'package:ksa_guide/features/souq/domain/souq_models.dart';
import 'package:ksa_guide/features/souq/presentation/souq_format.dart';

void main() {
  test('maps actual Excel column names', () {
    const sample = {
      '#': 1,
      'Brand': 'Chevrolet',
      'Model': 'Malibu LTZ',
      'Year': 2013,
      'City': 'Jeddah',
      'Price (SAR)': 15000,
      'Type / condition': 'Used',
      'Haraj ad ID': '11189673128',
    };
    final ad = HarajParser.fromRecord(sample);
    expect(ad, isNotNull);
    expect(ad!.id, 'haraj-11189673128');
    expect(ad.source, AdSource.haraj);
    expect(ad.categoryId, 'cars');
    expect(ad.make, 'Chevrolet');
    expect(ad.model, 'Malibu LTZ');
    expect(ad.year, 2013);
    expect(ad.city, 'Jeddah');
    expect(ad.price, 15000);
    expect(ad.originalUrl, contains('11189673128'));
  });

  test('missing price becomes negotiable best offer', () {
    const sample = {
      'Brand': 'Chevrolet',
      'Model': 'Tahoe',
      'City': 'Riyadh',
      'Price (SAR)': null,
      'Type / condition': 'Used',
      'Haraj ad ID': '11189673127',
    };
    final ad = HarajParser.fromRecord(sample);
    expect(ad!.price, isNull);
    expect(ad.isNegotiable, isTrue);
  });

  test('arabic digits and ألف price strings', () {
    expect(SouqFormat.parsePrice('٤٥ ألف'), 45000);
    expect(SouqFormat.parsePrice('45,000'), 45000);
    expect(SouqFormat.parsePrice('على السوم'), isNull);
    expect(SouqFormat.westernDigits('٢٠٢٠'), '2020');
  });

  test('extracts make from Arabic title', () {
    expect(HarajParser.extractMake('تويوتا كامري 2020'), 'Toyota');
    expect(HarajParser.normalizeCity('الرياض'), 'Riyadh');
    expect(HarajParser.normalizeCity('جدة'), 'Jeddah');
  });

  test('skips rows without id and dedupes asset json', () {
    final raw = jsonEncode({
      'listings': [
        {
          'Brand': 'Ford',
          'Model': 'F-150',
          'Haraj ad ID': '1',
          'City': 'Dammam',
          'Price (SAR)': 90000,
        },
        {
          'Brand': 'Ford',
          'Model': 'F-150',
          'Haraj ad ID': '1',
          'City': 'Dammam',
          'Price (SAR)': 90000,
        },
        {'Brand': 'Nope'},
      ],
    });
    final ads = HarajParser.parseAssetJson(raw);
    expect(ads, hasLength(1));
    expect(ads.first['id'], 'haraj-1');
  });

  test('maps GraphQL scrape images and postDate', () {
    final ad = HarajParser.fromRecord({
      'id': 189675979,
      'title': 'رنج روفر 2016 مصدوم',
      'postDate': 1790858968,
      'city': 'الرياض',
      'Brand': 'Land Rover',
      'Year': 2016,
      'images': [
        'https://postcdn.haraj.com.sa/userfiles30/example.jpg-700.webp',
      ],
      'url': 'https://haraj.com.sa/11189675979/x/',
      'author': 'seller1',
      'price': 42000,
      'condition': 'USED',
    });
    expect(ad, isNotNull);
    expect(ad!.images, isNotEmpty);
    expect(ad.images.first, contains('postcdn.haraj.com.sa'));
    expect(ad.city, 'Riyadh');
    expect(ad.make, 'Land Rover');
    expect(ad.originalUrl, contains('11189675979'));
  });

  test('arabic search normalization', () {
    expect(SouqFormat.matches('إعلان تويوتا', 'اعلان'), isTrue);
    expect(SouqFormat.matches('مكة', 'مكه'), isTrue);
    expect(SouqFormat.looksProhibited('used pistol for sale'), isTrue);
    expect(SouqFormat.looksProhibited('Toyota Camry'), isFalse);
  });
}
