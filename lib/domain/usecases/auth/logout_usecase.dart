import '../../../core/result/result.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/preference_repository.dart';

class LogoutUseCase {
  const LogoutUseCase(this._repository, this._preferences);

  final AuthRepository _repository;
  final PreferenceRepository _preferences;

  Future<Result<void>> call() async {
    try {
      await _repository.logout();
      await _preferences.limparSessao();
      return const Success(null);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
