import 'package:flutter/material.dart';

import '../data/life_settings.dart';
import '../data/saudi_cities.dart';
import '../theme/app_theme.dart';

class CityPickerScreen extends StatefulWidget {
  const CityPickerScreen({super.key});

  @override
  State<CityPickerScreen> createState() => _CityPickerScreenState();
}

class _CityPickerScreenState extends State<CityPickerScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final grouped = SaudiCities.grouped;
    return Scaffold(
      appBar: AppBar(title: const Text('Choose city')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search Riyadh, Jeddah, Abha…',
                prefixIcon: const Icon(Icons.search_rounded),
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
                  borderSide: const BorderSide(color: AppColors.stroke),
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.my_location, color: AppColors.gold),
            title: const Text('Use my current location'),
            subtitle: const Text('Prayer times follow GPS across KSA'),
            onTap: () async {
              await LifeSettings.instance.refreshGps(request: true);
              if (context.mounted) Navigator.pop(context);
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              children: [
                for (final region in SaudiCities.regions)
                  ..._regionBlock(context, region, grouped[region] ?? const []),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _regionBlock(
    BuildContext context,
    String region,
    List<SaudiCity> cities,
  ) {
    final filtered = cities
        .where(
          (c) =>
              _query.isEmpty ||
              c.name.toLowerCase().contains(_query) ||
              region.toLowerCase().contains(_query),
        )
        .toList();
    if (filtered.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
        child: Text(
          region,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      for (final city in filtered)
        ListTile(
          title: Text(city.name),
          subtitle: Text(city.region),
          trailing: LifeSettings.instance.cityId == city.id &&
                  !LifeSettings.instance.useGps
              ? const Icon(Icons.check_rounded, color: AppColors.gold)
              : null,
          onTap: () async {
            await LifeSettings.instance.selectCity(city.id);
            if (context.mounted) Navigator.pop(context);
          },
        ),
    ];
  }
}
