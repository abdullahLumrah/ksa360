import 'package:flutter/foundation.dart';

class AppTabs {
  static const home = 0;
  static const categories = 1;
  /// Bottom-nav Marketplace tab (historically named Souq).
  static const marketplace = 2;
  static const souq = marketplace;
  static const community = 3;
  static const play = 4;
  static const profile = 5;

  static final index = ValueNotifier<int>(home);

  /// When set, HomeShell switches to Marketplace and opens this category.
  static final pendingMarketplaceCategory = ValueNotifier<String?>(null);

  static void go(int value) => index.value = value;

  /// Jump to the Marketplace tab and open [categoryId] (e.g. cars).
  static void openMarketplaceCategory(String categoryId) {
    pendingMarketplaceCategory.value = categoryId;
    go(marketplace);
  }
}
