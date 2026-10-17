import 'pessoa_model.dart';

class RankingItemModel {
  const RankingItemModel({
    required this.pessoa,
    required this.pontuacao,
    required this.mediaPontuacao,
    required this.totalAvaliacoes,
    required this.posicao,
  });

  final PessoaModel pessoa;
  final int pontuacao;
  final double mediaPontuacao;
  final int totalAvaliacoes;
  final int posicao;

  RankingItemModel copyWith({
    PessoaModel? pessoa,
    int? pontuacao,
    double? mediaPontuacao,
    int? totalAvaliacoes,
    int? posicao,
  }) {
    return RankingItemModel(
      pessoa: pessoa ?? this.pessoa,
      pontuacao: pontuacao ?? this.pontuacao,
      mediaPontuacao: mediaPontuacao ?? this.mediaPontuacao,
      totalAvaliacoes: totalAvaliacoes ?? this.totalAvaliacoes,
      posicao: posicao ?? this.posicao,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RankingItemModel &&
          runtimeType == other.runtimeType &&
          pessoa == other.pessoa &&
          posicao == other.posicao;

  @override
  int get hashCode => pessoa.hashCode ^ posicao.hashCode;
}
