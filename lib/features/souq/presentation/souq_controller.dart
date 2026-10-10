import 'package:flutter/foundation.dart';

import '../data/local_souq_repository.dart';
import '../domain/souq_models.dart';
import '../domain/souq_repository.dart';

class SouqController extends ChangeNotifier {
  SouqController({SouqRepository? repository})
      : repo = repository ?? LocalSouqRepository();

  static final instance = SouqController();

  final SouqRepository repo;
  bool ready = false;
  String? loadError;

  Future<void>? _readyJob;

  Future<void> ensureReady() {
    return _readyJob ??= _ensureReady();
  }

  Future<void> _ensureReady() async {
    try {
      await repo.ready();
      ready = true;
      loadError = null;
    } catch (e) {
      loadError = '$e';
      _readyJob = null;
    }
    notifyListeners();
  }

  bool isFavorite(String id) => repo.favoriteIds.contains(id);

  Future<void> toggleFavorite(String id) async {
    await repo.toggleFavorite(id);
    notifyListeners();
  }

  Future<PagedAds> search(SearchFilters filters, {int page = 0}) {
    return repo.search(filters, page: page);
  }

  Future<Ad> publish(Ad ad) async {
    final saved = await repo.publish(ad);
    await repo.clearDraft();
    if (repo is LocalSouqRepository) {
      await (repo as LocalSouqRepository).refreshMine();
    }
    notifyListeners();
    return saved;
  }

  Future<void> refreshMine() async {
    if (repo is LocalSouqRepository) {
      await (repo as LocalSouqRepository).refreshMine();
    }
    notifyListeners();
  }

  Future<List<Ad>> favoriteAds() async {
    if (repo is LocalSouqRepository) {
      return (repo as LocalSouqRepository).favoriteAds();
    }
    return const [];
  }

  Future<void> refreshChats({String? adId}) async {
    if (repo is LocalSouqRepository) {
      await (repo as LocalSouqRepository).refreshChats(adId: adId);
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    if (repo is LocalSouqRepository) {
      await (repo as LocalSouqRepository).refreshCatalog();
    }
    notifyListeners();
  }

  List<Ad> quickSearch(String query, {int limit = 8}) {
    if (repo is LocalSouqRepository) {
      return (repo as LocalSouqRepository).quickSearch(query, limit: limit);
    }
    return const [];
  }
}
