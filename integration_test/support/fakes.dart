import 'package:piramid_game/core/result/app_exception.dart';
import 'package:piramid_game/domain/models/avaliacao_model.dart';
import 'package:piramid_game/domain/models/criterios_avaliacao.dart';
import 'package:piramid_game/domain/models/pessoa_model.dart';
import 'package:piramid_game/domain/models/usuario_model.dart';
import 'package:piramid_game/domain/repositories/auth_repository.dart';
import 'package:piramid_game/domain/repositories/avaliacao_repository.dart';
import 'package:piramid_game/domain/repositories/pessoa_repository.dart';
import 'package:piramid_game/domain/repositories/preference_repository.dart';

/// Simula o Firebase Authentication + coleção `usuarios`.
class FakeAuthRepository implements AuthRepository {
  final Map<String, ({UsuarioModel usuario, String senha})> contas = {};
  final Map<String, UsuarioModel> perfis = {};
  UsuarioModel? logado;
  UsuarioModel? contaGoogle;
  int _seq = 0;

  void entrarComo(UsuarioModel usuario) {
    perfis[usuario.uid] = usuario;
    logado = usuario;
  }

  @override
  UsuarioModel? get usuarioAtual => logado;

  @override
  Future<UsuarioModel> cadastrarComEmail({
    required String nome,
    required String email,
    required String senha,
  }) async {
    if (contas.containsKey(email)) {
      throw const AppException('Já existe uma conta com este e-mail.');
    }
    final usuario = UsuarioModel(
      uid: 'uid_${++_seq}',
      nome: nome,
      email: email,
      provider: 'password',
    );
    contas[email] = (usuario: usuario, senha: senha);
    perfis[usuario.uid] = usuario;
    return logado = usuario;
  }

  @override
  Future<UsuarioModel> loginComEmail({
    required String email,
    required String senha,
  }) async {
    final conta = contas[email];
    if (conta == null || conta.senha != senha) {
      throw const AppException('E-mail ou senha incorretos.');
    }
    return logado = perfis[conta.usuario.uid] ?? conta.usuario;
  }

  @override
  Future<UsuarioModel> loginComGoogle() async {
    final google = contaGoogle;
    if (google == null) {
      throw const AppException('Login com Google cancelado.');
    }
    perfis.putIfAbsent(google.uid, () => google);
    return logado = perfis[google.uid]!;
  }

  @override
  Future<void> logout() async => logado = null;

  @override
  Future<UsuarioModel?> restaurarSessao() async {
    final atual = logado;
    return atual == null ? null : perfis[atual.uid] ?? atual;
  }

  @override
  Future<UsuarioModel?> buscarUsuario(String uid) async => perfis[uid];

  @override
  Future<UsuarioModel?> buscarUsuarioVinculado(String pessoaId) async {
    return perfis.values.where((u) => u.pessoaId == pessoaId).firstOrNull;
  }

  @override
  Future<void> vincularPessoa(String uid, String? pessoaId) async {
    final perfil = perfis[uid] ?? logado!;
    perfis[uid] = perfil.comPessoaVinculada(pessoaId);
  }
}

class FakePessoaRepository implements PessoaRepository {
  final Map<String, PessoaModel> dados = {};
  final FakeAvaliacaoRepository? avaliacoes;
  int _seq = 0;
  bool falhar = false;

  FakePessoaRepository({this.avaliacoes});

  void _talvezFalhar() {
    if (falhar) throw const AppException('Servidor indisponível.');
  }

  @override
  Future<PessoaModel> cadastrarPessoa(PessoaModel pessoa) async {
    _talvezFalhar();
    final salva = pessoa.copyWith(id: 'pes_${++_seq}');
    dados[salva.id] = salva;
    return salva;
  }

  @override
  Future<void> atualizarPessoa(PessoaModel pessoa) async {
    _talvezFalhar();
    dados[pessoa.id] = pessoa;
  }

  @override
  Future<void> removerPessoa(String id) async {
    _talvezFalhar();
    dados.remove(id);
    avaliacoes?.dados.removeWhere((_, a) => a.pessoaId == id);
  }

  @override
  Future<PessoaModel?> buscarPorId(String id) async {
    _talvezFalhar();
    return dados[id];
  }

  @override
  Future<List<PessoaModel>> listarTodas() async {
    _talvezFalhar();
    return dados.values.toList();
  }
}

class FakeAvaliacaoRepository implements AvaliacaoRepository {
  final Map<String, AvaliacaoModel> dados = {};

  @override
  Future<void> salvarAvaliacao(AvaliacaoModel avaliacao) async {
    final id = AvaliacaoModel.gerarIdCanonico(
      avaliacao.avaliadorUid,
      avaliacao.pessoaId,
    );
    dados[id] = avaliacao.copyWith(id: id);
  }

  @override
  Future<AvaliacaoModel?> buscarAvaliacao(
    String avaliadorUid,
    String pessoaId,
  ) async {
    return dados[AvaliacaoModel.gerarIdCanonico(avaliadorUid, pessoaId)];
  }

  @override
  Future<List<AvaliacaoModel>> listarPorPessoa(String pessoaId) async =>
      dados.values.where((a) => a.pessoaId == pessoaId).toList();

  @override
  Future<List<AvaliacaoModel>> listarPorAvaliador(String avaliadorUid) async =>
      dados.values.where((a) => a.avaliadorUid == avaliadorUid).toList();

  @override
  Future<List<AvaliacaoModel>> listarTodas() async => dados.values.toList();
}

class FakePreferenceRepository implements PreferenceRepository {
  bool? temaEscuro;
  UsuarioModel? cache;

  @override
  Future<void> salvarTemaEscuro(bool isDark) async => temaEscuro = isDark;

  @override
  Future<bool?> obterTemaEscuro() async => temaEscuro;

  @override
  Future<void> salvarUsuarioEmCache(UsuarioModel usuario) async =>
      cache = usuario;

  @override
  Future<UsuarioModel?> obterUsuarioEmCache() async => cache;

  @override
  Future<void> limparSessao() async => cache = null;
}

/// Conjunto de repositórios falsos já interligados.
class FakeBackend {
  FakeBackend() {
    pessoas = FakePessoaRepository(avaliacoes: avaliacoes);
  }

  final auth = FakeAuthRepository();
  final avaliacoes = FakeAvaliacaoRepository();
  late final FakePessoaRepository pessoas;
  final preferencias = FakePreferenceRepository();
}

const usuarioAna = UsuarioModel(
  uid: 'uid_ana',
  nome: 'Ana Clara',
  email: 'ana@ifpr.edu.br',
  provider: 'password',
);

const usuarioJoao = UsuarioModel(
  uid: 'uid_joao',
  nome: 'João Pedro',
  email: 'joao@ifpr.edu.br',
  provider: 'password',
);

PessoaModel novaPessoa({
  String id = '',
  String nome = 'Maria Eduarda',
  String apelido = 'Duda',
  String curso = 'INFO',
  int turma = 2024,
  String criadoPor = 'uid_ana',
}) {
  return PessoaModel(
    id: id,
    nome: nome,
    apelido: apelido,
    curso: curso,
    turma: turma,
    dataNascimento: DateTime(2007, 5, 12),
    criadoPor: criadoPor,
  );
}

Map<String, int> notasIguais(int valor) => {
  for (final c in CriterioAvaliacao.values) c.id: valor,
};

/// Notas do exemplo do documento (João Pedro = 58 pontos).
const Map<String, int> notasExemploJoao = {
  'resenha': 4,
  'presencaVip': 3,
  'aura': 5,
  'modoParceiro': 4,
  'carismaNatural': 4,
  'humorDeMilhoes': 5,
  'energiaDeGrupo': 3,
  'criatividadeCaotica': 4,
  'modoAtleta': 5,
  'talentoDePalco': 2,
  'dripEscolar': 4,
  'coracaoDeDorama': 3,
  'queridinhoProfessores': 4,
  'cerebroTurbo': 5,
  'caosControlado': 3,
};

/// Monta notas cuja soma é exatamente [total] (entre 15 e 75).
Map<String, int> notasComTotal(int total) {
  final notas = notasIguais(1);
  var restante = total - CriterioAvaliacao.pontuacaoMinima;
  for (final c in CriterioAvaliacao.values) {
    final extra = restante.clamp(0, 4);
    notas[c.id] = 1 + extra;
    restante -= extra;
  }
  return notas;
}
