import '../../../core/result/app_exception.dart';
import '../../../core/result/result.dart';
import '../../models/avaliacao_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/avaliacao_repository.dart';

/// Busca a avaliação que o usuário autenticado fez para a pessoa informada.
class ConsultarAvaliacaoUseCase {
  const ConsultarAvaliacaoUseCase(this._repository, this._authRepository);

  final AvaliacaoRepository _repository;
  final AuthRepository _authRepository;

  Future<Result<AvaliacaoModel?>> call(String pessoaId) async {
    final atual = _authRepository.usuarioAtual;
    if (atual == null) {
      return const Failure(AppException('Você precisa estar autenticado.'));
    }
    if (pessoaId.trim().isEmpty) {
      return const Failure(FormatException('Pessoa não informada.'));
    }

    try {
      return Success(await _repository.buscarAvaliacao(atual.uid, pessoaId));
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
