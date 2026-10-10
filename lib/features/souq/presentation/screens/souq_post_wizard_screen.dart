import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../data/auth_session.dart';
import '../../../../data/life_settings.dart';
import '../../../../data/saudi_cities.dart';
import '../../../../screens/auth_sheet.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/app_filter_chip.dart';
import '../../../../widgets/motion.dart';
import '../../domain/souq_categories.dart';
import '../../domain/souq_models.dart';
import '../souq_controller.dart';
import '../souq_format.dart';
import '../souq_l10n.dart';
import '../souq_motion.dart';
import '../widgets/souq_ad_card.dart';
import '../widgets/souq_widgets.dart';
import 'souq_my_ads_screen.dart';

class SouqPostWizardScreen extends StatefulWidget {
  const SouqPostWizardScreen({super.key, this.initialCategoryId, this.existing});
  final String? initialCategoryId;
  final Ad? existing;

  @override
  State<SouqPostWizardScreen> createState() => _SouqPostWizardScreenState();
}

class _SouqPostWizardScreenState extends State<SouqPostWizardScreen> {
  final _page = PageController();
  int _step = 0;
  int _shake = 0;
  bool _publishing = false;
  bool _done = false;
  Ad? _published;

  String? _categoryId;
  String? _subId;
  final _photos = <String>[];
  String? _videoPath;
  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  final _desc = TextEditingController();
  AdCondition _condition = AdCondition.good;
  final _attrs = <String, dynamic>{};
  double? _price;
  bool _negotiable = false;
  bool _free = false;
  bool _bestOffer = false;
  String _city = '';
  String? _district;
  final _phone = TextEditingController();
  bool _call = true;
  bool _wa = true;
  bool _chat = true;
  bool _hidePhone = false;
  bool _agreed = false;
  PriceInsight? _insight;

  SouqCategory? get cat =>
      _categoryId == null ? null : SouqCatalog.byId(_categoryId!);

  @override
  void initState() {
    super.initState();
    _city = LifeSettings.instance.city.name;
    _categoryId = widget.initialCategoryId;
    final existing = widget.existing;
    if (existing != null) {
      _hydrate(existing);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureSignedIn());
    SouqController.instance.ensureReady().then((_) {
      final draft = SouqController.instance.repo.draft;
      if (draft != null && widget.existing == null && mounted) {
        _offerDraft(draft);
      }
    });
  }

  Future<void> _ensureSignedIn() async {
    if (AuthSession.instance.isSignedIn) return;
    await showAuthSheet(context);
    if (!mounted) return;
    if (!AuthSession.instance.isSignedIn) {
      Navigator.maybePop(context);
    }
  }

  void _hydrate(Ad ad) {
    _categoryId = ad.categoryId;
    _subId = ad.subcategoryId;
    _photos.addAll(ad.images);
    _videoPath = ad.video.isEmpty ? null : ad.video;
    _title.text = ad.title;
    _subtitle.text = ad.subtitle;
    _desc.text = ad.description;
    _condition = ad.condition;
    _attrs.addAll(ad.attributes);
    _price = ad.price;
    _negotiable = ad.isNegotiable;
    _bestOffer = ad.price == null;
    _city = ad.city;
    _district = ad.district;
    _phone.text = ad.seller.phone ?? '';
    _call = ad.contact.call;
    _wa = ad.contact.whatsapp;
    _chat = ad.contact.chat;
    _hidePhone = ad.contact.hidePhone;
  }

  Future<void> _offerDraft(AdDraft draft) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(SouqL10n.of(context).draftBanner),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (go == true) {
      _applyDraft(draft.payload);
      setState(() => _step = draft.step);
      _page.jumpToPage(draft.step);
    } else {
      await SouqController.instance.repo.clearDraft();
    }
  }

  void _applyDraft(Map<String, dynamic> p) {
    _categoryId = p['categoryId'] as String?;
    _subId = p['subId'] as String?;
    _photos
      ..clear()
      ..addAll(((p['photos'] as List?) ?? []).map((e) => '$e'));
    _title.text = p['title'] as String? ?? '';
    _subtitle.text = p['subtitle'] as String? ?? '';
    _desc.text = p['desc'] as String? ?? '';
    _videoPath = p['video'] as String?;
    _price = (p['price'] as num?)?.toDouble();
    _city = p['city'] as String? ?? _city;
  }

  Map<String, dynamic> get _payload => {
        'categoryId': _categoryId,
        'subId': _subId,
        'photos': _photos,
        'title': _title.text,
        'subtitle': _subtitle.text,
        'desc': _desc.text,
        'video': _videoPath,
        'price': _price,
        'city': _city,
        'attrs': _attrs,
      };

  Future<void> _persistDraft() async {
    await SouqController.instance.repo.saveDraft(
      AdDraft(
        id: widget.existing?.id ?? 'draft',
        step: _step,
        updatedAt: DateTime.now(),
        payload: _payload,
      ),
    );
  }

  bool get _stepValid {
    switch (_step) {
      case 0:
        return _categoryId != null;
      case 1:
        return (cat?.photosRequired == false) || _photos.isNotEmpty;
      case 2:
        return _title.text.trim().length >= 4 &&
            !SouqFormat.looksProhibited('${_title.text} ${_desc.text}');
      case 3:
        return _free || _bestOffer || (_price != null && _price! >= 0);
      case 4:
        return _city.isNotEmpty && (_call || _wa || _chat);
      case 5:
        return _agreed;
      default:
        return false;
    }
  }

  Future<void> _next() async {
    if (!_stepValid) {
      HapticFeedback.mediumImpact();
      setState(() => _shake++);
      return;
    }
    await _persistDraft();
    if (_step == 5) {
      await _publish();
      return;
    }
    setState(() => _step++);
    _page.nextPage(
      duration: SouqMotion.sharedAxis,
      curve: SouqMotion.shared,
    );
    if (_step == 3) _loadInsight();
  }

  void _back() {
    if (_step == 0) {
      Navigator.maybePop(context);
      return;
    }
    setState(() => _step--);
    _page.previousPage(
      duration: SouqMotion.sharedAxis,
      curve: SouqMotion.shared,
    );
  }

  Future<void> _loadInsight() async {
    final make = '${_attrs['make'] ?? ''}';
    if (make.isEmpty) return;
    final insight = await SouqController.instance.repo.priceInsight(
      make: make,
      model: _attrs['model']?.toString(),
      year: int.tryParse('${_attrs['year'] ?? ''}'),
    );
    if (mounted) setState(() => _insight = insight);
  }

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(
      imageQuality: 55,
      maxWidth: 1280,
    );
    if (files.isEmpty) return;
    final dir = await getApplicationDocumentsDirectory();
    for (final f in files.take(10 - _photos.length)) {
      final dest = File(
        '${dir.path}/souq_${DateTime.now().millisecondsSinceEpoch}_${f.name}',
      );
      await File(f.path).copy(dest.path);
      _photos.add(dest.path);
    }
    setState(() {});
    await _persistDraft();
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final file = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 45),
    );
    if (file == null) return;
    final raw = File(file.path);
    if (await raw.length() > 20 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a shorter video so we can compress it')),
      );
      return;
    }
    final dir = await getApplicationDocumentsDirectory();
    final dest = File(
      '${dir.path}/souq_vid_${DateTime.now().millisecondsSinceEpoch}.mp4',
    );
    await raw.copy(dest.path);
    setState(() => _videoPath = dest.path);
    await _persistDraft();
  }

  Future<void> _publish() async {
    if (!AuthSession.instance.isSignedIn) {
      await showAuthSheet(context);
      if (!AuthSession.instance.isSignedIn) return;
    }
    setState(() => _publishing = true);
    HapticFeedback.mediumImpact();
    final me = SouqController.instance.repo.me.copyWith(
      phone: _phone.text.trim().isEmpty ? null : '+966${_phone.text.trim()}',
      whatsapp: _phone.text.trim().isEmpty ? null : '+966${_phone.text.trim()}',
    );
    final now = DateTime.now();
    final phone = _phone.text.trim();
    var description = _desc.text.trim();
    if (phone.isNotEmpty && !description.contains(phone)) {
      description = description.isEmpty ? phone : '$description\n\n+966$phone';
    }
    final ad = Ad(
      id: widget.existing?.id ?? 'user-${now.millisecondsSinceEpoch}',
      source: AdSource.user,
      categoryId: _categoryId!,
      subcategoryId: _subId,
      title: _title.text.trim(),
      subtitle: _subtitle.text.trim(),
      description: description,
      video: _videoPath ?? '',
      price: _free || _bestOffer ? null : _price,
      isNegotiable: _negotiable || _bestOffer,
      condition: _condition,
      images: List.of(_photos),
      city: _city,
      district: _district,
      attributes: Map.of(_attrs),
      seller: me,
      contact: ContactPreference(
        call: _call,
        whatsapp: _wa,
        chat: _chat,
        hidePhone: _hidePhone,
      ),
      createdAt: widget.existing?.createdAt ?? now,
      status: AdStatus.awaitingApproval,
    );
    try {
      final saved = await SouqController.instance.publish(ad);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _publishing = false;
        _done = true;
        _published = saved;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _publishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  @override
  void dispose() {
    _page.dispose();
    _title.dispose();
    _subtitle.dispose();
    _desc.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SouqL10n.of(context);
    if (_done && _published != null) {
      return _Success(ad: _published!, l10n: l10n);
    }
    final labels = [
      l10n.chooseCategory,
      l10n.photos,
      l10n.details,
      l10n.price,
      l10n.location,
      l10n.review,
    ];

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (did, _) async {
        if (!did) _back();
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: Text(l10n.postAd),
          leading: IconButton(
            onPressed: _back,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_step + 1) / 6,
                  minHeight: 6,
                  backgroundColor: AppColors.chip,
                  color: AppColors.green,
                ),
              ),
            ),
            Text(
              labels[_step],
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Expanded(
              child: PageView(
                controller: _page,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _CategoryStep(
                    selectedId: _categoryId,
                    subId: _subId,
                    onSelect: (id) => setState(() {
                      _categoryId = id;
                      _subId = null;
                    }),
                    onSub: (id) => setState(() => _subId = id),
                  ),
                  _PhotosStep(
                    photos: _photos,
                    videoPath: _videoPath,
                    tips: cat == null
                        ? ''
                        : (l10n.ar ? cat!.photoTipsAr : cat!.photoTipsEn),
                    onAdd: _pickPhotos,
                    onAddVideo: _pickVideo,
                    onClearVideo: () => setState(() => _videoPath = null),
                    onRemove: (i) => setState(() => _photos.removeAt(i)),
                    onReorder: (from, to) {
                      setState(() {
                        final item = _photos.removeAt(from);
                        _photos.insert(to, item);
                      });
                    },
                  ),
                  _DetailsStep(
                    cat: cat,
                    title: _title,
                    subtitle: _subtitle,
                    desc: _desc,
                    condition: _condition,
                    attrs: _attrs,
                    onCondition: (c) => setState(() => _condition = c),
                    onAttr: () => setState(() {}),
                  ),
                  _PriceStep(
                    price: _price,
                    negotiable: _negotiable,
                    free: _free,
                    bestOffer: _bestOffer,
                    insight: _insight,
                    onPrice: (v) => setState(() => _price = v),
                    onNeg: (v) => setState(() => _negotiable = v),
                    onFree: (v) => setState(() {
                      _free = v;
                      if (v) _bestOffer = false;
                    }),
                    onBest: (v) => setState(() {
                      _bestOffer = v;
                      if (v) _free = false;
                    }),
                  ),
                  _LocationStep(
                    city: _city,
                    phone: _phone,
                    call: _call,
                    wa: _wa,
                    chat: _chat,
                    hide: _hidePhone,
                    onCity: (c) => setState(() => _city = c),
                    onCall: (v) => setState(() => _call = v),
                    onWa: (v) => setState(() => _wa = v),
                    onChat: (v) => setState(() => _chat = v),
                    onHide: (v) => setState(() => _hidePhone = v),
                  ),
                  _ReviewStep(
                    agreed: _agreed,
                    onAgree: (v) => setState(() => _agreed = v),
                    preview: _previewAd(),
                    onEdit: (s) {
                      setState(() => _step = s);
                      _page.jumpToPage(s);
                    },
                  ),
                ],
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Shake(
                  trigger: _shake,
                  child: FilledButton(
                    onPressed: _publishing ? null : _next,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor:
                          _stepValid ? AppColors.green : AppColors.muted,
                    ),
                    child: _publishing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_step == 5 ? l10n.publish : l10n.next),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Ad _previewAd() {
    return Ad(
      id: 'preview',
      source: AdSource.user,
      categoryId: _categoryId ?? 'other',
      subcategoryId: _subId,
      title: _title.text.isEmpty ? 'Untitled' : _title.text,
      description: _desc.text,
      price: _free || _bestOffer ? null : _price,
      isNegotiable: _negotiable || _bestOffer,
      condition: _condition,
      images: _photos,
      city: _city,
      attributes: _attrs,
      seller: SouqController.instance.repo.me,
      createdAt: DateTime.now(),
    );
  }
}

class _CategoryStep extends StatefulWidget {
  const _CategoryStep({
    required this.selectedId,
    required this.subId,
    required this.onSelect,
    required this.onSub,
  });
  final String? selectedId;
  final String? subId;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onSub;

  @override
  State<_CategoryStep> createState() => _CategoryStepState();
}

class _CategoryStepState extends State<_CategoryStep> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final l10n = SouqL10n.of(context);
    final q = SouqFormat.normalizeSearch(_q);
    final cats = SouqCatalog.all.where((c) {
      if (q.isEmpty) return true;
      final blob =
          '${c.nameEn} ${c.nameAr} ${c.subcategories.map((s) => '${s.nameEn} ${s.nameAr}').join()}';
      return SouqFormat.matches(blob, q);
    }).toList();
    final selected =
        widget.selectedId == null ? null : SouqCatalog.byId(widget.selectedId!);
    final showFeatured =
        q.isEmpty && cats.any((c) => c.id == SouqCatalog.cars);
    final gridCats = showFeatured
        ? cats.where((c) => c.id != SouqCatalog.cars).toList()
        : cats;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          decoration: const InputDecoration(
            hintText: 'iPhone, Toyota, villa…',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onChanged: (v) => setState(() => _q = v),
        ),
        const SizedBox(height: 16),
        if (showFeatured) ...[
          SizedBox(
            height: 148,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: widget.selectedId == null ||
                      widget.selectedId == SouqCatalog.cars
                  ? 1
                  : 0.45,
              child: SouqCategoryTile(
                category: SouqCatalog.byId(SouqCatalog.cars),
                featured: true,
                useHero: false,
                selected: widget.selectedId == SouqCatalog.cars,
                onTap: () => widget.onSelect(SouqCatalog.cars),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: gridCats.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.86,
          ),
          itemBuilder: (context, i) {
            final c = gridCats[i];
            return AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: widget.selectedId == null || widget.selectedId == c.id
                  ? 1
                  : 0.45,
              child: SouqCategoryTile(
                category: c,
                useHero: false,
                compact: true,
                selected: widget.selectedId == c.id,
                onTap: () => widget.onSelect(c.id),
              ),
            );
          },
        ),
        if (selected != null) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: selected.subcategories
                .map(
                  (s) => AppFilterChip(
                    selected: widget.subId == s.id,
                    label: s.name(l10n.ar),
                    onSelected: (_) => widget.onSub(s.id),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _PhotosStep extends StatelessWidget {
  const _PhotosStep({
    required this.photos,
    required this.videoPath,
    required this.tips,
    required this.onAdd,
    required this.onAddVideo,
    required this.onClearVideo,
    required this.onRemove,
    required this.onReorder,
  });
  final List<String> photos;
  final String? videoPath;
  final String tips;
  final VoidCallback onAdd;
  final VoidCallback onAddVideo;
  final VoidCallback onClearVideo;
  final ValueChanged<int> onRemove;
  final void Function(int from, int to) onReorder;

  @override
  Widget build(BuildContext context) {
    final l10n = SouqL10n.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (tips.isNotEmpty)
          Text(tips, style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 12),
        ReorderableGrid(
          photos: photos,
          coverLabel: l10n.cover,
          onAdd: onAdd,
          onRemove: onRemove,
          onReorder: onReorder,
        ),
        const SizedBox(height: 16),
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.stroke),
          ),
          leading: Icon(
            videoPath == null
                ? Icons.videocam_outlined
                : Icons.videocam_rounded,
          ),
          title: Text(videoPath == null ? l10n.addVideo : 'Video attached'),
          subtitle: Text(l10n.videoHint),
          trailing: videoPath == null
              ? const Icon(Icons.add_rounded)
              : IconButton(
                  onPressed: onClearVideo,
                  icon: const Icon(Icons.close_rounded),
                ),
          onTap: onAddVideo,
        ),
      ],
    );
  }
}

class ReorderableGrid extends StatelessWidget {
  const ReorderableGrid({
    super.key,
    required this.photos,
    required this.coverLabel,
    required this.onAdd,
    required this.onRemove,
    required this.onReorder,
  });
  final List<String> photos;
  final String coverLabel;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final void Function(int, int) onReorder;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < photos.length; i++)
          LongPressDraggable<int>(
            data: i,
            feedback: Opacity(
              opacity: 0.9,
              child: _Thumb(path: photos[i], size: 104),
            ),
            child: DragTarget<int>(
              onAcceptWithDetails: (d) => onReorder(d.data, i),
              builder: (context, _, __) => Stack(
                children: [
                  _Thumb(path: photos[i], size: 104),
                  if (i == 0)
                    Positioned(
                      left: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        color: AppColors.gold,
                        child: Text(
                          coverLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      onPressed: () => onRemove(i),
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (photos.length < 10)
          InkWell(
            onTap: onAdd,
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.stroke),
                color: AppColors.card,
              ),
              child: const Icon(Icons.add_a_photo_rounded),
            ),
          ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.path, required this.size});
  final String path;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.file(
        File(path),
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    required this.cat,
    required this.title,
    required this.subtitle,
    required this.desc,
    required this.condition,
    required this.attrs,
    required this.onCondition,
    required this.onAttr,
  });
  final SouqCategory? cat;
  final TextEditingController title;
  final TextEditingController subtitle;
  final TextEditingController desc;
  final AdCondition condition;
  final Map<String, dynamic> attrs;
  final ValueChanged<AdCondition> onCondition;
  final VoidCallback onAttr;

  @override
  Widget build(BuildContext context) {
    final l10n = SouqL10n.of(context);
    final suggestion = cat?.id == SouqCatalog.cars
        ? SouqFormat.suggestCarTitle(
            make: attrs['make']?.toString(),
            model: attrs['model']?.toString(),
            year: int.tryParse('${attrs['year'] ?? ''}'),
            mileage: int.tryParse('${attrs['mileage'] ?? ''}'),
          )
        : '';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: title,
          maxLength: 70,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        TextField(
          controller: subtitle,
          maxLength: 90,
          decoration: InputDecoration(labelText: l10n.subtitle),
        ),
        if (suggestion.isNotEmpty)
          ActionChip(
            label: Text('${l10n.useSuggestion}: $suggestion'),
            onPressed: () {
              title.text = suggestion;
              onAttr();
            },
          ),
        const SizedBox(height: 8),
        TextField(
          controller: desc,
          maxLength: 2000,
          minLines: 3,
          maxLines: 8,
          decoration: const InputDecoration(labelText: 'Description'),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: AdCondition.values
              .map(
                (c) => AppFilterChip(
                  selected: condition == c,
                  label: SouqFormat.conditionLabel(c, ar: l10n.ar),
                  onSelected: (_) => onCondition(c),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        if (cat != null)
          for (final field in cat!.fields)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AttrField(field: field, attrs: attrs, onChanged: onAttr),
            ),
      ],
    );
  }
}

class _AttrField extends StatelessWidget {
  const _AttrField({
    required this.field,
    required this.attrs,
    required this.onChanged,
  });
  final AttributeField field;
  final Map<String, dynamic> attrs;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final label = SouqL10n.of(context).ar ? field.labelAr : field.labelEn;
    final value = attrs[field.key];
    switch (field.type) {
      case AttributeType.dropdown:
        return DropdownButtonFormField<String>(
          value: field.options.contains(value) ? value as String? : null,
          decoration: InputDecoration(labelText: label),
          items: field.options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (v) {
            attrs[field.key] = v;
            onChanged();
          },
        );
      case AttributeType.chips:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            Wrap(
              spacing: 8,
              children: field.options
                  .map(
                    (o) => AppFilterChip(
                      selected: value == o,
                      label: o,
                      onSelected: (_) {
                        attrs[field.key] = o;
                        onChanged();
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      case AttributeType.year:
        final years = [for (var y = 2027; y >= 1980; y--) '$y'];
        return DropdownButtonFormField<String>(
          value: value == null ? null : '$value',
          decoration: InputDecoration(labelText: label),
          items: years
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (v) {
            attrs[field.key] = v;
            onChanged();
          },
        );
      case AttributeType.toggle:
        return SwitchListTile(
          title: Text(label),
          value: value == true || value == 'true',
          onChanged: (v) {
            attrs[field.key] = v;
            onChanged();
          },
        );
      case AttributeType.number:
      case AttributeType.text:
      case AttributeType.range:
      case AttributeType.color:
        return TextField(
          decoration: InputDecoration(
            labelText: label,
            suffixText: field.unit,
          ),
          keyboardType: field.type == AttributeType.number
              ? TextInputType.number
              : TextInputType.text,
          onChanged: (v) {
            attrs[field.key] = v;
            onChanged();
          },
        );
    }
  }
}

class _PriceStep extends StatelessWidget {
  const _PriceStep({
    required this.price,
    required this.negotiable,
    required this.free,
    required this.bestOffer,
    required this.insight,
    required this.onPrice,
    required this.onNeg,
    required this.onFree,
    required this.onBest,
  });
  final double? price;
  final bool negotiable;
  final bool free;
  final bool bestOffer;
  final PriceInsight? insight;
  final ValueChanged<double?> onPrice;
  final ValueChanged<bool> onNeg;
  final ValueChanged<bool> onFree;
  final ValueChanged<bool> onBest;

  @override
  Widget build(BuildContext context) {
    final l10n = SouqL10n.of(context);
    final disabled = free || bestOffer;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          SouqFormat.sar(disabled ? null : price, ar: l10n.ar),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          enabled: !disabled,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            suffixText: 'SAR',
            hintText: '0',
          ),
          onChanged: (v) => onPrice(double.tryParse(v.replaceAll(',', ''))),
        ),
        SwitchListTile(
          title: Text(l10n.negotiable),
          value: negotiable,
          onChanged: onNeg,
        ),
        SwitchListTile(
          title: Text(l10n.free),
          value: free,
          onChanged: onFree,
        ),
        SwitchListTile(
          title: Text(l10n.bestOffer),
          value: bestOffer,
          onChanged: onBest,
        ),
        if (insight != null) ...[
          const SizedBox(height: 12),
          Text(
            'Similar cars sell for ${SouqFormat.compactSar(insight!.low)}–${SouqFormat.compactSar(insight!.high)} SAR (${insight!.sample} ads)',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
      ],
    );
  }
}

class _LocationStep extends StatelessWidget {
  const _LocationStep({
    required this.city,
    required this.phone,
    required this.call,
    required this.wa,
    required this.chat,
    required this.hide,
    required this.onCity,
    required this.onCall,
    required this.onWa,
    required this.onChat,
    required this.onHide,
  });
  final String city;
  final TextEditingController phone;
  final bool call;
  final bool wa;
  final bool chat;
  final bool hide;
  final ValueChanged<String> onCity;
  final ValueChanged<bool> onCall;
  final ValueChanged<bool> onWa;
  final ValueChanged<bool> onChat;
  final ValueChanged<bool> onHide;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<String>(
          value: SaudiCities.all.any((c) => c.name == city) ? city : null,
          decoration: const InputDecoration(labelText: 'City'),
          items: SaudiCities.all
              .map((c) => DropdownMenuItem(value: c.name, child: Text(c.name)))
              .toList(),
          onChanged: (v) {
            if (v != null) onCity(v);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            prefixText: '+966 ',
            labelText: '5XXXXXXXX',
          ),
        ),
        SwitchListTile(title: const Text('Phone call'), value: call, onChanged: onCall),
        SwitchListTile(title: const Text('WhatsApp'), value: wa, onChanged: onWa),
        SwitchListTile(title: const Text('In-app chat'), value: chat, onChanged: onChat),
        SwitchListTile(title: const Text('Hide phone number'), value: hide, onChanged: onHide),
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.agreed,
    required this.onAgree,
    required this.preview,
    required this.onEdit,
  });
  final bool agreed;
  final ValueChanged<bool> onAgree;
  final Ad preview;
  final ValueChanged<int> onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = SouqL10n.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SouqAdCard(ad: preview, wide: true, heroPrefix: 'preview'),
        TextButton(onPressed: () => onEdit(2), child: Text(l10n.edit)),
        CheckboxListTile(
          value: agreed,
          onChanged: (v) => onAgree(v ?? false),
          title: Text(l10n.rules),
        ),
      ],
    );
  }
}

class _Success extends StatelessWidget {
  const _Success({required this.ad, required this.l10n});
  final Ad ad;
  final SouqL10n l10n;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              const Icon(Icons.check_circle_rounded, size: 88, color: AppColors.green),
              const SizedBox(height: 12),
              Text(
                l10n.published,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 20),
              SouqAdCard(ad: ad, wide: true, heroPrefix: 'done'),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  openCard(context, const SouqMyAdsScreen());
                },
                child: Text(l10n.myAds),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Share.share(ad.title),
                child: Text(l10n.share),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SouqPostWizardScreen(),
                    ),
                  );
                },
                child: Text(l10n.postAnother),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
