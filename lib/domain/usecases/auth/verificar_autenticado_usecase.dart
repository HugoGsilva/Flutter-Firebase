import '../../../core/result/result.dart';
import '../../models/usuario_model.dart';
import '../../repositories/auth_repository.dart';

class VerificarAutenticadoUseCase {
  const VerificarAutenticadoUseCase(this._repository);

  final AuthRepository _repository;

  Result<UsuarioModel?> call() {
    try {
      return Success(_repository.usuarioAtual);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
