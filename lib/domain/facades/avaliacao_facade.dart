import '../../core/result/result.dart';
import '../models/avaliacao_model.dart';
import '../usecases/avaliacao/alterar_avaliacao_usecase.dart';
import '../usecases/avaliacao/consultar_avaliacao_usecase.dart';
import '../usecases/avaliacao/listar_avaliacoes_usuario_usecase.dart';
import '../usecases/avaliacao/registrar_avaliacao_usecase.dart';
import '../usecases/avaliacao/verificar_autoavaliacao_usecase.dart';

class AvaliacaoFacade {
  const AvaliacaoFacade({
    required this.registrarAvaliacaoUseCase,
    required this.alterarAvaliacaoUseCase,
    required this.consultarAvaliacaoUseCase,
    required this.listarAvaliacoesUsuarioUseCase,
    required this.verificarAutoavaliacaoUseCase,
  });

  final RegistrarAvaliacaoUseCase registrarAvaliacaoUseCase;
  final AlterarAvaliacaoUseCase alterarAvaliacaoUseCase;
  final ConsultarAvaliacaoUseCase consultarAvaliacaoUseCase;
  final ListarAvaliacoesUsuarioUseCase listarAvaliacoesUsuarioUseCase;
  final VerificarAutoavaliacaoUseCase verificarAutoavaliacaoUseCase;

  Future<Result<AvaliacaoModel>> avaliar({
    required String pessoaId,
    required Map<String, int> notas,
  }) {
    return registrarAvaliacaoUseCase(pessoaId: pessoaId, notas: notas);
  }

  Future<Result<AvaliacaoModel>> alterarAvaliacao({
    required String pessoaId,
    required Map<String, int> notas,
  }) {
    return alterarAvaliacaoUseCase(pessoaId: pessoaId, notas: notas);
  }

  Future<Result<AvaliacaoModel?>> consultarAvaliacao(String pessoaId) {
    return consultarAvaliacaoUseCase(pessoaId);
  }

  Future<Result<List<AvaliacaoModel>>> carregarAvaliacoes() {
    return listarAvaliacoesUsuarioUseCase();
  }

  Future<Result<bool>> verificarAutoavaliacao(String pessoaId) {
    return verificarAutoavaliacaoUseCase(pessoaId);
  }
}
