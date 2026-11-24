import 'package:firebase_auth/firebase_auth.dart';

import '../../core/result/app_exception.dart';
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

  Future<UsuarioModel> atualizarPerfil({
    String? nome,
    String? foto,
    bool atualizarFoto = false,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AppException('Você precisa estar autenticado.');
    }
    if (nome != null) {
      await user.updateDisplayName(nome);
    }
    if (atualizarFoto && (foto == null || !foto.startsWith('data:'))) {
      await user.updatePhotoURL(foto);
    }
    await user.reload();
    final atualizado = _firebaseAuth.currentUser ?? user;
    return mapearUsuario(
      atualizado,
      nome: nome ?? atualizado.displayName,
      foto: atualizarFoto ? foto : atualizado.photoURL,
      sobrescreverFoto: atualizarFoto,
    );
  }

  Future<void> alterarSenha({
    required String senhaAtual,
    required String novaSenha,
  }) async {
    final user = _firebaseAuth.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      throw const AppException('Você precisa estar autenticado.');
    }
    final credential = EmailAuthProvider.credential(
      email: email,
      password: senhaAtual,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(novaSenha);
  }

  Future<void> enviarEmailRecuperacaoSenha(String email) {
    return _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  static UsuarioModel mapearUsuario(
    User user, {
    String? nome,
    String? foto,
    bool sobrescreverFoto = false,
  }) {
    final provider = user.providerData.isNotEmpty
        ? user.providerData.first.providerId
        : 'password';

    return UsuarioModel(
      uid: user.uid,
      nome: nome ?? user.displayName ?? '',
      email: user.email ?? '',
      foto: sobrescreverFoto ? foto : (foto ?? user.photoURL),
      provider: provider,
    );
  }
}
