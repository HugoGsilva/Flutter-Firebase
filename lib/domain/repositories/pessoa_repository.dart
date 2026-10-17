import '../models/pessoa_model.dart';

abstract interface class PessoaRepository {
  Future<void> cadastrarPessoa(PessoaModel pessoa);
  Future<void> atualizarPessoa(PessoaModel pessoa);
  Future<void> removerPessoa(String id);
  Future<PessoaModel?> buscarPorId(String id);
  Future<List<PessoaModel>> listarTodas();
}
