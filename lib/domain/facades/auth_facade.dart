import '../../core/result/result.dart';
import '../models/usuario_model.dart';
import '../usecases/auth/cadastrar_usuario_usecase.dart';
import '../usecases/auth/login_email_usecase.dart';
import '../usecases/auth/login_google_usecase.dart';
import '../usecases/auth/logout_usecase.dart';
import '../usecases/auth/verificar_autenticado_usecase.dart';

class AuthFacade {
  const AuthFacade({
    required this.cadastrarUsuarioUseCase,
    required this.loginEmailUseCase,
    required this.loginGoogleUseCase,
    required this.logoutUseCase,
    required this.verificarAutenticadoUseCase,
  });

  final CadastrarUsuarioUseCase cadastrarUsuarioUseCase;
  final LoginEmailUseCase loginEmailUseCase;
  final LoginGoogleUseCase loginGoogleUseCase;
  final LogoutUseCase logoutUseCase;
  final VerificarAutenticadoUseCase verificarAutenticadoUseCase;

  Future<Result<UsuarioModel>> cadastrarComEmail({
    required String nome,
    required String email,
    required String senha,
  }) {
    return cadastrarUsuarioUseCase(nome: nome, email: email, senha: senha);
  }

  Future<Result<UsuarioModel>> loginComEmail({
    required String email,
    required String senha,
  }) {
    return loginEmailUseCase(email: email, senha: senha);
  }

  Future<Result<UsuarioModel>> loginComGoogle() {
    return loginGoogleUseCase();
  }

  Future<Result<void>> logout() {
    return logoutUseCase();
  }

  Result<UsuarioModel?> verificarAutenticado() {
    return verificarAutenticadoUseCase();
  }
}
