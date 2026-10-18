import '../models/pessoa_model.dart';

abstract interface class PessoaRepository {
  /// Persiste a pessoa e retorna o registro com o identificador gerado.
  Future<PessoaModel> cadastrarPessoa(PessoaModel pessoa);
  Future<void> atualizarPessoa(PessoaModel pessoa);

  /// Remove a pessoa e as avaliações que ela recebeu.
  Future<void> removerPessoa(String id);
  Future<PessoaModel?> buscarPorId(String id);
  Future<List<PessoaModel>> listarTodas();
}
