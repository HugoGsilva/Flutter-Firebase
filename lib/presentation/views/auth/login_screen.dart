import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/di/injection.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_router.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../widgets/feedback.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _obscurePassword = true;

  late final AuthViewModel _authViewModel;

  @override
  void initState() {
    super.initState();
    _authViewModel = sl<AuthViewModel>();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final result = await _authViewModel.loginCommand(
      _emailController.text.trim(),
      _senhaController.text,
    );
    _tratarResultado(result, 'Erro ao realizar login.');
  }

  Future<void> _handleGoogleLogin() async {
    FocusScope.of(context).unfocus();
    final result = await _authViewModel.loginGoogleCommand();
    _tratarResultado(result, 'Erro ao entrar com Google.');
  }

  Future<void> _handleEsqueciSenha() async {
    final email = await showDialog<String>(
      context: context,
      builder: (_) =>
          _DialogRecuperarSenha(emailInicial: _emailController.text.trim()),
    );
    if (!mounted || email == null) return;

    final result = await _authViewModel.recuperarSenhaCommand(email);
    if (!mounted) return;

    if (result case Success()) {
      mostrarSucesso(
        context,
        'Enviamos um link de redefinição de senha para $email.',
      );
    } else {
      mostrarErro(
        context,
        _authViewModel.errorMessage.value ??
            'Não foi possível enviar o e-mail de recuperação.',
      );
      _authViewModel.limparErro();
    }
  }

  void _tratarResultado(Result<Object?> result, String mensagemPadrao) {
    if (!mounted) return;
    if (result case Success()) {
      context.go(AppRoutes.home);
    } else {
      mostrarErro(context, _authViewModel.errorMessage.value ?? mensagemPadrao);
      _authViewModel.limparErro();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: SignalBuilder(
                  builder: (context) {
                    final loading = _authViewModel.isLoading.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.military_tech_rounded,
                          size: 64,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'PiramidGame IFPR-Pgua',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Entre para avaliar e ranquear a galera do campus',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          key: const Key('login_email'),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          enabled: !loading,
                          decoration: const InputDecoration(
                            labelText: 'E-mail',
                            hintText: 'seu.email@exemplo.com',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty) return 'Informe seu e-mail';
                            if (!email.contains('@') || !email.contains('.')) {
                              return 'Informe um e-mail válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const Key('login_senha'),
                          controller: _senhaController,
                          obscureText: _obscurePassword,
                          enabled: !loading,
                          onFieldSubmitted: (_) => _handleLogin(),
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Informe sua senha';
                            }
                            return null;
                          },
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            key: const Key('login_esqueci_senha'),
                            onPressed: loading ? null : _handleEsqueciSenha,
                            child: const Text('Esqueci minha senha'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: loading ? null : _handleLogin,
                          child: loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Entrar'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: loading ? null : _handleGoogleLogin,
                          icon: const Icon(Icons.g_mobiledata, size: 28),
                          label: const Text('Entrar com Google'),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Ainda não tem conta?',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            TextButton(
                              onPressed: loading
                                  ? null
                                  : () => context.push(AppRoutes.cadastro),
                              child: const Text(
                                'Criar conta',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogRecuperarSenha extends StatefulWidget {
  const _DialogRecuperarSenha({required this.emailInicial});

  final String emailInicial;

  @override
  State<_DialogRecuperarSenha> createState() => _DialogRecuperarSenhaState();
}

class _DialogRecuperarSenhaState extends State<_DialogRecuperarSenha> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.emailInicial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Recuperar senha'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          key: const Key('recuperar_email'),
          controller: _controller,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'E-mail da conta',
            hintText: 'seu.email@exemplo.com',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (value) {
            final email = value?.trim() ?? '';
            if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
              return 'Informe um e-mail válido';
            }
            return null;
          },
          onFieldSubmitted: (_) => _confirmar(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('recuperar_enviar'),
          onPressed: _confirmar,
          child: const Text('Enviar'),
        ),
      ],
    );
  }
}
