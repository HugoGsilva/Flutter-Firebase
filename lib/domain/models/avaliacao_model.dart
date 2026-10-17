import 'criterios_avaliacao.dart';

class AvaliacaoModel {
  const AvaliacaoModel({
    required this.id,
    required this.avaliadorUid,
    required this.pessoaId,
    required this.notas,
    required this.pontuacaoTotal,
    required this.dataAvaliacao,
  });

  final String id;
  final String avaliadorUid;
  final String pessoaId;
  final Map<String, int> notas;
  final int pontuacaoTotal;
  final DateTime dataAvaliacao;

  static String gerarIdCanonico(String avaliadorUid, String pessoaId) =>
      '${avaliadorUid}_$pessoaId';

  AvaliacaoModel copyWith({
    String? id,
    String? avaliadorUid,
    String? pessoaId,
    Map<String, int>? notas,
    int? pontuacaoTotal,
    DateTime? dataAvaliacao,
  }) {
    return AvaliacaoModel(
      id: id ?? this.id,
      avaliadorUid: avaliadorUid ?? this.avaliadorUid,
      pessoaId: pessoaId ?? this.pessoaId,
      notas: notas ?? this.notas,
      pontuacaoTotal: pontuacaoTotal ?? this.pontuacaoTotal,
      dataAvaliacao: dataAvaliacao ?? this.dataAvaliacao,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'avaliadorUid': avaliadorUid,
      'pessoaId': pessoaId,
      'notas': notas,
      'pontuacaoTotal': pontuacaoTotal,
      'dataAvaliacao': dataAvaliacao.toIso8601String(),
    };
  }

  factory AvaliacaoModel.fromMap(Map<String, dynamic> map) {
    final rawNotas = map['notas'];
    final parsedNotas = <String, int>{};
    if (rawNotas is Map) {
      for (final entry in rawNotas.entries) {
        parsedNotas[entry.key.toString()] = (entry.value as num).toInt();
      }
    }

    final pontuacao = (map['pontuacaoTotal'] as num?)?.toInt() ??
        CriterioAvaliacao.calcularPontuacaoTotal(parsedNotas);

    return AvaliacaoModel(
      id: map['id'] as String? ?? '',
      avaliadorUid: map['avaliadorUid'] as String? ?? '',
      pessoaId: map['pessoaId'] as String? ?? '',
      notas: parsedNotas,
      pontuacaoTotal: pontuacao,
      dataAvaliacao: map['dataAvaliacao'] != null
          ? DateTime.tryParse(map['dataAvaliacao'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvaliacaoModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
