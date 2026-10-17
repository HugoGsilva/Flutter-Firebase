import 'package:flutter/foundation.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../core/command/command.dart';
import '../../core/result/result.dart';
import '../../domain/facades/tema_facade.dart';

class ThemeViewModel extends ChangeNotifier {
  ThemeViewModel(this._temaFacade) {
    isDarkMode = signal<bool>(false);

    carregarTemaCommand = Command0<bool?>(_carregarTemaInternal);
    toggleThemeCommand = Command0<void>(_toggleThemeInternal);
  }

  final TemaFacade _temaFacade;

  late final Signal<bool> isDarkMode;

  late final Command0<bool?> carregarTemaCommand;
  late final Command0<void> toggleThemeCommand;

  Future<Result<bool?>> _carregarTemaInternal() async {
    final res = await _temaFacade.obterTemaSalvo();
    if (res case Success(data: final dark)) {
      if (dark != null) {
        isDarkMode.value = dark;
      }
    }
    notifyListeners();
    return res;
  }

  Future<Result<void>> _toggleThemeInternal() async {
    final novoModo = !isDarkMode.value;
    isDarkMode.value = novoModo;
    notifyListeners();
    return _temaFacade.salvarTema(novoModo);
  }

  Future<void> carregarTema() => carregarTemaCommand.execute();
  Future<void> toggleTheme() => toggleThemeCommand.execute();
}
