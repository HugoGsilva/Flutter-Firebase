import 'package:signals_flutter/signals_flutter.dart';

import '../../core/result/app_exception.dart';
import '../../core/result/result.dart';

/// Estado de carregamento e de erro compartilhado pelas ViewModels.
abstract class BaseViewModel {
  final isLoading = signal<bool>(false);
  final errorMessage = signal<String?>(null);

  Future<Result<T>> executar<T>(
    Future<Result<T>> Function() acao, {
    void Function(T dados)? aoConcluir,
  }) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final resultado = await acao();
      switch (resultado) {
        case Success(data: final dados):
          aoConcluir?.call(dados);
        case Failure(error: final erro):
          errorMessage.value = mensagemDoErro(erro);
      }
      return resultado;
    } finally {
      isLoading.value = false;
    }
  }

  void limparErro() => errorMessage.value = null;
}
