import 'package:signals_flutter/signals_flutter.dart';

import '../../core/command/command.dart';
import '../../core/result/result.dart';
import '../../domain/facades/avaliacao_facade.dart';
import '../../domain/models/avaliacao_model.dart';
import '../../domain/models/criterios_avaliacao.dart';
import 'base_viewmodel.dart';

class AvaliacaoViewModel extends BaseViewModel {
  AvaliacaoViewModel(this._avaliacaoFacade) {
    carregarAvaliacaoCommand = Command1<AvaliacaoModel?, String>(
      _carregarAvaliacao,
    );
    avaliarPessoaCommand = Command1<AvaliacaoModel, String>(_avaliarPessoa);
    carregarMinhasAvaliacoesCommand = Command0<List<AvaliacaoModel>>(
      _carregarMinhasAvaliacoes,
    );
  }

  static const int notaInicial = 3;

  final AvaliacaoFacade _avaliacaoFacade;

  final notas = signal<Map<String, int>>(criarNotasPadrao());
  late final pontuacaoTotal = computed(
    () => CriterioAvaliacao.calcularPontuacaoTotal(notas.value),
  );
  final avaliacaoExistente = signal<AvaliacaoModel?>(null);
  final isAutoavaliacao = signal<bool>(false);

  /// Avaliações do usuário autenticado indexadas pelo id da pessoa.
  final minhasAvaliacoes = signal<Map<String, AvaliacaoModel>>({});

  late final Command1<AvaliacaoModel?, String> carregarAvaliacaoCommand;
  late final Command1<AvaliacaoModel, String> avaliarPessoaCommand;
  late final Command0<List<AvaliacaoModel>> carregarMinhasAvaliacoesCommand;

  static Map<String, int> criarNotasPadrao([int valor = notaInicial]) {
    return {for (final c in CriterioAvaliacao.values) c.id: valor};
  }

  void definirNota(CriterioAvaliacao criterio, int nota) {
    if (!CriterioAvaliacao.isNotaValida(nota)) return;
    notas.value = {...notas.value, criterio.id: nota};
  }

  Future<Result<AvaliacaoModel?>> _carregarAvaliacao(String pessoaId) {
    notas.value = criarNotasPadrao();
    avaliacaoExistente.value = null;
    isAutoavaliacao.value = false;

    return executar(() async {
      final auto = await _avaliacaoFacade.verificarAutoavaliacao(pessoaId);
      if (auto case Failure(error: final erro)) return Failure(erro);
      isAutoavaliacao.value = auto.dataOrNull ?? false;
      if (isAutoavaliacao.value) return const Success(null);

      return _avaliacaoFacade.consultarAvaliacao(pessoaId);
    }, aoConcluir: _aplicarAvaliacao);
  }

  Future<Result<AvaliacaoModel>> _avaliarPessoa(String pessoaId) {
    final notasAtuais = Map<String, int>.from(notas.value);
    final jaAvaliou = avaliacaoExistente.value != null;

    return executar(
      () => jaAvaliou
          ? _avaliacaoFacade.alterarAvaliacao(
              pessoaId: pessoaId,
              notas: notasAtuais,
            )
          : _avaliacaoFacade.avaliar(pessoaId: pessoaId, notas: notasAtuais),
      aoConcluir: (avaliacao) {
        _aplicarAvaliacao(avaliacao);
        minhasAvaliacoes.value = {
          ...minhasAvaliacoes.value,
          pessoaId: avaliacao,
        };
      },
    );
  }

  Future<Result<List<AvaliacaoModel>>> _carregarMinhasAvaliacoes() {
    return executar(
      _avaliacaoFacade.carregarAvaliacoes,
      aoConcluir: (lista) =>
          minhasAvaliacoes.value = {for (final a in lista) a.pessoaId: a},
    );
  }

  void _aplicarAvaliacao(AvaliacaoModel? avaliacao) {
    avaliacaoExistente.value = avaliacao;
    if (avaliacao != null && avaliacao.notas.isNotEmpty) {
      notas.value = {...criarNotasPadrao(), ...avaliacao.notas};
    }
  }

  void limpar() {
    notas.value = criarNotasPadrao();
    avaliacaoExistente.value = null;
    isAutoavaliacao.value = false;
    minhasAvaliacoes.value = {};
  }
}
