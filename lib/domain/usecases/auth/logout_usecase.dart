import '../../../core/result/result.dart';
import '../../repositories/auth_repository.dart';

class LogoutUseCase {
  const LogoutUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call() async {
    try {
      await _repository.logout();
      return const Success(null);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
