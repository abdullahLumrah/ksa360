import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ksa_guide/features/souq/data/expat_parser.dart';
import 'package:ksa_guide/features/souq/domain/souq_models.dart';

void main() {
  test('parses expatriates title into make year price mileage', () {
    final ad = ExpatParser.fromRecord({
      'id': '64319867',
      'title':
          'SAR 69000,  Infiniti QX60,  2019,  Automatic,  200000 KM,    200K Km Super Clean 7 Passengers',
      'postDate': 1790870000,
      'city': 'Riyadh',
      'images': ['https://www.expatriates.com/img/64319867.1.jpg'],
      'url': 'https://www.expatriates.com/cls/64319867.html',
    });
    expect(ad, isNotNull);
    expect(ad!.id, 'expat-64319867');
    expect(ad.source, AdSource.expatriates);
    expect(ad.city, 'Riyadh');
    expect(ad.price, 69000);
    expect(ad.make, 'Infiniti');
    expect(ad.year, 2019);
    expect(ad.mileage, 200000);
    expect(ad.transmission, 'Automatic');
    expect(ad.originalUrl, contains('64319867'));
    expect(ad.images, isNotEmpty);
  });

  test('skips empty titles', () {
    expect(ExpatParser.fromRecord({'id': '1', 'title': ''}), isNull);
  });

  test('collapses duplicate titles to one listing', () {
    const title =
        'SAR 11500,  Kia Rio,  2011,  Automatic,  300000 KM, Perfect Condition';
    final ads = ExpatParser.parseAssetJson(
      jsonEncode({
        'listings': [
          {
            'id': '64070351',
            'title': title,
            'postDate': 1790837091,
            'city': 'Riyadh',
            'images': ['https://www.expatriates.com/img/64070351.1.jpg'],
            'url': 'https://www.expatriates.com/cls/64070351.html',
          },
          {
            'id': '64027298',
            'title': title,
            'postDate': 1790837091,
            'city': 'Riyadh',
            'images': [
              'https://www.expatriates.com/img/64027298.1.jpg',
              'https://www.expatriates.com/img/64027298.2.jpg',
            ],
            'url': 'https://www.expatriates.com/cls/64027298.html',
          },
        ],
      }),
    );
    expect(ads, hasLength(1));
    expect(ads.single['id'], 'expat-64027298');
  });
}
