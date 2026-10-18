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

  /// Retorna a mensagem do primeiro problema encontrado ou null se estiver ok.
  String? validar() {
    if (nome.trim().length < 2) {
      return 'O nome deve ter no mínimo 2 caracteres.';
    }
    if (apelido.trim().isEmpty) {
      return 'Informe o apelido da pessoa.';
    }
    if (!isCursoValido(curso)) {
      return 'Curso inválido. Escolha um dos cursos: ${cursosValidos.join(", ")}.';
    }
    if (!isTurmaValida(turma)) {
      return 'Turma/Ano deve estar entre $turmaAnoMinimo e $turmaAnoMaximo.';
    }
    if (dataNascimento.isAfter(DateTime.now())) {
      return 'A data de nascimento não pode estar no futuro.';
    }
    return null;
  }

  PessoaModel normalizada() {
    return copyWith(
      nome: nome.trim(),
      apelido: apelido.trim(),
      curso: curso.trim().toUpperCase(),
    );
  }

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
      'nome': nome,
      'apelido': apelido,
      'curso': curso,
      'turma': turma,
      'dataNascimento': dataNascimento.toIso8601String(),
      'criadoPor': criadoPor,
    };
  }

  factory PessoaModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final dataRaw = map['dataNascimento'];

    return PessoaModel(
      id: id ?? map['id'] as String? ?? '',
      nome: map['nome'] as String? ?? '',
      apelido: map['apelido'] as String? ?? '',
      curso: map['curso'] as String? ?? '',
      turma: (map['turma'] as num?)?.toInt() ?? turmaAnoMinimo,
      dataNascimento: dataRaw is String
          ? DateTime.tryParse(dataRaw) ?? DateTime(2000)
          : DateTime(2000),
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
