import '../../../core/result/result.dart';
import '../../models/pessoa_model.dart';
import '../../repositories/pessoa_repository.dart';

class ListarPessoasUseCase {
  const ListarPessoasUseCase(this._repository);

  final PessoaRepository _repository;

  Future<Result<List<PessoaModel>>> call() async {
    try {
      final pessoas = await _repository.listarTodas();
      return Success(pessoas);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
