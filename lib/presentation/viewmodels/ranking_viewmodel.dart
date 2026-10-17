import 'package:flutter/foundation.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../core/command/command.dart';
import '../../core/result/result.dart';
import '../../domain/facades/auth_facade.dart';
import '../../domain/facades/ranking_facade.dart';
import '../../domain/models/ranking_item_model.dart';

class RankingViewModel extends ChangeNotifier {
  RankingViewModel(this._rankingFacade, {this.authFacade}) {
    rankingPessoal = signal<List<RankingItemModel>>([]);
    rankingGlobal = signal<List<RankingItemModel>>([]);
    isLoading = signal<bool>(false);
    errorMessage = signal<String?>(null);

    carregarRankingPessoalCommand =
        CommandOptional1<List<RankingItemModel>, String>(
          _carregarRankingPessoal,
        );
    carregarRankingGlobalCommand = Command0<List<RankingItemModel>>(
      _carregarRankingGlobal,
    );
  }

  final RankingFacade _rankingFacade;
  final AuthFacade? authFacade;
  String? _usuarioUidOverride;

  late final Signal<List<RankingItemModel>> rankingPessoal;
  late final Signal<List<RankingItemModel>> rankingGlobal;
  late final Signal<bool> isLoading;
  late final Signal<String?> errorMessage;

  late final CommandOptional1<List<RankingItemModel>, String>
  carregarRankingPessoalCommand;
  late final Command0<List<RankingItemModel>> carregarRankingGlobalCommand;

  void setUsuarioUid(String? uid) {
    _usuarioUidOverride = uid;
  }

  Future<Result<List<RankingItemModel>>> _carregarRankingPessoal([
    String? avaliadorUid,
  ]) async {
    final uid =
        avaliadorUid ??
        _usuarioUidOverride ??
        authFacade?.verificarAutenticado().dataOrNull?.uid;

    if (uid == null || uid.isEmpty) {
      const falha = Failure<List<RankingItemModel>>(
        FormatException(
          'Identificador do usuário não encontrado para o ranking pessoal.',
        ),
      );
      errorMessage.value = 'Identificador do usuário não encontrado.';
      return falha;
    }

    isLoading.value = true;
    errorMessage.value = null;
    notifyListeners();
    try {
      final res = await _rankingFacade.obterRankingPessoal(uid);
      if (res case Success(data: final itens)) {
        rankingPessoal.value = itens;
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

  Future<Result<List<RankingItemModel>>> _carregarRankingGlobal() async {
    isLoading.value = true;
    errorMessage.value = null;
    notifyListeners();
    try {
      final res = await _rankingFacade.obterRankingGlobal();
      if (res case Success(data: final itens)) {
        rankingGlobal.value = itens;
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
