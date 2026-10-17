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

  // --- Usuários ---

  Future<void> salvarUsuario(UsuarioModel usuario) async {
    await _firestore
        .collection(colecaoUsuarios)
        .doc(usuario.uid)
        .set(usuario.toMap(), SetOptions(merge: true));
  }

  Future<UsuarioModel?> obterUsuario(String uid) async {
    final doc = await _firestore.collection(colecaoUsuarios).doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return UsuarioModel.fromMap(doc.data()!);
  }

  // --- Pessoas ---

  Future<void> salvarPessoa(PessoaModel pessoa) async {
    await _firestore
        .collection(colecaoPessoas)
        .doc(pessoa.id)
        .set(pessoa.toMap());
  }

  Future<void> atualizarPessoa(PessoaModel pessoa) async {
    await _firestore
        .collection(colecaoPessoas)
        .doc(pessoa.id)
        .update(pessoa.toMap());
  }

  Future<void> removerPessoa(String id) async {
    await _firestore.collection(colecaoPessoas).doc(id).delete();

    // Remove também as avaliações vinculadas a esta pessoa
    final snapshot = await _firestore
        .collection(colecaoAvaliacoes)
        .where('pessoaId', isEqualTo: id)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<PessoaModel?> obterPessoa(String id) async {
    final doc = await _firestore.collection(colecaoPessoas).doc(id).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return PessoaModel.fromMap(doc.data()!);
  }

  Future<List<PessoaModel>> listarPessoas() async {
    final snapshot = await _firestore.collection(colecaoPessoas).get();
    return snapshot.docs
        .map((doc) => PessoaModel.fromMap(doc.data()))
        .toList();
  }

  // --- Avaliações ---

  Future<void> salvarAvaliacao(AvaliacaoModel avaliacao) async {
    final idCanonico = AvaliacaoModel.gerarIdCanonico(
      avaliacao.avaliadorUid,
      avaliacao.pessoaId,
    );
    final dados = avaliacao.copyWith(id: idCanonico).toMap();

    await _firestore
        .collection(colecaoAvaliacoes)
        .doc(idCanonico)
        .set(dados);
  }

  Future<AvaliacaoModel?> obterAvaliacao(
    String avaliadorUid,
    String pessoaId,
  ) async {
    final idCanonico = AvaliacaoModel.gerarIdCanonico(avaliadorUid, pessoaId);
    final doc =
        await _firestore.collection(colecaoAvaliacoes).doc(idCanonico).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return AvaliacaoModel.fromMap(doc.data()!);
  }

  Future<List<AvaliacaoModel>> listarAvaliacoesPorPessoa(
    String pessoaId,
  ) async {
    final snapshot = await _firestore
        .collection(colecaoAvaliacoes)
        .where('pessoaId', isEqualTo: pessoaId)
        .get();

    return snapshot.docs
        .map((doc) => AvaliacaoModel.fromMap(doc.data()))
        .toList();
  }

  Future<List<AvaliacaoModel>> listarAvaliacoesPorAvaliador(
    String avaliadorUid,
  ) async {
    final snapshot = await _firestore
        .collection(colecaoAvaliacoes)
        .where('avaliadorUid', isEqualTo: avaliadorUid)
        .get();

    return snapshot.docs
        .map((doc) => AvaliacaoModel.fromMap(doc.data()))
        .toList();
  }

  Future<List<AvaliacaoModel>> listarTodasAvaliacoes() async {
    final snapshot = await _firestore.collection(colecaoAvaliacoes).get();
    return snapshot.docs
        .map((doc) => AvaliacaoModel.fromMap(doc.data()))
        .toList();
  }
}
