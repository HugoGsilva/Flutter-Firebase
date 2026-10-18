import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.rating,
    this.onRatingChanged,
    this.starSize = 32.0,
    this.maximo = 5,
  });

  final int rating;
  final ValueChanged<int>? onRatingChanged;
  final double starSize;
  final int maximo;

  @override
  Widget build(BuildContext context) {
    final inactiveColor = Theme.of(context).colorScheme.outlineVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maximo, (index) {
        final valor = index + 1;
        final preenchida = valor <= rating;

        final icon = Icon(
          preenchida ? Icons.star_rounded : Icons.star_outline_rounded,
          color: preenchida ? AppColors.estrela : inactiveColor,
          size: starSize,
          semanticLabel: '$valor estrela${valor > 1 ? 's' : ''}',
        );

        if (onRatingChanged == null) return icon;

        return InkResponse(
          key: ValueKey('estrela_$valor'),
          onTap: () => onRatingChanged!(valor),
          radius: starSize * 0.7,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: icon,
          ),
        );
      }),
    );
  }
}
