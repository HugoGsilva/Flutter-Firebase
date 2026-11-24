import 'dart:typed_data';

import '../../core/result/result.dart';
import '../models/usuario_model.dart';
import '../usecases/auth/alterar_senha_usecase.dart';
import '../usecases/auth/atualizar_foto_perfil_usecase.dart';
import '../usecases/auth/atualizar_perfil_usecase.dart';
import '../usecases/auth/cadastrar_usuario_usecase.dart';
import '../usecases/auth/login_email_usecase.dart';
import '../usecases/auth/login_google_usecase.dart';
import '../usecases/auth/logout_usecase.dart';
import '../usecases/auth/recuperar_senha_usecase.dart';
import '../usecases/auth/remover_foto_perfil_usecase.dart';
import '../usecases/auth/verificar_autenticado_usecase.dart';
import '../usecases/auth/vincular_pessoa_usecase.dart';

class AuthFacade {
  const AuthFacade({
    required this.cadastrarUsuarioUseCase,
    required this.loginEmailUseCase,
    required this.loginGoogleUseCase,
    required this.logoutUseCase,
    required this.verificarAutenticadoUseCase,
    required this.vincularPessoaUseCase,
    required this.atualizarPerfilUseCase,
    required this.atualizarFotoPerfilUseCase,
    required this.removerFotoPerfilUseCase,
    required this.alterarSenhaUseCase,
    required this.recuperarSenhaUseCase,
  });

  final CadastrarUsuarioUseCase cadastrarUsuarioUseCase;
  final LoginEmailUseCase loginEmailUseCase;
  final LoginGoogleUseCase loginGoogleUseCase;
  final LogoutUseCase logoutUseCase;
  final VerificarAutenticadoUseCase verificarAutenticadoUseCase;
  final VincularPessoaUseCase vincularPessoaUseCase;
  final AtualizarPerfilUseCase atualizarPerfilUseCase;
  final AtualizarFotoPerfilUseCase atualizarFotoPerfilUseCase;
  final RemoverFotoPerfilUseCase removerFotoPerfilUseCase;
  final AlterarSenhaUseCase alterarSenhaUseCase;
  final RecuperarSenhaUseCase recuperarSenhaUseCase;

  Future<Result<UsuarioModel>> criarConta({
    required String nome,
    required String email,
    required String senha,
  }) {
    return cadastrarUsuarioUseCase(nome: nome, email: email, senha: senha);
  }

  Future<Result<UsuarioModel>> login({
    required String email,
    required String senha,
  }) {
    return loginEmailUseCase(email: email, senha: senha);
  }

  Future<Result<UsuarioModel>> loginComGoogle() => loginGoogleUseCase();

  Future<Result<UsuarioModel?>> verificarAutenticacao() {
    return verificarAutenticadoUseCase();
  }

  Future<UsuarioModel?> usuarioEmCache() {
    return verificarAutenticadoUseCase.usuarioEmCache();
  }

  Future<Result<void>> logout() => logoutUseCase();

  Future<Result<UsuarioModel>> vincularPessoa(String? pessoaId) {
    return vincularPessoaUseCase(pessoaId);
  }

  Future<Result<UsuarioModel>> atualizarNome({required String nome}) {
    return atualizarPerfilUseCase(nome: nome);
  }

  Future<Result<UsuarioModel>> atualizarFotoPerfil({
    required Uint8List bytes,
    required String nomeArquivo,
    required String mimeType,
  }) {
    return atualizarFotoPerfilUseCase(
      bytes: bytes,
      nomeArquivo: nomeArquivo,
      mimeType: mimeType,
    );
  }

  Future<Result<UsuarioModel>> removerFotoPerfil() {
    return removerFotoPerfilUseCase();
  }

  Future<Result<void>> alterarSenha({
    required String senhaAtual,
    required String novaSenha,
    required String confirmacaoSenha,
  }) {
    return alterarSenhaUseCase(
      senhaAtual: senhaAtual,
      novaSenha: novaSenha,
      confirmacaoSenha: confirmacaoSenha,
    );
  }

  Future<Result<void>> recuperarSenha({required String email}) {
    return recuperarSenhaUseCase(email: email);
  }
}
