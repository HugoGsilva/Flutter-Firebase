import 'dart:convert';
import 'dart:typed_data';

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

  @override
  Future<UsuarioModel> atualizarNome({required String nome}) {
    return comTratamentoFirebase(() async {
      final atualizado = await _authService.atualizarPerfil(nome: nome);
      await _firestoreService.atualizarPerfilUsuario(
        atualizado.uid,
        nome: nome,
      );
      final salvo = await _firestoreService.obterUsuario(atualizado.uid);
      return atualizado
          .comFoto(salvo?.foto ?? atualizado.foto)
          .comPessoaVinculada(salvo?.pessoaId);
    });
  }

  @override
  Future<UsuarioModel> atualizarFotoPerfil({
    required Uint8List bytes,
    required String nomeArquivo,
    required String mimeType,
  }) {
    return comTratamentoFirebase(() async {
      final atual = _authService.currentUser;
      if (atual == null) {
        throw const AppException('Você precisa estar autenticado.');
      }
      final dataUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';
      await _firestoreService.atualizarPerfilUsuario(
        atual.uid,
        foto: dataUrl,
        atualizarFoto: true,
      );
      final salvo = await _firestoreService.obterUsuario(atual.uid);
      final base = atual.nome.isNotEmpty ? atual : (salvo ?? atual);
      return base.comFoto(dataUrl).comPessoaVinculada(salvo?.pessoaId);
    });
  }

  @override
  Future<UsuarioModel> removerFotoPerfil() {
    return comTratamentoFirebase(() async {
      final atualizado = await _authService.atualizarPerfil(
        foto: null,
        atualizarFoto: true,
      );
      await _firestoreService.atualizarPerfilUsuario(
        atualizado.uid,
        foto: null,
        atualizarFoto: true,
      );
      final salvo = await _firestoreService.obterUsuario(atualizado.uid);
      return atualizado.comFoto(null).comPessoaVinculada(salvo?.pessoaId);
    });
  }

  @override
  Future<void> alterarSenha({
    required String senhaAtual,
    required String novaSenha,
  }) {
    return comTratamentoFirebase(
      () => _authService.alterarSenha(
        senhaAtual: senhaAtual,
        novaSenha: novaSenha,
      ),
    );
  }

  @override
  Future<void> enviarRecuperacaoSenha({required String email}) {
    return comTratamentoFirebase(
      () => _authService.enviarEmailRecuperacaoSenha(email),
    );
  }

  /// Mantém o documento em `usuarios` atualizado com os dados do Firebase
  /// Authentication e devolve o perfil com foto e vínculo salvos.
  Future<UsuarioModel> _sincronizarPerfil(UsuarioModel usuario) async {
    final salvo = await _firestoreService.obterUsuario(usuario.uid);
    final atualizado = usuario
        .copyWith(nome: usuario.nome.isNotEmpty ? usuario.nome : salvo?.nome)
        .comFoto(salvo != null ? salvo.foto : usuario.foto);
    await _firestoreService.salvarUsuario(atualizado);
    return atualizado.comPessoaVinculada(salvo?.pessoaId);
  }
}
