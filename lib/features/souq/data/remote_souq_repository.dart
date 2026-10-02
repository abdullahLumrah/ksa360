import '../domain/souq_models.dart';
import '../domain/souq_repository.dart';

/// Networked backend stub. Wire Firebase / Supabase / REST here without
/// touching presentation code — swap in [SouqController].
class RemoteSouqRepository implements SouqRepository {
  RemoteSouqRepository({this.baseUrl = 'https://api.example.com/souq'});

  final String baseUrl;

  Never _todo() => throw UnimplementedError(
        'RemoteSouqRepository is a stub. Implement REST/Firebase calls, '
        'then construct SouqController with this repository. Endpoint root: $baseUrl',
      );

  @override
  Future<void> ready() => _todo();

  @override
  Future<PagedAds> search(SearchFilters filters, {int page = 0, int pageSize = 20}) =>
      _todo();

  @override
  Future<int> count(SearchFilters filters) => _todo();

  @override
  Future<Ad?> byId(String id) => _todo();

  @override
  Future<List<Ad>> featuredCars({int limit = 8}) => _todo();

  @override
  Future<List<Ad>> recentlyAdded({int limit = 24}) => _todo();

  @override
  Future<List<Ad>> nearCity(String city, {int limit = 12}) => _todo();

  @override
  Future<List<Ad>> similarTo(Ad ad, {int limit = 8}) => _todo();

  @override
  Future<List<Ad>> bySeller(String sellerId) => _todo();

  @override
  Future<List<String>> makes() => _todo();

  @override
  Future<PriceInsight?> priceInsight({
    required String make,
    String? model,
    int? year,
  }) =>
      _todo();

  @override
  Future<List<double>> priceHistogram(SearchFilters filters) => _todo();

  @override
  Future<List<String>> suggest(String query) => _todo();

  @override
  Future<Ad> publish(Ad ad) => _todo();

  @override
  Future<Ad> update(Ad ad) => _todo();

  @override
  Future<void> delete(String id) => _todo();

  @override
  Future<void> markStatus(String id, AdStatus status) => _todo();

  @override
  Future<void> bumpViews(String id) => _todo();

  @override
  Set<String> get favoriteIds => _todo();

  @override
  Future<void> toggleFavorite(String id) => _todo();

  @override
  List<Ad> get myAds => _todo();

  @override
  AdDraft? get draft => _todo();

  @override
  Future<void> saveDraft(AdDraft draft) => _todo();

  @override
  Future<void> clearDraft() => _todo();

  @override
  List<SavedSearch> get savedSearches => _todo();

  @override
  Future<void> saveSearch(SavedSearch search) => _todo();

  @override
  Future<void> deleteSearch(String id) => _todo();

  @override
  SellerInfo get me => _todo();

  @override
  Future<void> updateMe(SellerInfo me) => _todo();

  @override
  List<SouqConversation> get conversations => _todo();

  @override
  Future<SouqConversation> openChat({required Ad ad, String? firstMessage}) =>
      _todo();

  @override
  Future<void> sendMessage(String conversationId, String text) => _todo();
}
