import '../../domain/models/pessoa_model.dart';
import '../../domain/repositories/pessoa_repository.dart';
import '../errors/firebase_error_mapper.dart';
import '../services/firestore_service.dart';

class PessoaRepositoryImpl implements PessoaRepository {
  PessoaRepositoryImpl(this._firestoreService);

  final FirestoreService _firestoreService;

  @override
  Future<PessoaModel> cadastrarPessoa(PessoaModel pessoa) {
    return comTratamentoFirebase(() async {
      final id = await _firestoreService.salvarPessoa(pessoa);
      return pessoa.copyWith(id: id);
    });
  }

  @override
  Future<void> atualizarPessoa(PessoaModel pessoa) {
    return comTratamentoFirebase(
      () => _firestoreService.atualizarPessoa(pessoa),
    );
  }

  @override
  Future<void> removerPessoa(String id) {
    return comTratamentoFirebase(() => _firestoreService.removerPessoa(id));
  }

  @override
  Future<PessoaModel?> buscarPorId(String id) {
    return comTratamentoFirebase(() => _firestoreService.obterPessoa(id));
  }

  @override
  Future<List<PessoaModel>> listarTodas() {
    return comTratamentoFirebase(_firestoreService.listarPessoas);
  }
}
