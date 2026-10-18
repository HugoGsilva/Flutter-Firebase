import 'package:signals_flutter/signals_flutter.dart';

import '../../core/command/command.dart';
import '../../core/result/result.dart';
import '../../domain/facades/auth_facade.dart';
import '../../domain/models/usuario_model.dart';
import 'base_viewmodel.dart';

class AuthViewModel extends BaseViewModel {
  AuthViewModel(this._authFacade) {
    verificarSessaoCommand = Command0<UsuarioModel?>(_verificarSessao);
    loginCommand = Command2<UsuarioModel, String, String>(_login);
    cadastroCommand = Command3<UsuarioModel, String, String, String>(_cadastro);
    loginGoogleCommand = Command0<UsuarioModel>(_loginGoogle);
    logoutCommand = Command0<void>(_logout);
    vincularPessoaCommand = Command1<UsuarioModel, String?>(_vincularPessoa);
  }

  final AuthFacade _authFacade;

  final currentUser = signal<UsuarioModel?>(null);
  late final isAuthenticated = computed(() => currentUser.value != null);

  /// Nome guardado localmente para saudar o usuário enquanto a sessão é
  /// verificada no Firebase.
  final nomeEmCache = signal<String?>(null);

  late final Command0<UsuarioModel?> verificarSessaoCommand;
  late final Command2<UsuarioModel, String, String> loginCommand;
  late final Command3<UsuarioModel, String, String, String> cadastroCommand;
  late final Command0<UsuarioModel> loginGoogleCommand;
  late final Command0<void> logoutCommand;
  late final Command1<UsuarioModel, String?> vincularPessoaCommand;

  void _definirUsuario(UsuarioModel? usuario) => currentUser.value = usuario;

  Future<void> carregarCache() async {
    final cache = await _authFacade.usuarioEmCache();
    nomeEmCache.value = cache?.nome;
  }

  Future<Result<UsuarioModel?>> _verificarSessao() {
    return executar(
      _authFacade.verificarAutenticacao,
      aoConcluir: _definirUsuario,
    );
  }

  Future<Result<UsuarioModel>> _login(String email, String senha) {
    return executar(
      () => _authFacade.login(email: email, senha: senha),
      aoConcluir: _definirUsuario,
    );
  }

  Future<Result<UsuarioModel>> _cadastro(
    String nome,
    String email,
    String senha,
  ) {
    return executar(
      () => _authFacade.criarConta(nome: nome, email: email, senha: senha),
      aoConcluir: _definirUsuario,
    );
  }

  Future<Result<UsuarioModel>> _loginGoogle() {
    return executar(_authFacade.loginComGoogle, aoConcluir: _definirUsuario);
  }

  Future<Result<void>> _logout() {
    return executar(
      _authFacade.logout,
      aoConcluir: (_) {
        nomeEmCache.value = null;
        _definirUsuario(null);
      },
    );
  }

  Future<Result<UsuarioModel>> _vincularPessoa(String? pessoaId) {
    return executar(
      () => _authFacade.vincularPessoa(pessoaId),
      aoConcluir: _definirUsuario,
    );
  }
}
