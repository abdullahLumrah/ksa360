import 'dart:convert';

import 'package:http/http.dart' as http;

class HomeCurrency {
  const HomeCurrency(this.code, this.name, this.flag);
  final String code;
  final String name;
  final String flag;
}

const homeCurrencies = <HomeCurrency>[
  HomeCurrency('PKR', 'Pakistani rupee', 'PK'),
  HomeCurrency('INR', 'Indian rupee', 'IN'),
  HomeCurrency('BDT', 'Bangladeshi taka', 'BD'),
  HomeCurrency('PHP', 'Philippine peso', 'PH'),
  HomeCurrency('EGP', 'Egyptian pound', 'EG'),
  HomeCurrency('IDR', 'Indonesian rupiah', 'ID'),
  HomeCurrency('NPR', 'Nepalese rupee', 'NP'),
  HomeCurrency('LKR', 'Sri Lankan rupee', 'LK'),
  HomeCurrency('SDG', 'Sudanese pound', 'SD'),
  HomeCurrency('YER', 'Yemeni rial', 'YE'),
  HomeCurrency('JOD', 'Jordanian dinar', 'JO'),
  HomeCurrency('AED', 'UAE dirham', 'AE'),
  HomeCurrency('USD', 'US dollar', 'US'),
  HomeCurrency('EUR', 'Euro', 'EU'),
  HomeCurrency('GBP', 'British pound', 'GB'),
  HomeCurrency('TRY', 'Turkish lira', 'TR'),
];

const fallbackSarRates = <String, double>{
  'PKR': 74.5,
  'INR': 22.3,
  'BDT': 32.4,
  'PHP': 15.4,
  'EGP': 12.7,
  'IDR': 4350,
  'NPR': 35.6,
  'LKR': 80.2,
  'SDG': 160,
  'YER': 66.5,
  'JOD': 0.189,
  'AED': 0.98,
  'USD': 0.266,
  'EUR': 0.227,
  'GBP': 0.198,
  'TRY': 11.0,
};

class FxQuote {
  const FxQuote({required this.rates, required this.live});
  final Map<String, double> rates;
  final bool live;
}

class CurrencyService {
  static Future<FxQuote> loadRates() async {
    try {
      final res = await http
          .get(Uri.parse('https://open.er-api.com/v6/latest/SAR'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        return const FxQuote(rates: fallbackSarRates, live: false);
      }
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final raw = json['rates'] as Map<String, dynamic>?;
      if (raw == null) {
        return const FxQuote(rates: fallbackSarRates, live: false);
      }
      final rates = <String, double>{...fallbackSarRates};
      for (final code in fallbackSarRates.keys) {
        final value = raw[code];
        if (value is num) rates[code] = value.toDouble();
      }
      return FxQuote(rates: rates, live: true);
    } catch (_) {
      return const FxQuote(rates: fallbackSarRates, live: false);
    }
  }
}
