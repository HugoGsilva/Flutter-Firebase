import '../../../core/result/app_exception.dart';
import '../../../core/result/result.dart';
import '../../models/pessoa_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/pessoa_repository.dart';

class CadastrarPessoaUseCase {
  const CadastrarPessoaUseCase(this._repository, this._authRepository);

  final PessoaRepository _repository;
  final AuthRepository _authRepository;

  /// O cadastro da pessoa não cria nenhuma conta de autenticação; apenas
  /// registra quem fez o cadastro em `criadoPor`.
  Future<Result<PessoaModel>> call(PessoaModel pessoa) async {
    final usuario = _authRepository.usuarioAtual;
    if (usuario == null) {
      return const Failure(
        AppException('Você precisa estar autenticado para cadastrar.'),
      );
    }

    final erro = pessoa.validar();
    if (erro != null) return Failure(FormatException(erro));

    try {
      final salva = await _repository.cadastrarPessoa(
        pessoa.normalizada().copyWith(id: '', criadoPor: usuario.uid),
      );
      return Success(salva);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
