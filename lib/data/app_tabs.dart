import 'package:flutter/foundation.dart';

class AppTabs {
  static const home = 0;
  static const categories = 1;
  static const souq = 2;
  static const eat = 3;
  static const play = 4;
  static const profile = 5;

  static final index = ValueNotifier<int>(home);

  static void go(int value) => index.value = value;
}
