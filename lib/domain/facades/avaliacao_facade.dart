import '../../core/result/result.dart';
import '../models/avaliacao_model.dart';
import '../usecases/avaliacao/buscar_avaliacao_usuario_usecase.dart';
import '../usecases/avaliacao/salvar_avaliacao_usecase.dart';
import '../usecases/avaliacao/verificar_autoavaliacao_usecase.dart';

class AvaliacaoFacade {
  const AvaliacaoFacade({
    required this.salvarAvaliacaoUseCase,
    required this.buscarAvaliacaoUsuarioUseCase,
    required this.verificarAutoavaliacaoUseCase,
  });

  final SalvarAvaliacaoUseCase salvarAvaliacaoUseCase;
  final BuscarAvaliacaoUsuarioUseCase buscarAvaliacaoUsuarioUseCase;
  final VerificarAutoavaliacaoUseCase verificarAutoavaliacaoUseCase;

  Future<Result<void>> salvarAvaliacao(
    AvaliacaoModel avaliacao, {
    String? pessoaCriadorUid,
  }) {
    return salvarAvaliacaoUseCase(
      avaliacao,
      pessoaCriadorUid: pessoaCriadorUid,
    );
  }

  Future<Result<AvaliacaoModel?>> buscarAvaliacao({
    required String avaliadorUid,
    required String pessoaId,
  }) {
    return buscarAvaliacaoUsuarioUseCase(
      avaliadorUid: avaliadorUid,
      pessoaId: pessoaId,
    );
  }

  Result<bool> verificarAutoavaliacao({
    required String avaliadorUid,
    required String pessoaCriadorUid,
    String? pessoaId,
  }) {
    return verificarAutoavaliacaoUseCase(
      avaliadorUid: avaliadorUid,
      pessoaCriadorUid: pessoaCriadorUid,
      pessoaId: pessoaId,
    );
  }
}
