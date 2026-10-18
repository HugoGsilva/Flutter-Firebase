import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/avaliacao_model.dart';
import '../../domain/models/pessoa_model.dart';
import '../../domain/models/usuario_model.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String colecaoUsuarios = 'usuarios';
  static const String colecaoPessoas = 'pessoas';
  static const String colecaoAvaliacoes = 'avaliacoes';

  CollectionReference<Map<String, dynamic>> get _usuarios =>
      _firestore.collection(colecaoUsuarios);
  CollectionReference<Map<String, dynamic>> get _pessoas =>
      _firestore.collection(colecaoPessoas);
  CollectionReference<Map<String, dynamic>> get _avaliacoes =>
      _firestore.collection(colecaoAvaliacoes);

  // --- Usuários ---

  /// Grava os dados de perfil sem sobrescrever o vínculo com a pessoa.
  Future<void> salvarUsuario(UsuarioModel usuario) async {
    final dados = usuario.toMap()..remove('pessoaId');
    await _usuarios.doc(usuario.uid).set(dados, SetOptions(merge: true));
  }

  Future<UsuarioModel?> obterUsuario(String uid) async {
    final doc = await _usuarios.doc(uid).get();
    final dados = doc.data();
    if (!doc.exists || dados == null) return null;
    return UsuarioModel.fromMap(dados, uid: doc.id);
  }

  Future<UsuarioModel?> buscarUsuarioPorPessoa(String pessoaId) async {
    final snapshot = await _usuarios
        .where('pessoaId', isEqualTo: pessoaId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return UsuarioModel.fromMap(doc.data(), uid: doc.id);
  }

  Future<void> atualizarPessoaVinculada(String uid, String? pessoaId) async {
    await _usuarios.doc(uid).set({
      'pessoaId': pessoaId,
    }, SetOptions(merge: true));
  }

  // --- Pessoas ---

  Future<String> salvarPessoa(PessoaModel pessoa) async {
    final ref = pessoa.id.isEmpty ? _pessoas.doc() : _pessoas.doc(pessoa.id);
    await ref.set(pessoa.toMap());
    return ref.id;
  }

  Future<void> atualizarPessoa(PessoaModel pessoa) async {
    final dados = pessoa.toMap()..remove('criadoPor');
    await _pessoas.doc(pessoa.id).update(dados);
  }

  /// Exclui a pessoa junto com as avaliações recebidas, para que elas não
  /// continuem contando nos rankings.
  Future<void> removerPessoa(String id) async {
    final avaliacoes = await _avaliacoes.where('pessoaId', isEqualTo: id).get();

    final batch = _firestore.batch();
    for (final doc in avaliacoes.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_pessoas.doc(id));
    await batch.commit();
  }

  Future<PessoaModel?> obterPessoa(String id) async {
    final doc = await _pessoas.doc(id).get();
    final dados = doc.data();
    if (!doc.exists || dados == null) return null;
    return PessoaModel.fromMap(dados, id: doc.id);
  }

  Future<List<PessoaModel>> listarPessoas() async {
    final snapshot = await _pessoas.orderBy('nome').get();
    return snapshot.docs
        .map((doc) => PessoaModel.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  // --- Avaliações ---

  Future<void> salvarAvaliacao(AvaliacaoModel avaliacao) async {
    final id = AvaliacaoModel.gerarIdCanonico(
      avaliacao.avaliadorUid,
      avaliacao.pessoaId,
    );
    await _avaliacoes.doc(id).set(avaliacao.toMap());
  }

  Future<AvaliacaoModel?> obterAvaliacao(
    String avaliadorUid,
    String pessoaId,
  ) async {
    final id = AvaliacaoModel.gerarIdCanonico(avaliadorUid, pessoaId);
    final doc = await _avaliacoes.doc(id).get();
    final dados = doc.data();
    if (!doc.exists || dados == null) return null;
    return AvaliacaoModel.fromMap(dados, id: doc.id);
  }

  Future<List<AvaliacaoModel>> listarAvaliacoesPorPessoa(String pessoaId) {
    return _listarAvaliacoes(
      _avaliacoes.where('pessoaId', isEqualTo: pessoaId),
    );
  }

  Future<List<AvaliacaoModel>> listarAvaliacoesPorAvaliador(
    String avaliadorUid,
  ) {
    return _listarAvaliacoes(
      _avaliacoes.where('avaliadorUid', isEqualTo: avaliadorUid),
    );
  }

  Future<List<AvaliacaoModel>> listarTodasAvaliacoes() {
    return _listarAvaliacoes(_avaliacoes);
  }

  Future<List<AvaliacaoModel>> _listarAvaliacoes(
    Query<Map<String, dynamic>> query,
  ) async {
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => AvaliacaoModel.fromMap(doc.data(), id: doc.id))
        .toList();
  }
}
