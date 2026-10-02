import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../data/currency_service.dart';
import '../data/life_settings.dart';
import '../data/phrases.dart';
import '../theme/app_theme.dart';

class PhrasesScreen extends StatelessWidget {
  const PhrasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Arabic phrases')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Text(
              'Tap a phrase to copy the Arabic. Useful at police, hospital, and Absher counters.',
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
          ),
          for (final group in phraseGroups) _GroupCard(group: group),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group});
  final PhraseGroup group;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.stroke),
        ),
        child: ExpansionTile(
          title: Text(
            group.title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(group.subtitle),
          children: [
            for (final phrase in group.phrases)
              ListTile(
                title: Text(
                  phrase.ar,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                    color: AppColors.goldSoft,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('${phrase.en}\n${phrase.say}'),
                ),
                isThreeLine: true,
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: phrase.ar));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Arabic copied')),
                    );
                  }
                },
              ),
          ],
        ),
        ),
      ),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _amount = TextEditingController(text: '7000');
  late Future<FxQuote> _quote;

  @override
  void initState() {
    super.initState();
    _quote = CurrencyService.loadRates();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = LifeSettings.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Salary calculator')),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          return FutureBuilder<FxQuote>(
            future: _quote,
            builder: (context, snap) {
              final quote = snap.data ??
                  const FxQuote(rates: fallbackSarRates, live: false);
              final sar = double.tryParse(_amount.text.replaceAll(',', '')) ?? 0;
              final rate = quote.rates[settings.homeCurrency] ?? 0;
              final monthly = sar * rate;
              final yearly = monthly * 12;
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  const Text(
                    'Enter your monthly salary in Saudi riyals. Convert to the currency you send home.',
                    style: TextStyle(color: AppColors.muted, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Monthly salary (SAR)',
                    prefixText: 'SAR  ',
                    prefixStyle: const TextStyle(
                      color: AppColors.goldSoft,
                      fontWeight: FontWeight.w800,
                    ),
                    filled: true,
                    fillColor: AppColors.card,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.stroke),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.gold, width: 1.2),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: settings.homeCurrency,
                    items: [
                      for (final c in homeCurrencies)
                        DropdownMenuItem(
                          value: c.code,
                          child: Text('${c.code}  ·  ${c.name}'),
                        ),
                    ],
                    onChanged: (code) {
                      if (code != null) settings.setHomeCurrency(code);
                    },
                  ),
                  const SizedBox(height: 20),
                  _ResultCard(
                    title: 'Monthly',
                    value: monthly,
                    code: settings.homeCurrency,
                  ),
                  const SizedBox(height: 10),
                  _ResultCard(
                    title: 'Yearly',
                    value: yearly,
                    code: settings.homeCurrency,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    quote.live
                        ? 'Live rate: 1 SAR = ${rate.toStringAsFixed(3)} ${settings.homeCurrency}'
                        : 'Using saved rates. 1 SAR ≈ ${rate.toStringAsFixed(3)} ${settings.homeCurrency}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'KSA has no personal income tax. GOSI and housing are extra — this is a transfer estimate only.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.title,
    required this.value,
    required this.code,
  });

  final String title;
  final double value;
  final String code;

  @override
  Widget build(BuildContext context) {
    final formatted = NumberFormat.decimalPattern().format(value.round());
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(
            '$formatted $code',
            style: const TextStyle(
              color: AppColors.goldSoft,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
