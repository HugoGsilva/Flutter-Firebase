import 'package:flutter/foundation.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../core/command/command.dart';
import '../../core/result/result.dart';
import '../../domain/facades/avaliacao_facade.dart';
import '../../domain/models/avaliacao_model.dart';
import '../../domain/models/criterios_avaliacao.dart';

class AvaliacaoViewModel extends ChangeNotifier {
  AvaliacaoViewModel(this._avaliacaoFacade) {
    notas = signal<Map<String, int>>(criarNotasPadrao(3));
    pontuacaoTotal = computed(() {
      return CriterioAvaliacao.calcularPontuacaoTotal(notas.value);
    });
    avaliacaoExistente = signal<AvaliacaoModel?>(null);
    isLoading = signal<bool>(false);
    errorMessage = signal<String?>(null);

    carregarAvaliacaoCommand =
        Command2<AvaliacaoModel?, String, String>(_carregarAvaliacao);
    salvarAvaliacaoCommand =
        Command3<void, String, String, String?>(_salvarAvaliacao);
  }

  final AvaliacaoFacade _avaliacaoFacade;

  late final Signal<Map<String, int>> notas;
  late final Computed<int> pontuacaoTotal;
  late final Signal<AvaliacaoModel?> avaliacaoExistente;
  late final Signal<bool> isLoading;
  late final Signal<String?> errorMessage;

  late final Command2<AvaliacaoModel?, String, String> carregarAvaliacaoCommand;
  late final Command3<void, String, String, String?> salvarAvaliacaoCommand;

  static Map<String, int> criarNotasPadrao([int valorPadrao = 3]) {
    return {
      for (final criterio in CriterioAvaliacao.values) criterio.id: valorPadrao,
    };
  }

  void definirNota(dynamic criterio, int nota) {
    final String id = criterio is CriterioAvaliacao ? criterio.id : criterio.toString();
    final novoMapa = Map<String, int>.from(notas.value);
    novoMapa[id] = nota;
    notas.value = novoMapa;
    notifyListeners();
  }

  void resetarNotas([int valorPadrao = 3]) {
    notas.value = criarNotasPadrao(valorPadrao);
    avaliacaoExistente.value = null;
    errorMessage.value = null;
    notifyListeners();
  }

  Future<Result<AvaliacaoModel?>> _carregarAvaliacao(
    String pessoaId,
    String usuarioUid,
  ) async {
    isLoading.value = true;
    errorMessage.value = null;
    notifyListeners();
    try {
      final res = await _avaliacaoFacade.buscarAvaliacao(
        avaliadorUid: usuarioUid,
        pessoaId: pessoaId,
      );
      if (res case Success(data: final avaliacao)) {
        avaliacaoExistente.value = avaliacao;
        if (avaliacao != null) {
          notas.value = Map<String, int>.from(avaliacao.notas);
        } else {
          notas.value = criarNotasPadrao(3);
        }
        errorMessage.value = null;
      } else if (res case Failure(error: final err)) {
        errorMessage.value = _formatError(err);
      }
      return res;
    } finally {
      isLoading.value = false;
      notifyListeners();
    }
  }

  Future<Result<void>> _salvarAvaliacao(
    String pessoaId,
    String usuarioUid,
    String? criadoPor,
  ) async {
    isLoading.value = true;
    errorMessage.value = null;
    notifyListeners();
    try {
      final novaAvaliacao = AvaliacaoModel(
        id: AvaliacaoModel.gerarIdCanonico(usuarioUid, pessoaId),
        avaliadorUid: usuarioUid,
        pessoaId: pessoaId,
        notas: Map<String, int>.from(notas.value),
        pontuacaoTotal: pontuacaoTotal.value,
        dataAvaliacao: DateTime.now(),
      );

      final res = await _avaliacaoFacade.salvarAvaliacao(
        novaAvaliacao,
        pessoaCriadorUid: criadoPor,
      );

      if (res case Success()) {
        avaliacaoExistente.value = novaAvaliacao;
        errorMessage.value = null;
      } else if (res case Failure(error: final err)) {
        errorMessage.value = _formatError(err);
      }
      return res;
    } finally {
      isLoading.value = false;
      notifyListeners();
    }
  }

  void limparErro() {
    errorMessage.value = null;
  }

  String _formatError(Exception e) {
    final msg = e.toString();
    if (msg.startsWith('Exception: ')) {
      return msg.substring(11);
    }
    return msg;
  }
}
