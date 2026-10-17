import 'package:flutter/foundation.dart';
import 'package:signals_flutter/signals_flutter.dart';

class HomeViewModel extends ChangeNotifier {
  final currentTab = signal<int>(0);

  void setTab(int index) {
    currentTab.value = index;
    notifyListeners();
  }
}
