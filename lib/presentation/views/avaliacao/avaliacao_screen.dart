import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/di/injection.dart';
import '../../../core/result/result.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/criterios_avaliacao.dart';
import '../../../domain/models/pessoa_model.dart';
import '../../viewmodels/avaliacao_viewmodel.dart';
import '../../viewmodels/pessoa_viewmodel.dart';
import '../widgets/feedback.dart';
import 'widgets/star_rating.dart';

class AvaliacaoScreen extends StatefulWidget {
  const AvaliacaoScreen({super.key, required this.pessoaId, this.pessoa});

  final String pessoaId;
  final PessoaModel? pessoa;

  @override
  State<AvaliacaoScreen> createState() => _AvaliacaoScreenState();
}

class _AvaliacaoScreenState extends State<AvaliacaoScreen> {
  final _avaliacaoViewModel = sl<AvaliacaoViewModel>();
  final _pessoaViewModel = sl<PessoaViewModel>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_pessoaViewModel.pessoaPorId(widget.pessoaId) == null &&
          widget.pessoa == null) {
        _pessoaViewModel.buscarPessoaCommand(widget.pessoaId);
      }
      await _avaliacaoViewModel.carregarAvaliacaoCommand(widget.pessoaId);
      final erro = _avaliacaoViewModel.errorMessage.value;
      if (erro != null && mounted) {
        mostrarErro(context, erro);
        _avaliacaoViewModel.limparErro();
      }
    });
  }

  Future<void> _salvar() async {
    final result = await _avaliacaoViewModel.avaliarPessoaCommand(
      widget.pessoaId,
    );
    if (!mounted) return;

    if (result case Success(data: final avaliacao)) {
      mostrarSucesso(
        context,
        'Avaliação salva! Nível Lenda: ${avaliacao.pontuacaoTotal} pontos.',
      );
      context.pop();
    } else {
      mostrarErro(
        context,
        _avaliacaoViewModel.errorMessage.value ??
            'Não foi possível salvar a avaliação.',
      );
      _avaliacaoViewModel.limparErro();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final pessoa =
            _pessoaViewModel.pessoaPorId(widget.pessoaId) ?? widget.pessoa;
        final carregando =
            _avaliacaoViewModel.carregarAvaliacaoCommand.runningSignal.value;
        final salvando =
            _avaliacaoViewModel.avaliarPessoaCommand.runningSignal.value;
        final pontuacao = _avaliacaoViewModel.pontuacaoTotal.value;
        final notas = _avaliacaoViewModel.notas.value;
        final jaAvaliou = _avaliacaoViewModel.avaliacaoExistente.value != null;
        final auto = _avaliacaoViewModel.isAutoavaliacao.value;

        final apelido = pessoa?.apelido ?? '';

        return Scaffold(
          appBar: AppBar(
            title: Text(apelido.isNotEmpty ? 'Avaliar $apelido' : 'Avaliar'),
          ),
          body: carregando
              ? const Center(child: CircularProgressIndicator())
              : auto
              ? const _BloqueioAutoavaliacao()
              : Column(
                  children: [
                    _NivelLendaHeader(
                      nome: pessoa?.nome ?? '',
                      apelido: apelido,
                      pontuacao: pontuacao,
                      jaAvaliou: jaAvaliou,
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
                          return _CriterioCard(
                            numero: index + 1,
                            criterio: criterio,
                            nota:
                                notas[criterio.id] ??
                                AvaliacaoViewModel.notaInicial,
                            onChanged: salvando
                                ? null
                                : (nota) => _avaliacaoViewModel.definirNota(
                                    criterio,
                                    nota,
                                  ),
                          );
                        },
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            key: const Key('avaliacao_salvar'),
                            onPressed: salvando ? null : _salvar,
                            icon: salvando
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.check_circle_outline),
                            label: Text(
                              jaAvaliou
                                  ? 'Atualizar Avaliação'
                                  : 'Salvar Avaliação',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _BloqueioAutoavaliacao extends StatelessWidget {
  const _BloqueioAutoavaliacao();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
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
              'Autoavaliação bloqueada',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Esta pessoa está vinculada à sua conta. Pelas regras do PiramidGame, o usuário autenticado não pode avaliar a si próprio.',
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
}

class _NivelLendaHeader extends StatelessWidget {
  const _NivelLendaHeader({
    required this.nome,
    required this.apelido,
    required this.pontuacao,
    required this.jaAvaliou,
  });

  final String nome;
  final String apelido;
  final int pontuacao;
  final bool jaAvaliou;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const minimo = CriterioAvaliacao.pontuacaoMinima;
    const maximo = CriterioAvaliacao.pontuacaoMaxima;
    final progresso = (pontuacao - minimo) / (maximo - minimo);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
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
                    Text(
                      jaAvaliou
                          ? 'Alterando sua avaliação anterior'
                          : 'Dê de 1 a 5 estrelas em cada critério',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: jaAvaliou
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        fontWeight: jaAvaliou ? FontWeight.bold : null,
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
                ),
                child: Column(
                  children: [
                    Text(
                      '$pontuacao',
                      key: const Key('avaliacao_pontuacao'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Nível Lenda',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimary,
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
              value: progresso.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                pontuacao >= 60 ? AppColors.douradoLenda : colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mínimo: $minimo pts', style: theme.textTheme.labelSmall),
              Text('Máximo: $maximo pts', style: theme.textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _CriterioCard extends StatelessWidget {
  const _CriterioCard({
    required this.numero,
    required this.criterio,
    required this.nota,
    required this.onChanged,
  });

  final int numero;
  final CriterioAvaliacao criterio;
  final int nota;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$numero. ${criterio.nome}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '$nota / 5',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
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
                key: Key('estrelas_${criterio.id}'),
                rating: nota,
                starSize: 34,
                onRatingChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
