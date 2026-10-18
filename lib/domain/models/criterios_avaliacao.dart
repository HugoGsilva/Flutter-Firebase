enum CriterioAvaliacao {
  resenha(
    id: 'resenha',
    nome: 'Resenha',
    descricao: 'Mede o quanto a pessoa anima a turma, puxa conversa e contribui para deixar o ambiente mais descontraído.',
  ),
  presencaVip(
    id: 'presencaVip',
    nome: 'Presença VIP',
    descricao: 'Avalia o quanto a pessoa é lembrada, percebida ou reconhecida pelos colegas no dia a dia.',
  ),
  aura(
    id: 'aura',
    nome: 'Aura',
    descricao: 'Representa a energia geral da pessoa: presença, estilo, jeito de ser e impacto que causa no ambiente.',
  ),
  modoParceiro(
    id: 'modoParceiro',
    nome: 'Modo Parceiro',
    descricao: 'Mede o quanto ajuda os colegas, colabora nas atividades e demonstra espírito de parceria.',
  ),
  carismaNatural(
    id: 'carismaNatural',
    nome: 'Carisma Natural',
    descricao:
        'Avalia a facilidade para socializar, conversar e criar boas relações.',
  ),
  humorDeMilhoes(
    id: 'humorDeMilhoes',
    nome: 'Humor de Milhões',
    descricao: 'Representa o quanto contribui com bom humor, brincadeiras saudáveis e momentos divertidos.',
  ),
  energiaDeGrupo(
    id: 'energiaDeGrupo',
    nome: 'Energia de Grupo',
    descricao: 'Mede a participação em trabalhos, eventos, jogos, dinâmicas e atividades coletivas.',
  ),
  criatividadeCaotica(
    id: 'criatividadeCaotica',
    nome: 'Criatividade Caótica',
    descricao: 'Avalia a capacidade de apresentar ideias diferentes, soluções inesperadas e comentários geniais.',
  ),
  modoAtleta(
    id: 'modoAtleta',
    nome: 'Modo Atleta',
    descricao: 'Representa aptidão esportiva, disposição física e espírito competitivo saudável.',
  ),
  talentoDePalco(
    id: 'talentoDePalco',
    nome: 'Talento de Palco',
    descricao: 'Mede aptidão artística, como música, canto, instrumentos, dança, ritmo ou presença em apresentações.',
  ),
  dripEscolar(
    id: 'dripEscolar',
    nome: 'Drip Escolar',
    descricao: 'Avalia o estilo pessoal, considerando roupas, tênis, cabelo, acessórios e presença visual.',
  ),
  coracaoDeDorama(
    id: 'coracaoDeDorama',
    nome: 'Coração de Dorama',
    descricao: 'Representa carisma afetivo, gentileza e aquela vibe de protagonista romântico, sem expor relacionamentos reais.',
  ),
  queridinhoProfessores(
    id: 'queridinhoProfessores',
    nome: 'Queridinho dos Professores',
    descricao: 'Mede a boa relação com os professores, considerando respeito, participação, educação e responsabilidade.',
  ),
  cerebroTurbo(
    id: 'cerebroTurbo',
    nome: 'Cérebro Turbo',
    descricao: 'Avalia o desempenho nos estudos, facilidade para aprender, resolver problemas e se destacar academicamente.',
  ),
  caosControlado(
    id: 'caosControlado',
    nome: 'Caos Controlado',
    descricao: 'Mede o quanto a pessoa é bagunceira, zoeira ou imprevisível, mas ainda dentro dos limites do respeito e da convivência saudável.',
  );

  const CriterioAvaliacao({
    required this.id,
    required this.nome,
    required this.descricao,
  });

  final String id;
  final String nome;
  final String descricao;

  static const int notaMinima = 1;
  static const int notaMaxima = 5;
  static const int pontuacaoMinima = 15;
  static const int pontuacaoMaxima = 75;

  static bool isNotaValida(int nota) =>
      nota >= notaMinima && nota <= notaMaxima;

  static bool validarNotas(Map<String, int> notas) {
    if (notas.length != CriterioAvaliacao.values.length) {
      return false;
    }
    for (final criterio in CriterioAvaliacao.values) {
      final nota = notas[criterio.id];
      if (nota == null || !isNotaValida(nota)) {
        return false;
      }
    }
    return true;
  }

  static int calcularPontuacaoTotal(Map<String, int> notas) {
    return notas.values.fold(0, (total, nota) => total + nota);
  }
}
