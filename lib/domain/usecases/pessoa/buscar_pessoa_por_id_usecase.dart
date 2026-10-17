import '../../../core/result/result.dart';
import '../../models/pessoa_model.dart';
import '../../repositories/pessoa_repository.dart';

class BuscarPessoaPorIdUseCase {
  const BuscarPessoaPorIdUseCase(this._repository);

  final PessoaRepository _repository;

  Future<Result<PessoaModel?>> call(String id) async {
    if (id.trim().isEmpty) {
      return const Failure(FormatException('ID inválido.'));
    }

    try {
      final pessoa = await _repository.buscarPorId(id);
      return Success(pessoa);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
