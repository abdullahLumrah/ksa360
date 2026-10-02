import '../domain/souq_models.dart';

abstract class SouqRepository {
  Future<void> ready();

  Future<PagedAds> search(SearchFilters filters, {int page = 0, int pageSize = 20});

  Future<int> count(SearchFilters filters);

  Future<Ad?> byId(String id);

  Future<List<Ad>> featuredCars({int limit = 8});

  Future<List<Ad>> recentlyAdded({int limit = 24});

  Future<List<Ad>> nearCity(String city, {int limit = 12});

  Future<List<Ad>> similarTo(Ad ad, {int limit = 8});

  Future<List<Ad>> bySeller(String sellerId);

  Future<List<String>> makes();

  Future<PriceInsight?> priceInsight({
    required String make,
    String? model,
    int? year,
  });

  Future<List<double>> priceHistogram(SearchFilters filters);

  Future<List<String>> suggest(String query);

  Future<Ad> publish(Ad ad);

  Future<Ad> update(Ad ad);

  Future<void> delete(String id);

  Future<void> markStatus(String id, AdStatus status);

  Future<void> bumpViews(String id);

  Set<String> get favoriteIds;

  Future<void> toggleFavorite(String id);

  List<Ad> get myAds;

  AdDraft? get draft;

  Future<void> saveDraft(AdDraft draft);

  Future<void> clearDraft();

  List<SavedSearch> get savedSearches;

  Future<void> saveSearch(SavedSearch search);

  Future<void> deleteSearch(String id);

  SellerInfo get me;

  Future<void> updateMe(SellerInfo me);

  List<SouqConversation> get conversations;

  Future<SouqConversation> openChat({required Ad ad, String? firstMessage});

  Future<void> sendMessage(String conversationId, String text);

  /// Swap this for a networked implementation later.
  static const backendNote = '''
Plug a real backend by implementing SouqRepository (Firebase / Supabase / REST).
Keep LocalSouqRepository for cache + Haraj seed. See RemoteSouqRepository.
''';
}
