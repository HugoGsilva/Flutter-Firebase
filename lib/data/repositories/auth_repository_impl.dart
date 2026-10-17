import '../../domain/models/usuario_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._authService, this._firestoreService);

  final AuthService _authService;
  final FirestoreService _firestoreService;

  @override
  UsuarioModel? get usuarioAtual => _authService.currentUser;

  @override
  Stream<UsuarioModel?> get authStateChanges => _authService.authStateChanges;

  @override
  Future<UsuarioModel> cadastrarComEmail({
    required String nome,
    required String email,
    required String senha,
  }) async {
    final usuario = await _authService.cadastrarEmailSenha(
      email: email,
      password: senha,
      nome: nome,
    );

    if (usuario == null) {
      throw Exception('Falha ao cadastrar usuário com e-mail e senha.');
    }

    await _firestoreService.salvarUsuario(usuario);
    return usuario;
  }

  @override
  Future<UsuarioModel> loginComEmail({
    required String email,
    required String senha,
  }) async {
    final usuario = await _authService.loginEmailSenha(
      email: email,
      password: senha,
    );

    if (usuario == null) {
      throw Exception('Usuário não encontrado ou credenciais inválidas.');
    }

    final salvo = await _firestoreService.obterUsuario(usuario.uid);
    if (salvo == null) {
      await _firestoreService.salvarUsuario(usuario);
      return usuario;
    }

    return salvo;
  }

  @override
  Future<UsuarioModel> loginComGoogle() async {
    final usuario = await _authService.loginGoogle();

    if (usuario == null) {
      throw Exception('Falha na autenticação via Google.');
    }

    final existente = await _firestoreService.obterUsuario(usuario.uid);
    if (existente == null) {
      await _firestoreService.salvarUsuario(usuario);
      return usuario;
    }

    return existente;
  }

  @override
  Future<void> logout() async {
    await _authService.logout();
  }
}
