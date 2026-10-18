import '../../../core/result/app_exception.dart';
import '../../../core/result/result.dart';
import '../../models/usuario_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/pessoa_repository.dart';
import '../../repositories/preference_repository.dart';

/// Relaciona o usuário autenticado à pessoa cadastrada que o representa.
/// Passar `null` remove o vínculo.
class VincularPessoaUseCase {
  const VincularPessoaUseCase(
    this._authRepository,
    this._pessoaRepository,
    this._preferences,
  );

  final AuthRepository _authRepository;
  final PessoaRepository _pessoaRepository;
  final PreferenceRepository _preferences;

  Future<Result<UsuarioModel>> call(String? pessoaId) async {
    final atual = _authRepository.usuarioAtual;
    if (atual == null) {
      return const Failure(AppException('Você precisa estar autenticado.'));
    }

    try {
      if (pessoaId != null) {
        final pessoa = await _pessoaRepository.buscarPorId(pessoaId);
        if (pessoa == null) {
          return const Failure(AppException('Pessoa não encontrada.'));
        }
        final dono = await _authRepository.buscarUsuarioVinculado(pessoaId);
        if (dono != null && dono.uid != atual.uid) {
          return const Failure(
            AppException('Esta pessoa já está vinculada a outra conta.'),
          );
        }
      }

      await _authRepository.vincularPessoa(atual.uid, pessoaId);
      final perfil = await _authRepository.buscarUsuario(atual.uid) ?? atual;
      final atualizado = perfil.comPessoaVinculada(pessoaId);
      await _preferences.salvarUsuarioEmCache(atualizado);
      return Success(atualizado);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
