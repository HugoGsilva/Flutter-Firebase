import '../../../core/result/result.dart';
import '../../repositories/preference_repository.dart';

class SalvarTemaUseCase {
  const SalvarTemaUseCase(this._repository);

  final PreferenceRepository _repository;

  Future<Result<void>> call(bool isDark) async {
    try {
      await _repository.salvarTemaEscuro(isDark);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
