import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/models/usuario_model.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  UsuarioModel? get currentUser {
    final user = _firebaseAuth.currentUser;
    return user != null ? _mapFirebaseUser(user) : null;
  }

  Stream<UsuarioModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map(
      (user) => user != null ? _mapFirebaseUser(user) : null,
    );
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
    if (user != null) {
      if (nome.isNotEmpty) {
        await user.updateDisplayName(nome);
      }
      return _mapFirebaseUser(
        user,
        overrideNome: nome.isNotEmpty ? nome : null,
      );
    }
    return null;
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
    return user != null ? _mapFirebaseUser(user) : null;
  }

  Future<UsuarioModel?> loginGoogle() async {
    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;
    final clientAuth = await googleUser.authorizationClient
        .authorizationForScopes(['email', 'profile']);
    final credential = GoogleAuthProvider.credential(
      accessToken: clientAuth?.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final user = userCredential.user;
    return user != null ? _mapFirebaseUser(user) : null;
  }

  Future<void> logout() async {
    await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
  }

  UsuarioModel _mapFirebaseUser(User user, {String? overrideNome}) {
    final provider = user.providerData.isNotEmpty
        ? user.providerData.first.providerId
        : 'password';

    return UsuarioModel(
      uid: user.uid,
      nome: overrideNome ?? user.displayName ?? '',
      email: user.email ?? '',
      foto: user.photoURL,
      provider: provider,
    );
  }
}
