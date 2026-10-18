import 'package:firebase_auth/firebase_auth.dart';

import '../../core/result/app_exception.dart';

/// Executa uma operação do Firebase convertendo os erros técnicos em
/// mensagens que podem ser exibidas para o usuário.
Future<T> comTratamentoFirebase<T>(Future<T> Function() operacao) async {
  try {
    return await operacao();
  } on FirebaseAuthException catch (e) {
    throw AppException(mensagemAuth(e.code));
  } on FirebaseException catch (e) {
    throw AppException(mensagemFirestore(e.code));
  }
}

String mensagemAuth(String code) {
  return switch (code) {
    'invalid-email' => 'O e-mail informado é inválido.',
    'user-disabled' => 'Esta conta foi desativada.',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' ||
    'INVALID_LOGIN_CREDENTIALS' => 'E-mail ou senha incorretos.',
    'email-already-in-use' => 'Já existe uma conta com este e-mail.',
    'weak-password' => 'A senha é muito fraca. Use pelo menos 6 caracteres.',
    'too-many-requests' =>
      'Muitas tentativas seguidas. Aguarde um pouco e tente novamente.',
    'network-request-failed' => 'Sem conexão com a internet.',
    'popup-closed-by-user' ||
    'cancelled-popup-request' ||
    'web-context-canceled' ||
    'canceled' => 'Login com Google cancelado.',
    'popup-blocked' => 'O navegador bloqueou a janela do Google. Libere os pop-ups e tente de novo.',
    'account-exists-with-different-credential' =>
      'Este e-mail já está cadastrado com outro método de login.',
    'operation-not-allowed' =>
      'Este método de login não está habilitado no Firebase.',
    'configuration-not-found' || 'internal-error' =>
      'O Firebase Authentication não está configurado para este projeto.',
    _ => 'Não foi possível autenticar ($code).',
  };
}

String mensagemFirestore(String code) {
  return switch (code) {
    'permission-denied' => 'Você não tem permissão para realizar esta ação.',
    'unavailable' ||
    'deadline-exceeded' => 'Servidor indisponível. Verifique sua conexão.',
    'not-found' => 'Registro não encontrado.',
    'unauthenticated' => 'Sua sessão expirou. Entre novamente.',
    _ => 'Erro ao acessar os dados ($code).',
  };
}
