import 'package:flutter/material.dart';

import '../data/dial.dart';
import '../data/emergencies.dart';
import '../data/life_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/app_filter_chip.dart';

class EmbassyDirectoryScreen extends StatefulWidget {
  const EmbassyDirectoryScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<EmbassyDirectoryScreen> createState() => _EmbassyDirectoryScreenState();
}

class _EmbassyDirectoryScreenState extends State<EmbassyDirectoryScreen> {
  final _search = TextEditingController();
  String _query = '';
  String _city = 'All';

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery.isNotEmpty) {
      _search.text = widget.initialQuery;
      _query = widget.initialQuery;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<MapEntry<String, List<Embassy>>> _groups() {
    final q = _query.trim().toLowerCase();
    final groups = <String, List<Embassy>>{};
    for (final e in EmergencyData.embassies) {
      if (_city != 'All' && e.city != _city) continue;
      if (q.isNotEmpty &&
          !e.country.toLowerCase().contains(q) &&
          !e.phone.contains(q.replaceAll(' ', ''))) {
        continue;
      }
      groups.putIfAbsent(e.country, () => []).add(e);
    }
    final mine = LifeSettings.instance.nationality;
    final entries = groups.entries.toList();
    entries.sort((a, b) {
      final aMine = a.value.first.nationalityId == mine;
      final bMine = b.value.first.nationalityId == mine;
      if (aMine != bMine) return aMine ? -1 : 1;
      return a.key.compareTo(b.key);
    });
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups();
    final countries = {for (final e in EmergencyData.embassies) e.country}.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Embassies & consulates')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search $countries countries',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.gold),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                      ),
                filled: true,
                fillColor: AppColors.card,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.stroke),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.gold, width: 1.2),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final city in const ['All', 'Riyadh', 'Jeddah'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AppFilterChip(
                      label: city == 'All' ? 'All cities' : city,
                      selected: _city == city,
                      onSelected: (_) => setState(() => _city = city),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: groups.isEmpty
                ? const Center(
                    child: Text(
                      'No mission matches that search.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                    itemCount: groups.length + 1,
                    itemBuilder: (context, index) {
                      if (index == groups.length) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Numbers come from public embassy directories and can change. '
                            'If a line does not answer, check the mission’s official website. '
                            'For a life-threatening emergency call 911 first.',
                            style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
                          ),
                        );
                      }
                      final group = groups[index];
                      return _CountryCard(
                        missions: group.value,
                        mine: group.value.first.nationalityId ==
                            LifeSettings.instance.nationality,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CountryCard extends StatelessWidget {
  const _CountryCard({required this.missions, required this.mine});

  final List<Embassy> missions;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final first = missions.first;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: mine ? AppColors.gold.withValues(alpha: 0.6) : AppColors.stroke,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(first.flagEmoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  first.country,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              if (mine)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.chip,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Your country',
                    style: TextStyle(
                      color: AppColors.goldSoft,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          for (final mission in missions) _MissionRow(mission: mission),
        ],
      ),
    );
  }
}

class _MissionRow extends StatelessWidget {
  const _MissionRow({required this.mission});

  final Embassy mission;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${mission.kind} · ${mission.city}',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  [
                    formatSaudiPhone(mission.phone),
                    if (mission.altPhone != null) formatSaudiPhone(mission.altPhone!),
                  ].join('   ·   '),
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          if (mission.altPhone != null)
            IconButton(
              tooltip: 'Call second line',
              onPressed: () => callNumber(mission.altPhone!),
              icon: const Icon(Icons.phone_forwarded_rounded, color: AppColors.muted, size: 20),
            ),
          IconButton(
            tooltip: 'Call ${mission.country} ${mission.kind.toLowerCase()}',
            onPressed: () => callNumber(mission.phone),
            icon: const Icon(Icons.call_rounded, color: AppColors.green),
          ),
        ],
      ),
    );
  }
}

String formatSaudiPhone(String number) {
  if (number.length == 10) {
    return '${number.substring(0, 3)} ${number.substring(3, 6)} ${number.substring(6)}';
  }
  return number;
}
