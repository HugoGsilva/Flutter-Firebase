import '../../domain/models/avaliacao_model.dart';
import '../../domain/repositories/avaliacao_repository.dart';
import '../errors/firebase_error_mapper.dart';
import '../services/firestore_service.dart';

class AvaliacaoRepositoryImpl implements AvaliacaoRepository {
  AvaliacaoRepositoryImpl(this._firestoreService);

  final FirestoreService _firestoreService;

  @override
  Future<void> salvarAvaliacao(AvaliacaoModel avaliacao) {
    return comTratamentoFirebase(
      () => _firestoreService.salvarAvaliacao(avaliacao),
    );
  }

  @override
  Future<AvaliacaoModel?> buscarAvaliacao(
    String avaliadorUid,
    String pessoaId,
  ) {
    return comTratamentoFirebase(
      () => _firestoreService.obterAvaliacao(avaliadorUid, pessoaId),
    );
  }

  @override
  Future<List<AvaliacaoModel>> listarPorPessoa(String pessoaId) {
    return comTratamentoFirebase(
      () => _firestoreService.listarAvaliacoesPorPessoa(pessoaId),
    );
  }

  @override
  Future<List<AvaliacaoModel>> listarPorAvaliador(String avaliadorUid) {
    return comTratamentoFirebase(
      () => _firestoreService.listarAvaliacoesPorAvaliador(avaliadorUid),
    );
  }

  @override
  Future<List<AvaliacaoModel>> listarTodas() {
    return comTratamentoFirebase(_firestoreService.listarTodasAvaliacoes);
  }
}
