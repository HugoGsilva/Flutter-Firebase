import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../../core/di/injection.dart';
import '../../../core/result/result.dart';
import '../../../domain/models/pessoa_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/pessoa_viewmodel.dart';

class PessoaDetailScreen extends StatefulWidget {
  const PessoaDetailScreen({
    super.key,
    required this.pessoaId,
    this.pessoa,
  });

  final String pessoaId;
  final PessoaModel? pessoa;

  @override
  State<PessoaDetailScreen> createState() => _PessoaDetailScreenState();
}

class _PessoaDetailScreenState extends State<PessoaDetailScreen> {
  late final PessoaViewModel _pessoaViewModel;
  late final AuthViewModel _authViewModel;
  PessoaModel? _pessoa;

  @override
  void initState() {
    super.initState();
    _pessoaViewModel = sl<PessoaViewModel>();
    _authViewModel = sl<AuthViewModel>();
    _atualizarPessoa();
  }

  void _atualizarPessoa() {
    _pessoa = widget.pessoa;
    if (_pessoa == null) {
      final lista = _pessoaViewModel.pessoas.value;
      _pessoa = lista.where((p) => p.id == widget.pessoaId).firstOrNull;
    }
  }

  Future<void> _confirmarExclusao(BuildContext context, PessoaModel pessoa) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text(
          'Deseja realmente excluir "${pessoa.nome}"? Esta ação removerá os dados cadastrais da pessoa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    if (!context.mounted) return;

    final result = await _pessoaViewModel.removerPessoaCommand(pessoa.id, true);
    if (!context.mounted) return;

    if (result case Success()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${pessoa.nome} foi removido(a) com sucesso.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      try {
        context.pop();
      } catch (_) {
        Navigator.of(context).maybePop();
      }
    } else if (result case Failure()) {
      final msg = _pessoaViewModel.errorMessage.value ?? 'Erro ao excluir pessoa.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _pessoaViewModel.limparErro();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SignalBuilder(
      builder: (context) {
        final listaAtual = _pessoaViewModel.pessoas.value;
        final pessoa = listaAtual.where((p) => p.id == widget.pessoaId).firstOrNull ?? _pessoa;

        if (pessoa == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detalhes')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Pessoa não encontrada.'),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Voltar'),
                  ),
                ],
              ),
            ),
          );
        }

        final currentUserId = _authViewModel.currentUser.value?.uid ?? '';
        final isAutoavaliacao = currentUserId == pessoa.criadoPor || currentUserId == pessoa.id;
        final dataFormatada = DateFormat('dd/MM/yyyy').format(pessoa.dataNascimento);

        return Scaffold(
          appBar: AppBar(
            title: Text(pessoa.apelido.isNotEmpty ? pessoa.apelido : pessoa.nome),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar',
                onPressed: () => context.push(
                  '/pessoas/editar/${pessoa.id}',
                  extra: pessoa,
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: colorScheme.error),
                tooltip: 'Excluir',
                onPressed: () => _confirmarExclusao(context, pessoa),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Text(
                          pessoa.nome.isNotEmpty ? pessoa.nome[0].toUpperCase() : '?',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        pessoa.nome,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (pessoa.apelido.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '"${pessoa.apelido}"',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.primary,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        _buildInfoTile(
                          context,
                          icon: Icons.school_outlined,
                          title: 'Curso',
                          value: pessoa.curso,
                        ),
                        const Divider(height: 1),
                        _buildInfoTile(
                          context,
                          icon: Icons.calendar_today_outlined,
                          title: 'Turma / Ano',
                          value: '${pessoa.turma}',
                        ),
                        const Divider(height: 1),
                        _buildInfoTile(
                          context,
                          icon: Icons.cake_outlined,
                          title: 'Data de Nascimento',
                          value: dataFormatada,
                        ),
                        const Divider(height: 1),
                        _buildInfoTile(
                          context,
                          icon: Icons.fingerprint_outlined,
                          title: 'Código do Cadastro',
                          value: pessoa.id,
                        ),
                      ],
                    ),
                  ),
                ),
                if (isAutoavaliacao) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: colorScheme.secondary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Este cadastro foi registrado por você. Pelas regras do app, não é permitida autoavaliação.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => context.push(
                    '/pessoas/avaliar/${pessoa.id}',
                    extra: pessoa,
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.star_rounded, size: 24),
                  label: const Text(
                    'Avaliar Pessoa',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.push(
                    '/pessoas/editar/${pessoa.id}',
                    extra: pessoa,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar Cadastro'),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => _confirmarExclusao(context, pessoa),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Excluir Cadastro'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
