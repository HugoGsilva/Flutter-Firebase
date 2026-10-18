import '../../../core/result/app_exception.dart';
import '../../../core/result/result.dart';
import '../../repositories/auth_repository.dart';

/// Indica se a pessoa informada é a própria pessoa vinculada ao usuário
/// autenticado.
class VerificarAutoavaliacaoUseCase {
  const VerificarAutoavaliacaoUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<Result<bool>> call(String pessoaId) async {
    final atual = _authRepository.usuarioAtual;
    if (atual == null) {
      return const Failure(
        AppException('Você precisa estar autenticado para avaliar.'),
      );
    }

    try {
      final perfil = await _authRepository.buscarUsuario(atual.uid);
      return Success(perfil?.pessoaId == pessoaId);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
