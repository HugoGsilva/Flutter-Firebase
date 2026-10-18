import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../domain/models/usuario_model.dart';
import 'auth_service.dart';

/// Login com conta Google integrado ao Firebase Authentication.
///
/// Na web abre o popup do Google; no Android/iOS o próprio Firebase conduz o
/// fluxo OAuth pelo navegador do sistema.
class GoogleAuthService {
  GoogleAuthService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  Future<UsuarioModel?> login() async {
    final provider = GoogleAuthProvider()
      ..addScope('email')
      ..addScope('profile')
      ..setCustomParameters({'prompt': 'select_account'});

    final credential = kIsWeb
        ? await _firebaseAuth.signInWithPopup(provider)
        : await _firebaseAuth.signInWithProvider(provider);

    final user = credential.user;
    return user != null ? AuthService.mapearUsuario(user) : null;
  }
}
