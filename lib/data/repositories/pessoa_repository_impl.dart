import '../../domain/models/pessoa_model.dart';
import '../../domain/repositories/pessoa_repository.dart';
import '../services/firestore_service.dart';

class PessoaRepositoryImpl implements PessoaRepository {
  PessoaRepositoryImpl(this._firestoreService);

  final FirestoreService _firestoreService;

  @override
  Future<void> cadastrarPessoa(PessoaModel pessoa) async {
    await _firestoreService.salvarPessoa(pessoa);
  }

  @override
  Future<void> atualizarPessoa(PessoaModel pessoa) async {
    await _firestoreService.atualizarPessoa(pessoa);
  }

  @override
  Future<void> removerPessoa(String id) async {
    await _firestoreService.removerPessoa(id);
  }

  @override
  Future<PessoaModel?> buscarPorId(String id) async {
    return _firestoreService.obterPessoa(id);
  }

  @override
  Future<List<PessoaModel>> listarTodas() async {
    return _firestoreService.listarPessoas();
  }
}
