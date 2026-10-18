import '../../core/result/result.dart';
import '../models/pessoa_model.dart';
import '../usecases/pessoa/atualizar_pessoa_usecase.dart';
import '../usecases/pessoa/buscar_pessoa_por_id_usecase.dart';
import '../usecases/pessoa/cadastrar_pessoa_usecase.dart';
import '../usecases/pessoa/listar_pessoas_usecase.dart';
import '../usecases/pessoa/remover_pessoa_usecase.dart';

class PessoaFacade {
  const PessoaFacade({
    required this.cadastrarPessoaUseCase,
    required this.atualizarPessoaUseCase,
    required this.removerPessoaUseCase,
    required this.listarPessoasUseCase,
    required this.buscarPessoaPorIdUseCase,
  });

  final CadastrarPessoaUseCase cadastrarPessoaUseCase;
  final AtualizarPessoaUseCase atualizarPessoaUseCase;
  final RemoverPessoaUseCase removerPessoaUseCase;
  final ListarPessoasUseCase listarPessoasUseCase;
  final BuscarPessoaPorIdUseCase buscarPessoaPorIdUseCase;

  Future<Result<PessoaModel>> cadastrar(PessoaModel pessoa) {
    return cadastrarPessoaUseCase(pessoa);
  }

  Future<Result<PessoaModel?>> buscar(String id) {
    return buscarPessoaPorIdUseCase(id);
  }

  Future<Result<List<PessoaModel>>> listar() => listarPessoasUseCase();

  Future<Result<PessoaModel>> alterar(PessoaModel pessoa) {
    return atualizarPessoaUseCase(pessoa);
  }

  Future<Result<void>> remover(String id, {required bool confirmado}) {
    return removerPessoaUseCase(id, confirmado: confirmado);
  }
}
