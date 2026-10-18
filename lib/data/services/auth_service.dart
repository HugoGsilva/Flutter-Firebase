import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/models/usuario_model.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  UsuarioModel? get currentUser {
    final user = _firebaseAuth.currentUser;
    return user != null ? mapearUsuario(user) : null;
  }

  /// Primeiro estado emitido pelo Firebase depois de restaurar a sessão salva.
  Future<UsuarioModel?> aguardarEstadoInicial() async {
    final user = await _firebaseAuth.authStateChanges().first;
    return user != null ? mapearUsuario(user) : null;
  }

  Future<UsuarioModel?> cadastrarEmailSenha({
    required String email,
    required String password,
    required String nome,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) return null;

    await user.updateDisplayName(nome);
    return mapearUsuario(user, nome: nome);
  }

  Future<UsuarioModel?> loginEmailSenha({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    return user != null ? mapearUsuario(user) : null;
  }

  Future<void> logout() => _firebaseAuth.signOut();

  static UsuarioModel mapearUsuario(User user, {String? nome}) {
    final provider = user.providerData.isNotEmpty
        ? user.providerData.first.providerId
        : 'password';

    return UsuarioModel(
      uid: user.uid,
      nome: nome ?? user.displayName ?? '',
      email: user.email ?? '',
      foto: user.photoURL,
      provider: provider,
    );
  }
}
