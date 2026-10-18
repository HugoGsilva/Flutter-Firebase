import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/models/ranking_item_model.dart';
import '../../widgets/feedback.dart';
import '../../widgets/formatacao.dart';

class RankingLista extends StatelessWidget {
  const RankingLista({
    super.key,
    required this.icone,
    required this.titulo,
    required this.pergunta,
    required this.explicacao,
    required this.itens,
    required this.carregando,
    required this.onRefresh,
    required this.mensagemVazia,
    this.global = false,
  });

  final IconData icone;
  final String titulo;
  final String pergunta;
  final String explicacao;
  final List<RankingItemModel> itens;
  final bool carregando;
  final Future<void> Function() onRefresh;
  final String mensagemVazia;

  /// No ranking global exibe a média com uma casa decimal e a quantidade de
  /// avaliações recebidas.
  final bool global;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            border: Border(
              bottom: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icone, color: colorScheme.primary, size: 26),
                  const SizedBox(width: 8),
                  Text(
                    titulo,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                pergunta,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                explicacao,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: carregando && itens.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: onRefresh,
                  child: itens.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 60),
                            EstadoVazio(
                              icone: Icons.military_tech_outlined,
                              titulo: 'Ranking vazio',
                              mensagem: mensagemVazia,
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          itemCount: itens.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) =>
                              _RankingCard(item: itens[index], global: global),
                        ),
                ),
        ),
      ],
    );
  }
}

class _RankingCard extends StatelessWidget {
  const _RankingCard({required this.item, required this.global});

  final RankingItemModel item;
  final bool global;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pos = item.posicao;
    final corPosicao = AppColors.corDaPosicao(pos, colorScheme);
    final pessoa = item.pessoa;

    final pontos = global
        ? '${formatarMedia(item.mediaPontuacao)} pontos'
        : '${item.pontuacao} pontos';

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: pos <= 3 ? corPosicao : colorScheme.outlineVariant,
          width: pos <= 3 ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: () => context.push(AppRoutes.detalhes(pessoa.id), extra: pessoa),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: corPosicao,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$posº',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.textoDaPosicao(pos, colorScheme),
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
                      pessoa.nome,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      [
                        if (pessoa.apelido.isNotEmpty) '"${pessoa.apelido}"',
                        '${pessoa.curso} ${pessoa.turma}',
                      ].join(' • '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      pontos,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (global)
                      Text(
                        formatarQuantidadeAvaliacoes(item.totalAvaliacoes),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
