import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.rating,
    this.onRatingChanged,
    this.starSize = 32.0,
    this.color,
  });

  final int rating;
  final ValueChanged<int>? onRatingChanged;
  final double starSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? Colors.amber.shade700;
    final inactiveColor = Theme.of(context).colorScheme.outlineVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isFilled = starIndex <= rating;

        final icon = Icon(
          isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
          color: isFilled ? activeColor : inactiveColor,
          size: starSize,
        );

        if (onRatingChanged == null) {
          return icon;
        }

        return InkResponse(
          onTap: () => onRatingChanged!(starIndex),
          radius: starSize,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: icon,
          ),
        );
      }),
    );
  }
}
