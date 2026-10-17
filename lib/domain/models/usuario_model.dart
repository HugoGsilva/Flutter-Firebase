class UsuarioModel {
  const UsuarioModel({
    required this.uid,
    required this.nome,
    required this.email,
    this.foto,
    required this.provider,
  });

  final String uid;
  final String nome;
  final String email;
  final String? foto;
  final String provider;

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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nome': nome,
      'email': email,
      'foto': foto,
      'provider': provider,
    };
  }

  factory UsuarioModel.fromMap(Map<String, dynamic> map) {
    return UsuarioModel(
      uid: map['uid'] as String? ?? '',
      nome: map['nome'] as String? ?? '',
      email: map['email'] as String? ?? '',
      foto: map['foto'] as String?,
      provider: map['provider'] as String? ?? 'password',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsuarioModel &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email;

  @override
  int get hashCode => uid.hashCode ^ email.hashCode;
}
