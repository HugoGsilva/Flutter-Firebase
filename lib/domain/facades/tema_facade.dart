import '../../core/result/result.dart';
import '../usecases/tema/obter_tema_salvo_usecase.dart';
import '../usecases/tema/salvar_tema_usecase.dart';

class TemaFacade {
  const TemaFacade({
    required this.obterTemaSalvoUseCase,
    required this.salvarTemaUseCase,
  });

  final ObterTemaSalvoUseCase obterTemaSalvoUseCase;
  final SalvarTemaUseCase salvarTemaUseCase;

  Future<Result<bool?>> obterTemaSalvo() => obterTemaSalvoUseCase();

  Future<Result<void>> alterarTema(bool escuro) => salvarTemaUseCase(escuro);
}
