import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/di/injection.dart';
import '../../../core/result/result.dart';
import '../../../domain/models/criterios_avaliacao.dart';
import '../../../domain/models/pessoa_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/avaliacao_viewmodel.dart';
import '../../viewmodels/pessoa_viewmodel.dart';
import 'widgets/star_rating.dart';

class AvaliacaoScreen extends StatefulWidget {
  const AvaliacaoScreen({super.key, required this.pessoaId, this.pessoa});

  final String pessoaId;
  final PessoaModel? pessoa;

  @override
  State<AvaliacaoScreen> createState() => _AvaliacaoScreenState();
}

class _AvaliacaoScreenState extends State<AvaliacaoScreen> {
  late final AvaliacaoViewModel _avaliacaoViewModel;
  late final AuthViewModel _authViewModel;
  late final PessoaViewModel _pessoaViewModel;
  PessoaModel? _pessoa;

  @override
  void initState() {
    super.initState();
    _avaliacaoViewModel = sl<AvaliacaoViewModel>();
    _authViewModel = sl<AuthViewModel>();
    _pessoaViewModel = sl<PessoaViewModel>();

    _carregarPessoaEAvaliacao();
  }

  void _carregarPessoaEAvaliacao() {
    _pessoa = widget.pessoa;
    if (_pessoa == null) {
      final lista = _pessoaViewModel.pessoas.value;
      _pessoa = lista.where((p) => p.id == widget.pessoaId).firstOrNull;
    }

    final usuarioUid = _authViewModel.currentUser.value?.uid ?? '';
    if (usuarioUid.isNotEmpty) {
      _avaliacaoViewModel.carregarAvaliacaoCommand(widget.pessoaId, usuarioUid);
    }
  }

  bool get _isAutoavaliacao {
    final usuarioUid = _authViewModel.currentUser.value?.uid ?? '';
    if (usuarioUid.isEmpty) return false;
    final criadorUid = _pessoa?.criadoPor ?? '';
    return usuarioUid == criadorUid || usuarioUid == widget.pessoaId;
  }

  Future<void> _salvar() async {
    final usuarioUid = _authViewModel.currentUser.value?.uid ?? '';
    if (usuarioUid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você precisa estar autenticado para avaliar.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final result = await _avaliacaoViewModel.salvarAvaliacaoCommand(
      widget.pessoaId,
      usuarioUid,
      _pessoa?.criadoPor,
    );

    if (!mounted) return;

    if (result case Success()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avaliação salva com sucesso!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } else if (result case Failure()) {
      final msg =
          _avaliacaoViewModel.errorMessage.value ??
          'Não foi possível salvar a avaliação.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _avaliacaoViewModel.limparErro();
    }
  }

  @override
  Widget build(BuildContext context) {
    final nomePessoa = _pessoa?.nome ?? 'Colega do IFPR';
    final apelidoPessoa = _pessoa?.apelido ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          apelidoPessoa.isNotEmpty
              ? 'Avaliar $apelidoPessoa'
              : 'Avaliar Pessoa',
        ),
      ),
      body: _isAutoavaliacao
          ? _buildBloqueioAutoavaliacao(context)
          : SignalBuilder(
              builder: (context) {
                final isLoading = _avaliacaoViewModel.isLoading.value;
                final pontuacao = _avaliacaoViewModel.pontuacaoTotal.value;
                final notas = _avaliacaoViewModel.notas.value;
                final jaAvaliou =
                    _avaliacaoViewModel.avaliacaoExistente.value != null;

                return Column(
                  children: [
                    _buildNivelLendaHeader(
                      context,
                      nomePessoa,
                      apelidoPessoa,
                      pontuacao,
                      jaAvaliou,
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: CriterioAvaliacao.values.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final criterio = CriterioAvaliacao.values[index];
                          final notaAtual = notas[criterio.id] ?? 3;

                          return _buildCriterioCard(
                            context,
                            criterio,
                            notaAtual,
                            isLoading,
                          );
                        },
                      ),
                    ),
                    _buildFooterButton(context, isLoading, jaAvaliou),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildBloqueioAutoavaliacao(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.block_rounded,
                size: 64,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Autoavaliação Bloqueada',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Pelas regras do PiramidGame, um usuário não pode avaliar o próprio perfil nem cadastros criados por si mesmo.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNivelLendaHeader(
    BuildContext context,
    String nome,
    String apelido,
    int pontuacao,
    bool jaAvaliou,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = (pontuacao - 15) / (75 - 15);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (apelido.isNotEmpty)
                      Text(
                        '@$apelido',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '$pontuacao',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Nível Lenda',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimary.withValues(alpha: 0.85),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                pontuacao >= 60 ? Colors.amber.shade700 : colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mínimo: 15 pts',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              if (jaAvaliou)
                Text(
                  'Modificando avaliação anterior',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              Text(
                'Máximo: 75 pts',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCriterioCard(
    BuildContext context,
    CriterioAvaliacao criterio,
    int notaAtual,
    bool isLoading,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    criterio.nome,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$notaAtual / 5',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              criterio.descricao,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: StarRating(
                rating: notaAtual,
                starSize: 34,
                onRatingChanged: isLoading
                    ? null
                    : (novaNota) {
                        _avaliacaoViewModel.definirNota(criterio, novaNota);
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterButton(
    BuildContext context,
    bool isLoading,
    bool jaAvaliou,
  ) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: isLoading ? null : _salvar,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(
              jaAvaliou ? 'Atualizar Avaliação' : 'Salvar Avaliação',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
