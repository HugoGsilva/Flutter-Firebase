class UsuarioModel {
  const UsuarioModel({
    required this.uid,
    required this.nome,
    required this.email,
    this.foto,
    required this.provider,
    this.pessoaId,
  });

  final String uid;
  final String nome;
  final String email;
  final String? foto;
  final String provider;

  /// Pessoa cadastrada que representa este usuário (usada para impedir
  /// autoavaliação). Pode ser nula quando o usuário ainda não se vinculou.
  final String? pessoaId;

  UsuarioModel copyWith({
    String? uid,
    String? nome,
    String? email,
    String? foto,
    String? provider,
  }) {
    return UsuarioModel(
      uid: uid ?? this.uid,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      foto: foto ?? this.foto,
      provider: provider ?? this.provider,
      pessoaId: pessoaId,
    );
  }

  UsuarioModel comPessoaVinculada(String? novaPessoaId) {
    return UsuarioModel(
      uid: uid,
      nome: nome,
      email: email,
      foto: foto,
      provider: provider,
      pessoaId: novaPessoaId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'email': email,
      'foto': foto,
      'provider': provider,
      'pessoaId': pessoaId,
    };
  }

  factory UsuarioModel.fromMap(Map<String, dynamic> map, {String? uid}) {
    return UsuarioModel(
      uid: uid ?? map['uid'] as String? ?? '',
      nome: map['nome'] as String? ?? '',
      email: map['email'] as String? ?? '',
      foto: map['foto'] as String?,
      provider: map['provider'] as String? ?? 'password',
      pessoaId: map['pessoaId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsuarioModel &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email &&
          pessoaId == other.pessoaId;

  @override
  int get hashCode => Object.hash(uid, email, pessoaId);
}
