import '../../../core/result/app_exception.dart';
import '../../../core/result/result.dart';
import '../../models/usuario_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/preference_repository.dart';

class AtualizarPerfilUseCase {
  const AtualizarPerfilUseCase(this._repository, this._preferences);

  final AuthRepository _repository;
  final PreferenceRepository _preferences;

  Future<Result<UsuarioModel>> call({required String nome}) async {
    if (_repository.usuarioAtual == null) {
      return const Failure(AppException('Você precisa estar autenticado.'));
    }

    final nomeLimpo = nome.trim();
    if (nomeLimpo.length < 3) {
      return const Failure(
        FormatException('O nome deve ter pelo menos 3 caracteres.'),
      );
    }

    try {
      final atualizado = await _repository.atualizarNome(nome: nomeLimpo);
      await _preferences.salvarUsuarioEmCache(atualizado);
      return Success(atualizado);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
