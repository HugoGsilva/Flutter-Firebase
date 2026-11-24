import 'dart:typed_data';

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

  /// Usuário autenticado no Firebase neste momento (sem consultar o Firestore).
  UsuarioModel? get usuarioAtual;

  /// Aguarda o Firebase Authentication restaurar a sessão e retorna o perfil
  /// completo do usuário, ou null se não houver autenticação válida.
  Future<UsuarioModel?> restaurarSessao();

  Future<UsuarioModel?> buscarUsuario(String uid);

  Future<UsuarioModel?> buscarUsuarioVinculado(String pessoaId);

  Future<void> vincularPessoa(String uid, String? pessoaId);

  Future<UsuarioModel> atualizarNome({required String nome});

  Future<UsuarioModel> atualizarFotoPerfil({
    required Uint8List bytes,
    required String nomeArquivo,
    required String mimeType,
  });

  Future<UsuarioModel> removerFotoPerfil();

  Future<void> alterarSenha({
    required String senhaAtual,
    required String novaSenha,
  });

  Future<void> enviarRecuperacaoSenha({required String email});
}
