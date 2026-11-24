import 'package:signals_flutter/signals_flutter.dart';

class HomeViewModel {
  static const int abaPessoas = 0;
  static const int abaRankingPessoal = 1;
  static const int abaRankingGlobal = 2;
  static const int abaPerfil = 3;
  static const int abaSobre = 4;

  final currentTab = signal<int>(abaPessoas);

  void setTab(int index) => currentTab.value = index;
}
