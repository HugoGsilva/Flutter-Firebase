import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/di/injection.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_router.dart';
import '../../../data/services/image_picker_service.dart';
import '../../../domain/models/pessoa_model.dart';
import '../../../domain/models/usuario_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/avaliacao_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/pessoa_viewmodel.dart';
import '../../viewmodels/ranking_viewmodel.dart';
import '../widgets/avatar_usuario.dart';
import '../widgets/feedback.dart';

class PerfilView extends StatefulWidget {
  const PerfilView({super.key});

  @override
  State<PerfilView> createState() => _PerfilViewState();
}

class _PerfilViewState extends State<PerfilView> {
  final _perfilFormKey = GlobalKey<FormState>();
  final _senhaFormKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _senhaAtualController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  late final AuthViewModel _authViewModel;
  late final PessoaViewModel _pessoaViewModel;
  late final ImagePickerService _imagePickerService;

  String? _ultimoUidSincronizado;
  String? _ultimoNomeSincronizado;
  bool _obscureAtual = true;
  bool _obscureNova = true;
  bool _obscureConfirmacao = true;

  @override
  void initState() {
    super.initState();
    _authViewModel = sl<AuthViewModel>();
    _pessoaViewModel = sl<PessoaViewModel>();
    _imagePickerService = sl<ImagePickerService>();
    _sincronizarNome(_authViewModel.currentUser.value);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  void _sincronizarNome(UsuarioModel? usuario) {
    if (usuario == null) {
      _ultimoUidSincronizado = null;
      _ultimoNomeSincronizado = null;
      return;
    }
    if (usuario.uid != _ultimoUidSincronizado ||
        usuario.nome != _ultimoNomeSincronizado) {
      _ultimoUidSincronizado = usuario.uid;
      _ultimoNomeSincronizado = usuario.nome;
      _nomeController.text = usuario.nome;
    }
  }

  bool get _suportaEscolhaCamera {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> _alterarFoto() async {
    if (!_suportaEscolhaCamera) {
      await _selecionarEEnviarFoto(usarCamera: false);
      return;
    }

    final escolha = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                key: const Key('foto_opcao_galeria'),
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Escolher da galeria'),
                onTap: () => Navigator.of(ctx).pop('galeria'),
              ),
              ListTile(
                key: const Key('foto_opcao_camera'),
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tirar foto com a câmera'),
                onTap: () => Navigator.of(ctx).pop('camera'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || escolha == null) return;
    await _selecionarEEnviarFoto(usarCamera: escolha == 'camera');
  }

  Future<void> _selecionarEEnviarFoto({required bool usarCamera}) async {
    FotoSelecionada? foto;
    try {
      foto = usarCamera
          ? await _imagePickerService.capturarDaCamera()
          : await _imagePickerService.selecionarDaGaleria();
    } on PlatformException {
      if (mounted) {
        mostrarErro(
          context,
          'Não foi possível acessar a ${usarCamera ? 'câmera' : 'galeria'}.',
        );
      }
      return;
    } catch (_) {
      if (mounted) {
        mostrarErro(context, 'Não foi possível selecionar a imagem.');
      }
      return;
    }

    if (!mounted || foto == null) return;

    final result = await _authViewModel.atualizarFotoCommand(
      foto.bytes,
      foto.nomeArquivo,
      foto.mimeType,
    );
    if (!mounted) return;

    if (result case Success()) {
      mostrarSucesso(context, 'Foto de perfil atualizada!');
    } else {
      mostrarErro(
        context,
        _authViewModel.errorMessage.value ??
            'Não foi possível atualizar a foto de perfil.',
      );
      _authViewModel.limparErro();
    }
  }

  Future<void> _removerFoto() async {
    final confirmou = await confirmar(
      context,
      titulo: 'Remover foto',
      mensagem: 'Deseja remover sua foto de perfil atual?',
      acao: 'Remover',
    );
    if (!confirmou || !mounted) return;

    final result = await _authViewModel.removerFotoCommand();
    if (!mounted) return;

    if (result case Success()) {
      mostrarSucesso(context, 'Foto de perfil removida.');
    } else {
      mostrarErro(
        context,
        _authViewModel.errorMessage.value ?? 'Não foi possível remover a foto.',
      );
      _authViewModel.limparErro();
    }
  }

  Future<void> _salvarNome() async {
    if (!_perfilFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final result = await _authViewModel.atualizarPerfilCommand(
      _nomeController.text.trim(),
    );
    if (!mounted) return;

    if (result case Success()) {
      mostrarSucesso(context, 'Perfil atualizado!');
    } else {
      mostrarErro(
        context,
        _authViewModel.errorMessage.value ??
            'Não foi possível atualizar o perfil.',
      );
      _authViewModel.limparErro();
    }
  }

  Future<void> _desvincularPessoa() async {
    final confirmou = await confirmar(
      context,
      titulo: 'Remover vínculo',
      mensagem: 'Deseja desvincular esta pessoa da sua conta?',
      acao: 'Desvincular',
    );
    if (!confirmou || !mounted) return;

    final result = await _authViewModel.vincularPessoaCommand(null);
    if (!mounted) return;

    if (result case Success()) {
      mostrarSucesso(context, 'Vínculo removido da sua conta.');
    } else {
      mostrarErro(
        context,
        _authViewModel.errorMessage.value ??
            'Não foi possível remover o vínculo.',
      );
      _authViewModel.limparErro();
    }
  }

  Future<void> _alterarSenha() async {
    if (!_senhaFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final result = await _authViewModel.alterarSenhaCommand(
      _senhaAtualController.text,
      _novaSenhaController.text,
      _confirmarSenhaController.text,
    );
    if (!mounted) return;

    if (result case Success()) {
      _senhaAtualController.clear();
      _novaSenhaController.clear();
      _confirmarSenhaController.clear();
      _senhaFormKey.currentState?.reset();
      mostrarSucesso(context, 'Senha alterada com sucesso!');
    } else {
      mostrarErro(
        context,
        _authViewModel.errorMessage.value ??
            'Não foi possível alterar a senha.',
      );
      _authViewModel.limparErro();
    }
  }

  Future<void> _confirmarLogout() async {
    final sair = await confirmar(
      context,
      titulo: 'Sair do aplicativo',
      mensagem: 'Deseja realmente encerrar sua sessão?',
      acao: 'Sair',
    );
    if (!sair || !mounted) return;

    await _authViewModel.logoutCommand();
    sl<PessoaViewModel>().limpar();
    sl<AvaliacaoViewModel>().limpar();
    sl<RankingViewModel>().limpar();
    sl<HomeViewModel>().setTab(HomeViewModel.abaPessoas);
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SignalBuilder(
      builder: (context) {
        final usuario = _authViewModel.currentUser.value;
        _sincronizarNome(usuario);

        if (usuario == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final loading = _authViewModel.isLoading.value;
        final temFoto = (usuario.foto ?? '').trim().isNotEmpty;
        final PessoaModel? pessoaVinculada = usuario.pessoaId != null
            ? _pessoaViewModel.pessoaPorId(usuario.pessoaId!)
            : null;

        return SingleChildScrollView(
          key: const PageStorageKey('perfil'),
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CabecalhoPerfil(
                    usuario: usuario,
                    temFoto: temFoto,
                    loading: loading,
                    onAlterarFoto: _alterarFoto,
                    onRemoverFoto: _removerFoto,
                  ),
                  const SizedBox(height: 16),
                  _SecaoCard(
                    titulo: 'Dados do perfil',
                    icone: Icons.badge_outlined,
                    child: Form(
                      key: _perfilFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            key: const Key('perfil_nome'),
                            controller: _nomeController,
                            textCapitalization: TextCapitalization.words,
                            enabled: !loading,
                            decoration: const InputDecoration(
                              labelText: 'Nome completo',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) {
                              if ((value?.trim().length ?? 0) < 3) {
                                return 'Informe pelo menos 3 caracteres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            initialValue: usuario.email,
                            enabled: false,
                            decoration: const InputDecoration(
                              labelText: 'E-mail',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            key: const Key('perfil_salvar_nome'),
                            onPressed: loading ? null : _salvarNome,
                            icon: loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: const Text('Salvar alterações'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SecaoCard(
                    titulo: 'Vínculo no PiramidGame',
                    icone: Icons.link_rounded,
                    child: usuario.pessoaId == null
                        ? Text(
                            'Sua conta ainda não está vinculada a uma pessoa cadastrada. '
                            'Abra os detalhes de um cadastro na aba Pessoas e toque em "Esta pessoa sou eu".',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pessoaVinculada?.nome ?? 'Cadastro vinculado',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (pessoaVinculada != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '${pessoaVinculada.apelido} • ${pessoaVinculada.curso} ${pessoaVinculada.turma}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: loading
                                        ? null
                                        : () => context.push(
                                            AppRoutes.detalhes(
                                              usuario.pessoaId!,
                                            ),
                                            extra: pessoaVinculada,
                                          ),
                                    icon: const Icon(Icons.open_in_new),
                                    label: const Text('Ver cadastro'),
                                  ),
                                  TextButton.icon(
                                    key: const Key('perfil_desvincular'),
                                    onPressed: loading
                                        ? null
                                        : _desvincularPessoa,
                                    icon: const Icon(Icons.link_off),
                                    label: const Text('Desvincular'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 12),
                  _SecaoCard(
                    titulo: 'Segurança e senha',
                    icone: Icons.lock_outline,
                    child: usuario.podeAlterarSenha
                        ? Form(
                            key: _senhaFormKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  key: const Key('perfil_senha_atual'),
                                  controller: _senhaAtualController,
                                  obscureText: _obscureAtual,
                                  enabled: !loading,
                                  decoration: InputDecoration(
                                    labelText: 'Senha atual',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureAtual
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscureAtual = !_obscureAtual,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Informe a senha atual';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  key: const Key('perfil_nova_senha'),
                                  controller: _novaSenhaController,
                                  obscureText: _obscureNova,
                                  enabled: !loading,
                                  decoration: InputDecoration(
                                    labelText: 'Nova senha',
                                    hintText: 'Mínimo 6 caracteres',
                                    prefixIcon: const Icon(
                                      Icons.lock_reset_outlined,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureNova
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscureNova = !_obscureNova,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.length < 6) {
                                      return 'Use pelo menos 6 caracteres';
                                    }
                                    if (value == _senhaAtualController.text) {
                                      return 'A nova senha deve ser diferente da atual';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  key: const Key('perfil_confirmar_senha'),
                                  controller: _confirmarSenhaController,
                                  obscureText: _obscureConfirmacao,
                                  enabled: !loading,
                                  decoration: InputDecoration(
                                    labelText: 'Confirmar nova senha',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmacao
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscureConfirmacao =
                                            !_obscureConfirmacao,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value != _novaSenhaController.text) {
                                      return 'As senhas não conferem';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                FilledButton.tonalIcon(
                                  key: const Key('perfil_alterar_senha'),
                                  onPressed: loading ? null : _alterarSenha,
                                  icon: const Icon(Icons.password_outlined),
                                  label: const Text('Alterar senha'),
                                ),
                              ],
                            ),
                          )
                        : Text(
                            'Esta conta foi autenticada com o Google. '
                            'A alteração de senha deve ser feita diretamente na sua Conta Google.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),
                  _SecaoCard(
                    titulo: 'Sessão',
                    icone: Icons.logout_rounded,
                    child: OutlinedButton.icon(
                      key: const Key('perfil_sair'),
                      onPressed: loading ? null : _confirmarLogout,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        side: BorderSide(color: colorScheme.error),
                      ),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Sair da conta'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CabecalhoPerfil extends StatelessWidget {
  const _CabecalhoPerfil({
    required this.usuario,
    required this.temFoto,
    required this.loading,
    required this.onAlterarFoto,
    required this.onRemoverFoto,
  });

  final UsuarioModel usuario;
  final bool temFoto;
  final bool loading;
  final VoidCallback onAlterarFoto;
  final VoidCallback onRemoverFoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textoProvider = usuario.podeAlterarSenha
        ? 'E-mail e senha'
        : 'Conta Google';

    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            AvatarUsuario(
              nome: usuario.nome,
              fotoUrl: usuario.foto,
              radius: 48,
            ),
            const SizedBox(height: 12),
            Text(
              usuario.nome.isNotEmpty ? usuario.nome : 'Usuário sem nome',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              usuario.email,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Chip(
              avatar: Icon(
                usuario.podeAlterarSenha
                    ? Icons.alternate_email
                    : Icons.g_mobiledata,
                size: 18,
              ),
              label: Text(textoProvider),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  key: const Key('perfil_alterar_foto'),
                  onPressed: loading ? null : onAlterarFoto,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Alterar foto'),
                ),
                if (temFoto)
                  OutlinedButton.icon(
                    key: const Key('perfil_remover_foto'),
                    onPressed: loading ? null : onRemoverFoto,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remover foto'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SecaoCard extends StatelessWidget {
  const _SecaoCard({
    required this.titulo,
    required this.icone,
    required this.child,
  });

  final String titulo;
  final IconData icone;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icone, color: colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titulo,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
