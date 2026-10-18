import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/di/injection.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_router.dart';
import '../../../domain/models/pessoa_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/avaliacao_viewmodel.dart';
import '../../viewmodels/pessoa_viewmodel.dart';
import '../../viewmodels/ranking_viewmodel.dart';
import '../widgets/feedback.dart';
import '../widgets/formatacao.dart';

class PessoaDetailScreen extends StatefulWidget {
  const PessoaDetailScreen({super.key, required this.pessoaId, this.pessoa});

  final String pessoaId;
  final PessoaModel? pessoa;

  @override
  State<PessoaDetailScreen> createState() => _PessoaDetailScreenState();
}

class _PessoaDetailScreenState extends State<PessoaDetailScreen> {
  final _pessoaViewModel = sl<PessoaViewModel>();
  final _authViewModel = sl<AuthViewModel>();
  final _avaliacaoViewModel = sl<AvaliacaoViewModel>();
  final _rankingViewModel = sl<RankingViewModel>();

  bool _buscando = false;

  @override
  void initState() {
    super.initState();
    final conhecida =
        _pessoaViewModel.pessoaPorId(widget.pessoaId) ?? widget.pessoa;
    _buscando = conhecida == null;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _rankingViewModel.carregarRankingGlobalCommand();
      if (_avaliacaoViewModel.minhasAvaliacoes.value.isEmpty) {
        _avaliacaoViewModel.carregarMinhasAvaliacoesCommand();
      }
      if (_buscando) {
        await _pessoaViewModel.buscarPessoaCommand(widget.pessoaId);
        if (mounted) setState(() => _buscando = false);
      }
    });
  }

  Future<void> _confirmarExclusao(PessoaModel pessoa) async {
    final ok = await confirmar(
      context,
      titulo: 'Confirmar exclusão',
      mensagem:
          'Deseja realmente excluir "${pessoa.nome}"? As avaliações recebidas por esta pessoa também serão removidas.',
      acao: 'Excluir',
    );
    if (!ok || !mounted) return;

    final result = await _pessoaViewModel.removerPessoaCommand(pessoa.id, true);
    if (!mounted) return;

    if (result case Success()) {
      if (_authViewModel.currentUser.value?.pessoaId == pessoa.id) {
        await _authViewModel.vincularPessoaCommand(null);
      }
      _rankingViewModel.carregarRankingGlobalCommand();
      _avaliacaoViewModel.carregarMinhasAvaliacoesCommand();
      if (!mounted) return;
      mostrarSucesso(context, '${pessoa.nome} foi removido(a).');
      context.pop();
    } else {
      mostrarErro(
        context,
        _pessoaViewModel.errorMessage.value ?? 'Erro ao excluir pessoa.',
      );
      _pessoaViewModel.limparErro();
    }
  }

  Future<void> _alternarVinculo(PessoaModel pessoa, bool souEu) async {
    final result = await _authViewModel.vincularPessoaCommand(
      souEu ? null : pessoa.id,
    );
    if (!mounted) return;
    if (result case Success()) {
      mostrarSucesso(
        context,
        souEu
            ? 'Vínculo removido.'
            : 'Pronto! ${pessoa.nome} agora está vinculado(a) à sua conta.',
      );
    } else {
      mostrarErro(
        context,
        _authViewModel.errorMessage.value ?? 'Não foi possível vincular.',
      );
      _authViewModel.limparErro();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SignalBuilder(
      builder: (context) {
        final pessoa =
            _pessoaViewModel.pessoaPorId(widget.pessoaId) ?? widget.pessoa;

        if (pessoa == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detalhes')),
            body: Center(
              child: _buscando
                  ? const CircularProgressIndicator()
                  : const EstadoVazio(
                      icone: Icons.person_off_outlined,
                      titulo: 'Pessoa não encontrada',
                      mensagem: 'O cadastro pode ter sido removido.',
                    ),
            ),
          );
        }

        final usuario = _authViewModel.currentUser.value;
        final souEu = usuario?.pessoaId == pessoa.id;
        final criadaPorMim = usuario?.uid == pessoa.criadoPor;
        final minhaAvaliacao =
            _avaliacaoViewModel.minhasAvaliacoes.value[pessoa.id];
        final global = _rankingViewModel.posicaoGlobalDe(pessoa.id);
        final ocupado =
            _pessoaViewModel.isLoading.value || _authViewModel.isLoading.value;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              pessoa.apelido.isNotEmpty ? pessoa.apelido : pessoa.nome,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar',
                onPressed: () =>
                    context.push(AppRoutes.editar(pessoa.id), extra: pessoa),
              ),
              if (criadaPorMim)
                IconButton(
                  icon: Icon(Icons.delete_outline, color: colorScheme.error),
                  tooltip: 'Excluir',
                  onPressed: ocupado ? null : () => _confirmarExclusao(pessoa),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        pessoa.nome.isNotEmpty
                            ? pessoa.nome[0].toUpperCase()
                            : '?',
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
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _PainelPontuacao(
                            titulo: 'Seu Nível Lenda',
                            valor: minhaAvaliacao != null
                                ? '${minhaAvaliacao.pontuacaoTotal}'
                                : '—',
                            legenda: minhaAvaliacao != null
                                ? 'de 75 pontos'
                                : 'ainda não avaliou',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PainelPontuacao(
                            titulo: 'Nível Lenda Global',
                            valor: global != null
                                ? formatarMedia(global.mediaPontuacao)
                                : '—',
                            legenda: global != null
                                ? '${global.posicao}º • ${formatarQuantidadeAvaliacoes(global.totalAvaliacoes)}'
                                : 'sem avaliações',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Column(
                          children: [
                            _InfoTile(
                              icon: Icons.school_outlined,
                              title: 'Curso',
                              value: pessoa.curso,
                            ),
                            const Divider(height: 1),
                            _InfoTile(
                              icon: Icons.groups_outlined,
                              title: 'Turma / Ano',
                              value: '${pessoa.turma}',
                            ),
                            const Divider(height: 1),
                            _InfoTile(
                              icon: Icons.cake_outlined,
                              title: 'Data de nascimento',
                              value: DateFormat('dd/MM/yyyy')
                                  .format(pessoa.dataNascimento),
                            ),
                            const Divider(height: 1),
                            _InfoTile(
                              icon: Icons.person_add_alt_outlined,
                              title: 'Cadastrado por',
                              value: criadaPorMim ? 'Você' : 'Outro usuário',
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (souEu) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: colorScheme.onTertiaryContainer,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Este cadastro está vinculado à sua conta. Pelas regras do app, não é permitida autoavaliação.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onTertiaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      key: const Key('detalhe_avaliar'),
                      onPressed: souEu
                          ? null
                          : () async {
                              await context.push(
                                AppRoutes.avaliar(pessoa.id),
                                extra: pessoa,
                              );
                              _rankingViewModel.carregarRankingGlobalCommand();
                            },
                      icon: const Icon(Icons.star_rounded),
                      label: Text(
                        minhaAvaliacao != null
                            ? 'Alterar Avaliação'
                            : 'Avaliar Pessoa',
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => context.push(
                        AppRoutes.editar(pessoa.id),
                        extra: pessoa,
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar Cadastro'),
                    ),
                    const SizedBox(height: 12),
                    if (souEu || usuario?.pessoaId == null)
                      TextButton.icon(
                        onPressed: ocupado
                            ? null
                            : () => _alternarVinculo(pessoa, souEu),
                        icon: Icon(souEu ? Icons.link_off : Icons.link_rounded),
                        label: Text(
                          souEu
                              ? 'Esta pessoa não sou eu'
                              : 'Esta pessoa sou eu',
                        ),
                      ),
                    if (criadaPorMim)
                      TextButton.icon(
                        onPressed: ocupado
                            ? null
                            : () => _confirmarExclusao(pessoa),
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.error,
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Excluir Cadastro'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PainelPontuacao extends StatelessWidget {
  const _PainelPontuacao({
    required this.titulo,
    required this.valor,
    required this.legenda,
  });

  final String titulo;
  final String valor;
  final String legenda;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(titulo, style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            valor,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            legenda,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
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
