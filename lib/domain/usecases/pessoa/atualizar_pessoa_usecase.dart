import '../../../core/result/result.dart';
import '../../models/pessoa_model.dart';
import '../../repositories/pessoa_repository.dart';

class AtualizarPessoaUseCase {
  const AtualizarPessoaUseCase(this._repository);

  final PessoaRepository _repository;

  Future<Result<void>> call(PessoaModel pessoa) async {
    final nomeLimpo = pessoa.nome.trim();
    if (nomeLimpo.isEmpty) {
      return const Failure(FormatException('O nome não pode ser vazio.'));
    }

    if (!PessoaModel.isCursoValido(pessoa.curso)) {
      return Failure(
        FormatException(
          'Curso inválido. Escolha um dos cursos: ${PessoaModel.cursosValidos.join(", ")}.',
        ),
      );
    }

    if (!PessoaModel.isTurmaValida(pessoa.turma)) {
      return Failure(
        FormatException(
          'Turma/Ano deve estar entre ${PessoaModel.turmaAnoMinimo} e ${PessoaModel.turmaAnoMaximo}.',
        ),
      );
    }

    try {
      await _repository.atualizarPessoa(
        pessoa.copyWith(
          nome: nomeLimpo,
          apelido: pessoa.apelido.trim(),
          curso: pessoa.curso.toUpperCase().trim(),
        ),
      );
      return const Success(null);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
