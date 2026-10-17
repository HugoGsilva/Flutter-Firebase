import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../../core/di/injection.dart';
import '../../../domain/models/ranking_item_model.dart';
import '../../viewmodels/ranking_viewmodel.dart';

class RankingPessoalView extends StatefulWidget {
  const RankingPessoalView({super.key});

  @override
  State<RankingPessoalView> createState() => _RankingPessoalViewState();
}

class _RankingPessoalViewState extends State<RankingPessoalView> {
  RankingViewModel? _rankingViewModel;

  @override
  void initState() {
    super.initState();
    if (sl.isRegistered<RankingViewModel>()) {
      _rankingViewModel = sl<RankingViewModel>();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _rankingViewModel?.carregarRankingPessoalCommand();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_rankingViewModel == null) {
      return const Center(child: Text('Carregando ranking pessoal...'));
    }

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
                    Icon(
                      Icons.person_pin_rounded,
                      color: colorScheme.primary,
                      size: 26,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ranking Pessoal',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '“Na minha opinião, quem possui o maior Nível Lenda?”',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ordenado pela pontuação atribuída nas suas avaliações.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SignalBuilder(
              builder: (context) {
                final isLoading = _rankingViewModel!.isLoading.value;
                final itens = _rankingViewModel!.rankingPessoal.value;

                if (isLoading && itens.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (itens.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      await _rankingViewModel?.carregarRankingPessoalCommand();
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.military_tech_outlined,
                                    size: 64,
                                    color: colorScheme.outline,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Nenhuma avaliação pessoal ainda',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Avalie pessoas na aba "Pessoas" para construir o seu ranking pessoal!',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await _rankingViewModel?.carregarRankingPessoalCommand();
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: itens.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = itens[index];
                      return _buildRankingCard(context, item);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingCard(BuildContext context, RankingItemModel item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pos = item.posicao;

    Color badgeBgColor;
    Color badgeTextColor;
    if (pos == 1) {
      badgeBgColor = Colors.amber.shade400;
      badgeTextColor = Colors.black87;
    } else if (pos == 2) {
      badgeBgColor = Colors.grey.shade400;
      badgeTextColor = Colors.black87;
    } else if (pos == 3) {
      badgeBgColor = Colors.brown.shade300;
      badgeTextColor = Colors.white;
    } else {
      badgeBgColor = colorScheme.surfaceContainerHighest;
      badgeTextColor = colorScheme.onSurfaceVariant;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: pos <= 3
              ? badgeBgColor.withValues(alpha: 0.8)
              : colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: pos <= 3 ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push(
          '/pessoas/detalhes/${item.pessoa.id}',
          extra: item.pessoa,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$posº',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: badgeTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.pessoa.nome,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        if (item.pessoa.apelido.isNotEmpty) ...[
                          Text(
                            '@${item.pessoa.apelido}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          item.pessoa.curso,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${item.pontuacao} pontos',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
