import 'package:flutter/foundation.dart';

class AppTabs {
  static const home = 0;
  static const categories = 1;
  static const souq = 2;
  static const jobs = 3;
  static const eat = 4;
  static const play = 5;
  static const profile = 6;

  static final index = ValueNotifier<int>(home);

  static void go(int value) => index.value = value;
}
