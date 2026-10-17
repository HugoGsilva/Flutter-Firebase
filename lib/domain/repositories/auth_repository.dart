import '../models/usuario_model.dart';

abstract interface class AuthRepository {
  Future<UsuarioModel> cadastrarComEmail({
    required String nome,
    required String email,
    required String senha,
  });

  Future<UsuarioModel> loginComEmail({
    required String email,
    required String senha,
  });

  Future<UsuarioModel> loginComGoogle();

  Future<void> logout();

  UsuarioModel? get usuarioAtual;

  Stream<UsuarioModel?> get authStateChanges;
}
