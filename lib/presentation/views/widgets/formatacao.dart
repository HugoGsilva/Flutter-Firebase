/// Formata a média com uma casa decimal e vírgula (ex.: 68,4).
String formatarMedia(double media) =>
    media.toStringAsFixed(1).replaceAll('.', ',');

String formatarQuantidadeAvaliacoes(int total) =>
    total == 1 ? '1 avaliação' : '$total avaliações';
