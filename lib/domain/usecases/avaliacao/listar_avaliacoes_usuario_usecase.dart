import '../../../core/result/app_exception.dart';
import '../../../core/result/result.dart';
import '../../models/avaliacao_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/avaliacao_repository.dart';

/// Avaliações realizadas pelo usuário autenticado.
class ListarAvaliacoesUsuarioUseCase {
  const ListarAvaliacoesUsuarioUseCase(this._repository, this._authRepository);

  final AvaliacaoRepository _repository;
  final AuthRepository _authRepository;

  Future<Result<List<AvaliacaoModel>>> call() async {
    final atual = _authRepository.usuarioAtual;
    if (atual == null) {
      return const Failure(AppException('Você precisa estar autenticado.'));
    }

    try {
      return Success(await _repository.listarPorAvaliador(atual.uid));
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
