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

  /// Usuário + pessoa avaliada = uma avaliação.
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
      'avaliadorUid': avaliadorUid,
      'pessoaId': pessoaId,
      for (final criterio in CriterioAvaliacao.values)
        criterio.id: notas[criterio.id],
      'pontuacaoTotal': pontuacaoTotal,
      'dataAvaliacao': dataAvaliacao.toIso8601String(),
    };
  }

  factory AvaliacaoModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final notas = <String, int>{
      for (final criterio in CriterioAvaliacao.values)
        if (map[criterio.id] is num)
          criterio.id: (map[criterio.id] as num).toInt(),
    };

    final dataRaw = map['dataAvaliacao'];

    return AvaliacaoModel(
      id: id ?? map['id'] as String? ?? '',
      avaliadorUid: map['avaliadorUid'] as String? ?? '',
      pessoaId: map['pessoaId'] as String? ?? '',
      notas: notas,
      pontuacaoTotal:
          (map['pontuacaoTotal'] as num?)?.toInt() ??
          CriterioAvaliacao.calcularPontuacaoTotal(notas),
      dataAvaliacao: dataRaw is String
          ? DateTime.tryParse(dataRaw) ?? DateTime.now()
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
