import '../../core/result/app_exception.dart';
import '../../domain/models/usuario_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../errors/firebase_error_mapper.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/google_auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
    this._authService,
    this._googleAuthService,
    this._firestoreService,
  );

  final AuthService _authService;
  final GoogleAuthService _googleAuthService;
  final FirestoreService _firestoreService;

  @override
  UsuarioModel? get usuarioAtual => _authService.currentUser;

  @override
  Future<UsuarioModel> cadastrarComEmail({
    required String nome,
    required String email,
    required String senha,
  }) {
    return comTratamentoFirebase(() async {
      final usuario = await _authService.cadastrarEmailSenha(
        email: email,
        password: senha,
        nome: nome,
      );
      if (usuario == null) {
        throw const AppException('Falha ao cadastrar usuário.');
      }
      await _firestoreService.salvarUsuario(usuario);
      return usuario;
    });
  }

  @override
  Future<UsuarioModel> loginComEmail({
    required String email,
    required String senha,
  }) {
    return comTratamentoFirebase(() async {
      final usuario = await _authService.loginEmailSenha(
        email: email,
        password: senha,
      );
      if (usuario == null) {
        throw const AppException('E-mail ou senha incorretos.');
      }
      return _sincronizarPerfil(usuario);
    });
  }

  @override
  Future<UsuarioModel> loginComGoogle() {
    return comTratamentoFirebase(() async {
      final usuario = await _googleAuthService.login();
      if (usuario == null) {
        throw const AppException('Falha na autenticação com o Google.');
      }
      return _sincronizarPerfil(usuario);
    });
  }

  @override
  Future<void> logout() {
    return comTratamentoFirebase(_authService.logout);
  }

  @override
  Future<UsuarioModel?> restaurarSessao() {
    return comTratamentoFirebase(() async {
      final usuario = await _authService.aguardarEstadoInicial();
      if (usuario == null) return null;
      return _sincronizarPerfil(usuario);
    });
  }

  @override
  Future<UsuarioModel?> buscarUsuario(String uid) {
    return comTratamentoFirebase(() => _firestoreService.obterUsuario(uid));
  }

  @override
  Future<UsuarioModel?> buscarUsuarioVinculado(String pessoaId) {
    return comTratamentoFirebase(
      () => _firestoreService.buscarUsuarioPorPessoa(pessoaId),
    );
  }

  @override
  Future<void> vincularPessoa(String uid, String? pessoaId) {
    return comTratamentoFirebase(
      () => _firestoreService.atualizarPessoaVinculada(uid, pessoaId),
    );
  }

  /// Mantém o documento em `usuarios` atualizado com os dados do Firebase
  /// Authentication e devolve o perfil com o vínculo de pessoa salvo.
  Future<UsuarioModel> _sincronizarPerfil(UsuarioModel usuario) async {
    final salvo = await _firestoreService.obterUsuario(usuario.uid);
    final atualizado = usuario.copyWith(
      nome: usuario.nome.isNotEmpty ? usuario.nome : salvo?.nome,
    );
    await _firestoreService.salvarUsuario(atualizado);
    return atualizado.comPessoaVinculada(salvo?.pessoaId);
  }
}
