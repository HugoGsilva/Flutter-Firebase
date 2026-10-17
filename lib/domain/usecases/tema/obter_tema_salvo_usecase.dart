import '../../../core/result/result.dart';
import '../../repositories/preference_repository.dart';

class ObterTemaSalvoUseCase {
  const ObterTemaSalvoUseCase(this._repository);

  final PreferenceRepository _repository;

  Future<Result<bool?>> call() async {
    try {
      final temaEscuro = await _repository.obterTemaEscuro();
      return Success(temaEscuro);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
