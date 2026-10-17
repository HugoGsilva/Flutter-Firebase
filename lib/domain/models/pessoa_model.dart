class PessoaModel {
  const PessoaModel({
    required this.id,
    required this.nome,
    required this.apelido,
    required this.curso,
    required this.turma,
    required this.dataNascimento,
    required this.criadoPor,
  });

  final String id;
  final String nome;
  final String apelido;
  final String curso;
  final int turma;
  final DateTime dataNascimento;
  final String criadoPor;

  static const List<String> cursosValidos = [
    'INFO',
    'MEC',
    'MAMB',
    'PROD',
    'TADS',
    'TGA',
  ];

  static const int turmaAnoMinimo = 1998;
  static const int turmaAnoMaximo = 2026;

  static bool isCursoValido(String curso) =>
      cursosValidos.contains(curso.toUpperCase());

  static bool isTurmaValida(int turma) =>
      turma >= turmaAnoMinimo && turma <= turmaAnoMaximo;

  PessoaModel copyWith({
    String? id,
    String? nome,
    String? apelido,
    String? curso,
    int? turma,
    DateTime? dataNascimento,
    String? criadoPor,
  }) {
    return PessoaModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      apelido: apelido ?? this.apelido,
      curso: curso ?? this.curso,
      turma: turma ?? this.turma,
      dataNascimento: dataNascimento ?? this.dataNascimento,
      criadoPor: criadoPor ?? this.criadoPor,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'apelido': apelido,
      'curso': curso,
      'turma': turma,
      'dataNascimento': dataNascimento.toIso8601String(),
      'criadoPor': criadoPor,
    };
  }

  factory PessoaModel.fromMap(Map<String, dynamic> map) {
    return PessoaModel(
      id: map['id'] as String? ?? '',
      nome: map['nome'] as String? ?? '',
      apelido: map['apelido'] as String? ?? '',
      curso: map['curso'] as String? ?? '',
      turma: (map['turma'] as num?)?.toInt() ?? turmaAnoMinimo,
      dataNascimento: map['dataNascimento'] != null
          ? DateTime.tryParse(map['dataNascimento'] as String) ??
                DateTime(2000, 1, 1)
          : DateTime(2000, 1, 1),
      criadoPor: map['criadoPor'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PessoaModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
