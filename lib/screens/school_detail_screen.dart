import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/dial.dart';
import '../data/maps_config.dart';
import '../data/school_photos.dart';
import '../data/school_repository.dart';
import '../models/school.dart';
import '../theme/app_theme.dart';
import '../widgets/motion.dart';
import '../widgets/school_photo.dart';

class SchoolDetailScreen extends StatefulWidget {
  const SchoolDetailScreen({super.key, required this.school});

  final School school;

  @override
  State<SchoolDetailScreen> createState() => _SchoolDetailScreenState();
}

class _SchoolDetailScreenState extends State<SchoolDetailScreen> {
  late School _school;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _school = widget.school;
    _hydrate();
  }

  Future<void> _hydrate() async {
    setState(() => _loading = true);
    final fresh = await SchoolRepository.instance.byId(widget.school.id);
    if (!mounted) return;
    setState(() {
      if (fresh != null) _school = fresh;
      _loading = false;
    });
  }

  Future<void> _openUrl(String raw) async {
    final value = raw.trim();
    if (value.isEmpty) return;
    final uri = Uri.parse(value.startsWith('http') ? value : 'https://$value');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SchoolRepository.instance,
      builder: (context, _) {
        final latest = SchoolRepository.instance.places
            .where((item) => item.id == _school.id);
        final school = latest.isEmpty ? _school : latest.first;
        final fees = school.fees;
        final admission = school.admission;
        return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(school.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          if (schoolGalleryUrls(school).isNotEmpty) ...[
            const _SectionTitle('Photos'),
            const SizedBox(height: 8),
            SizedBox(
              height: 168,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: schoolGalleryUrls(school).length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final urls = schoolGalleryUrls(school);
                  return SchoolPhoto(
                    school: school,
                    url: urls[index],
                    width: 240,
                    height: 168,
                    radius: 18,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (school.hasPin)
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                height: 176,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(school.lat, school.lng),
                    zoom: 15.1,
                  ),
                  style: kGoogleMapsDarkStyle,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  myLocationButtonEnabled: false,
                  compassEnabled: false,
                  gestureRecognizers: {
                    Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer(),
                    ),
                  },
                  markers: {
                    Marker(
                      markerId: MarkerId(school.id),
                      position: LatLng(school.lat, school.lng),
                      infoWindow: InfoWindow(title: school.name),
                    ),
                  },
                ),
              ),
            ),
          if (school.hasPin) const SizedBox(height: 14),
          Text(
            school.name,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            [
              if (school.district.isNotEmpty) school.district,
              if (school.city.isNotEmpty) school.city,
              if (school.km > 0)
                '${school.km < 10 ? school.km.toStringAsFixed(1) : school.km.toStringAsFixed(0)} km away',
            ].join('  ·  '),
            style: const TextStyle(color: AppColors.muted, height: 1.4),
          ),
          if (school.address.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              school.address,
              style: const TextStyle(color: AppColors.muted, height: 1.35),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in school.curriculum)
                _Pill(schoolCurriculumLabel(tag)),
              if (schoolGenderLabel(school).isNotEmpty)
                _Pill(schoolGenderLabel(school)),
              if (school.grades.isNotEmpty) _Pill(school.grades),
              if (school.established != null) _Pill('Est. ${school.established}'),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (school.phone.isNotEmpty)
                _Action(
                  label: 'Call',
                  icon: Icons.call_rounded,
                  onTap: () => callNumber(school.phone),
                ),
              if (school.hasPin)
                _Action(
                  label: 'Directions',
                  icon: Icons.directions_rounded,
                  onTap: () => openMap(school.lat, school.lng, school.name),
                ),
              if (school.website.isNotEmpty)
                _Action(
                  label: 'Website',
                  icon: Icons.public_rounded,
                  onTap: () => _openUrl(school.website),
                ),
              if (school.email.isNotEmpty)
                _Action(
                  label: 'Email',
                  icon: Icons.mail_outline_rounded,
                  onTap: () => launchUrl(Uri.parse('mailto:${school.email}')),
                ),
              if ((fees.sourceUrl.isNotEmpty || school.feeSourceUrl.isNotEmpty) &&
                  (fees.sourceUrl.isNotEmpty ? fees.sourceUrl : school.feeSourceUrl) !=
                      school.website)
                _Action(
                  label: 'Fee page',
                  icon: Icons.payments_outlined,
                  onTap: () => _openUrl(
                    fees.sourceUrl.isNotEmpty
                        ? fees.sourceUrl
                        : school.feeSourceUrl,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionTitle('Tuition'),
          const SizedBox(height: 8),
          _FeeCard(
            school: school,
            loading: _loading,
            onOpenSource: _openUrl,
          ),
          if (fees.oneTimeFees.isNotEmpty) ...[
            const SizedBox(height: 18),
            const _SectionTitle('Other published fees'),
            const SizedBox(height: 8),
            for (final fee in fees.oneTimeFees)
              _Line(
                fee.name,
                [
                  if (fee.amountSar != null) formatSar(fee.amountSar),
                  if (fee.note.isNotEmpty) fee.note,
                ].join(' · '),
              ),
          ],
          if (fees.discounts.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final discount in fees.discounts) _Line('Discount', discount),
          ],
          const SizedBox(height: 22),
          const _SectionTitle('Admission'),
          const SizedBox(height: 6),
          Text(
            admission.schoolSpecific
                ? 'Steps published for this school.'
                : 'Standard private-school admission in Saudi Arabia. Confirm each step with this school.',
            style: const TextStyle(color: AppColors.muted, height: 1.4),
          ),
          if (admission.steps.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (var i = 0; i < admission.steps.length; i++)
              _Line('${i + 1}', admission.steps[i]),
          ],
          if (admission.documentsRequired.isNotEmpty) ...[
            const SizedBox(height: 16),
            const _SectionTitle('Documents'),
            const SizedBox(height: 8),
            for (final doc in admission.documentsRequired) _Line('•', doc),
          ],
          if (admission.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(admission.notes, style: const TextStyle(height: 1.4)),
          ],
          const SizedBox(height: 18),
          Text(
            school.disclaimer.isNotEmpty
                ? school.disclaimer
                : SchoolRepository.instance.disclaimer,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
      },
    );
  }
}

class _FeeCard extends StatelessWidget {
  const _FeeCard({
    required this.school,
    required this.loading,
    required this.onOpenSource,
  });

  final School school;
  final bool loading;
  final void Function(String url) onOpenSource;

  @override
  Widget build(BuildContext context) {
    final fees = school.fees;
    final grades = fees.byGrade;
    final official = school.feeSourceType == 'official_website' ||
        fees.fromSchoolWebsite;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            schoolFeeLabel(school),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            [
              if (school.feeYear.isNotEmpty || fees.academicYear.isNotEmpty)
                school.feeYear.isNotEmpty ? school.feeYear : fees.academicYear,
              if (fees.vatNote.isNotEmpty) fees.vatNote,
              official ? 'From the school website' : 'Directory figure — confirm with the school',
            ].join('  ·  '),
            style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.35),
          ),
          if (loading && grades.isEmpty) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(minHeight: 2),
          ],
          if (grades.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final grade in grades)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        grade.grade,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      grade.annualFeeSar == null
                          ? '—'
                          : formatSar(grade.annualFeeSar),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
          ],
          if ((fees.sourceUrl.isNotEmpty || school.feeSourceUrl.isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: GestureDetector(
                onTap: () => onOpenSource(
                  fees.sourceUrl.isNotEmpty
                      ? fees.sourceUrl
                      : school.feeSourceUrl,
                ),
                child: Text(
                  fees.sourceName.isNotEmpty
                      ? 'Source: ${fees.sourceName}'
                      : school.feeSourceName.isNotEmpty
                          ? 'Source: ${school.feeSourceName}'
                          : 'Open fee source',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 16,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.kicker, this.text);
  final String kicker;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              kicker,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.gold,
              ),
            ),
          ),
          Expanded(
            child: Text(text, style: const TextStyle(height: 1.35)),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.gold),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.gold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
