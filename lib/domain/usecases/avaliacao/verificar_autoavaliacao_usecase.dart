import '../../../core/result/result.dart';

class VerificarAutoavaliacaoUseCase {
  const VerificarAutoavaliacaoUseCase();

  Result<bool> call({
    required String avaliadorUid,
    required String pessoaCriadorUid,
    String? pessoaId,
  }) {
    if (avaliadorUid.isEmpty) {
      return const Failure(FormatException('Avaliador UID não pode ser vazio.'));
    }

    final isAutoavaliacao = avaliadorUid == pessoaCriadorUid ||
        (pessoaId != null && avaliadorUid == pessoaId);

    return Success(isAutoavaliacao);
  }
}
