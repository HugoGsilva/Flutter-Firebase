enum CriterioAvaliacao {
  resenha(
    id: 'resenha',
    nome: 'Resenha',
    descricao:
        'Mede o quanto o aluno anima a turma, puxa conversa e contribui para deixar o ambiente mais descontraído.',
  ),
  presencaVip(
    id: 'presenca_vip',
    nome: 'Presença VIP',
    descricao:
        'Avalia o quanto o aluno é lembrado, percebido ou reconhecido pelos colegas no dia a dia da turma.',
  ),
  aura(
    id: 'aura',
    nome: 'Aura',
    descricao:
        'Representa a energia geral do aluno: presença, estilo, postura e aquela vibe que chama a atenção sem esforço.',
  ),
  modoParceiro(
    id: 'modo_parceiro',
    nome: 'Modo Parceiro',
    descricao:
        'Mede o quanto o aluno ajuda os colegas, colabora nas atividades e demonstra espírito de parceria.',
  ),
  carismaNatural(
    id: 'carisma_natural',
    nome: 'Carisma Natural',
    descricao:
        'Avalia a facilidade do aluno para socializar, conversar e criar boas relações com os colegas.',
  ),
  humorDeMilhoes(
    id: 'humor_de_milhoes',
    nome: 'Humor de Milhões',
    descricao:
        'Representa o quanto o aluno contribui com bom humor, brincadeiras saudáveis e momentos divertidos.',
  ),
  energiaDeGrupo(
    id: 'energia_de_grupo',
    nome: 'Energia de Grupo',
    descricao:
        'Mede a participação do aluno em trabalhos, eventos, jogos, dinâmicas e atividades coletivas da turma.',
  ),
  criatividadeCaotica(
    id: 'criatividade_caotica',
    nome: 'Criatividade Caótica',
    descricao:
        'Avalia a capacidade do aluno de ter ideias diferentes, soluções inesperadas e comentários geniais.',
  ),
  modoAtleta(
    id: 'modo_atleta',
    nome: 'Modo Atleta',
    descricao:
        'Representa a aptidão esportiva, a disposição física e o espírito competitivo saudável do aluno.',
  ),
  talentoDePalco(
    id: 'talento_de_palco',
    nome: 'Talento de Palco',
    descricao:
        'Mede a aptidão artística do aluno, como música, canto, instrumentos, dança, ritmo ou presença em apresentações.',
  ),
  dripEscolar(
    id: 'drip_escolar',
    nome: 'Drip Escolar',
    descricao:
        'Avalia o estilo pessoal do aluno, considerando roupas, tênis, cabelo, acessórios e presença visual.',
  ),
  coracaoDeDorama(
    id: 'coracao_de_dorama',
    nome: 'Coração de Dorama',
    descricao:
        'Mede o lado emotivo, conselheiro, leal e intenso do aluno nas amizades e nos romances escolares.',
  ),
  queridinhoDosProfessores(
    id: 'queridinho_dos_professores',
    nome: 'Queridinho dos Professores',
    descricao:
        'Avalia a boa convivência com a equipe pedagógica, pontualidade, educação e respeito aos professores.',
  ),
  cerebroTurbo(
    id: 'cerebro_turbo',
    nome: 'Cérebro Turbo',
    descricao:
        'Avalia o desempenho nos estudos, a facilidade para aprender, resolver problemas e se destacar academicamente.',
  ),
  caosControlado(
    id: 'caos_controlado',
    nome: 'Caos Controlado',
    descricao:
        'Mede o quanto o aluno é bagunceiro, zoeiro ou imprevisível, mas ainda dentro dos limites do respeito e da convivência saudável.',
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
