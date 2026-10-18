import 'package:signals_flutter/signals_flutter.dart';

import '../../core/command/command.dart';
import '../../core/result/result.dart';
import '../../domain/facades/tema_facade.dart';

class ThemeViewModel {
  ThemeViewModel(this._temaFacade) {
    carregarTemaCommand = Command0<bool?>(_carregarTema);
    alternarTemaCommand = Command0<void>(_alternarTema);
  }

  final TemaFacade _temaFacade;

  final isDarkMode = signal<bool>(false);

  late final Command0<bool?> carregarTemaCommand;
  late final Command0<void> alternarTemaCommand;

  Future<Result<bool?>> _carregarTema() async {
    final res = await _temaFacade.obterTemaSalvo();
    if (res case Success(data: final escuro?)) {
      isDarkMode.value = escuro;
    }
    return res;
  }

  Future<Result<void>> _alternarTema() {
    isDarkMode.value = !isDarkMode.value;
    return _temaFacade.alterarTema(isDarkMode.value);
  }
}
