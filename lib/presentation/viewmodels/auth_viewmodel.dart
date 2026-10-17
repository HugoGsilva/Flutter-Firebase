import 'package:flutter/foundation.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../core/command/command.dart';
import '../../core/result/result.dart';
import '../../domain/facades/auth_facade.dart';
import '../../domain/models/usuario_model.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._authFacade) {
    currentUser = signal<UsuarioModel?>(
      _authFacade.verificarAutenticado().dataOrNull,
    );
    isAuthenticated = computed(() => currentUser.value != null);
    isLoading = signal<bool>(false);
    errorMessage = signal<String?>(null);

    loginCommand = Command2<UsuarioModel, String, String>(_login);
    cadastroCommand = Command3<UsuarioModel, String, String, String>(_cadastro);
    loginGoogleCommand = Command0<UsuarioModel>(_loginGoogle);
    logoutCommand = Command0<void>(_logout);
  }

  final AuthFacade _authFacade;

  late final Signal<UsuarioModel?> currentUser;
  late final Computed<bool> isAuthenticated;
  late final Signal<bool> isLoading;
  late final Signal<String?> errorMessage;

  late final Command2<UsuarioModel, String, String> loginCommand;
  late final Command3<UsuarioModel, String, String, String> cadastroCommand;
  late final Command0<UsuarioModel> loginGoogleCommand;
  late final Command0<void> logoutCommand;

  Future<Result<UsuarioModel>> _login(String email, String senha) async {
    isLoading.value = true;
    errorMessage.value = null;
    notifyListeners();
    try {
      final res = await _authFacade.loginComEmail(email: email, senha: senha);
      if (res case Success(data: final user)) {
        currentUser.value = user;
        errorMessage.value = null;
      } else if (res case Failure(error: final err)) {
        errorMessage.value = _formatError(err);
      }
      return res;
    } finally {
      isLoading.value = false;
      notifyListeners();
    }
  }

  Future<Result<UsuarioModel>> _cadastro(
    String email,
    String senha,
    String nome,
  ) async {
    isLoading.value = true;
    errorMessage.value = null;
    notifyListeners();
    try {
      final res = await _authFacade.cadastrarComEmail(
        nome: nome,
        email: email,
        senha: senha,
      );
      if (res case Success(data: final user)) {
        currentUser.value = user;
        errorMessage.value = null;
      } else if (res case Failure(error: final err)) {
        errorMessage.value = _formatError(err);
      }
      return res;
    } finally {
      isLoading.value = false;
      notifyListeners();
    }
  }

  Future<Result<UsuarioModel>> _loginGoogle() async {
    isLoading.value = true;
    errorMessage.value = null;
    notifyListeners();
    try {
      final res = await _authFacade.loginComGoogle();
      if (res case Success(data: final user)) {
        currentUser.value = user;
        errorMessage.value = null;
      } else if (res case Failure(error: final err)) {
        errorMessage.value = _formatError(err);
      }
      return res;
    } finally {
      isLoading.value = false;
      notifyListeners();
    }
  }

  Future<Result<void>> _logout() async {
    isLoading.value = true;
    errorMessage.value = null;
    notifyListeners();
    try {
      final res = await _authFacade.logout();
      if (res case Success()) {
        currentUser.value = null;
        errorMessage.value = null;
      } else if (res case Failure(error: final err)) {
        errorMessage.value = _formatError(err);
      }
      return res;
    } finally {
      isLoading.value = false;
      notifyListeners();
    }
  }

  void verificarSessao() {
    final res = _authFacade.verificarAutenticado();
    currentUser.value = res.dataOrNull;
    notifyListeners();
  }

  void limparErro() {
    errorMessage.value = null;
  }

  String _formatError(Exception e) {
    final msg = e.toString();
    if (msg.startsWith('Exception: ')) {
      return msg.substring(11);
    }
    return msg;
  }
}
