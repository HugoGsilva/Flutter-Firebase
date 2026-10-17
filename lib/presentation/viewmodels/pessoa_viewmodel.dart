import 'package:flutter/foundation.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../core/command/command.dart';
import '../../core/result/result.dart';
import '../../domain/facades/pessoa_facade.dart';
import '../../domain/models/pessoa_model.dart';

class PessoaViewModel extends ChangeNotifier {
  PessoaViewModel(this._pessoaFacade) {
    pessoas = signal<List<PessoaModel>>([]);
    filtroCurso = signal<String?>(null);
    buscaTexto = signal<String>('');
    isLoading = signal<bool>(false);
    errorMessage = signal<String?>(null);

    pessoasFiltradas = computed(() {
      final lista = pessoas.value;
      final curso = filtroCurso.value;
      final busca = buscaTexto.value.trim().toLowerCase();

      return lista.where((p) {
        final matchCurso =
            curso == null ||
            curso.isEmpty ||
            p.curso.toUpperCase() == curso.toUpperCase();
        final matchBusca =
            busca.isEmpty ||
            p.nome.toLowerCase().contains(busca) ||
            p.apelido.toLowerCase().contains(busca);
        return matchCurso && matchBusca;
      }).toList();
    });

    carregarPessoasCommand = Command0<List<PessoaModel>>(_carregarPessoas);
    cadastrarPessoaCommand = Command1<void, PessoaModel>(_cadastrarPessoa);
    alterarPessoaCommand = Command1<void, PessoaModel>(_alterarPessoa);
    removerPessoaCommand = Command2<void, String, bool>(_removerPessoa);
  }

  final PessoaFacade _pessoaFacade;

  late final Signal<List<PessoaModel>> pessoas;
  late final Signal<String?> filtroCurso;
  late final Signal<String> buscaTexto;
  late final Signal<bool> isLoading;
  late final Signal<String?> errorMessage;
  late final Computed<List<PessoaModel>> pessoasFiltradas;

  late final Command0<List<PessoaModel>> carregarPessoasCommand;
  late final Command1<void, PessoaModel> cadastrarPessoaCommand;
  late final Command1<void, PessoaModel> alterarPessoaCommand;
  late final Command2<void, String, bool> removerPessoaCommand;

  Future<Result<List<PessoaModel>>> _carregarPessoas() async {
    isLoading.value = true;
    errorMessage.value = null;
    notifyListeners();
    try {
      final res = await _pessoaFacade.listarTodas();
      if (res case Success(data: final lista)) {
        pessoas.value = lista;
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

  Future<Result<void>> _cadastrarPessoa(PessoaModel pessoa) async {
    isLoading.value = true;
    errorMessage.value = null;
    notifyListeners();
    try {
      final res = await _pessoaFacade.cadastrar(pessoa);
      if (res case Success()) {
        errorMessage.value = null;
        await _carregarPessoas();
      } else if (res case Failure(error: final err)) {
        errorMessage.value = _formatError(err);
      }
      return res;
    } finally {
      isLoading.value = false;
      notifyListeners();
    }
  }

  Future<Result<void>> _alterarPessoa(PessoaModel pessoa) async {
    isLoading.value = true;
    errorMessage.value = null;
    notifyListeners();
    try {
      final res = await _pessoaFacade.atualizar(pessoa);
      if (res case Success()) {
        errorMessage.value = null;
        await _carregarPessoas();
      } else if (res case Failure(error: final err)) {
        errorMessage.value = _formatError(err);
      }
      return res;
    } finally {
      isLoading.value = false;
      notifyListeners();
    }
  }

  Future<Result<void>> _removerPessoa(String pessoaId, bool confirmou) async {
    isLoading.value = true;
    errorMessage.value = null;
    notifyListeners();
    try {
      final res = await _pessoaFacade.remover(pessoaId, confirmado: confirmou);
      if (res case Success()) {
        errorMessage.value = null;
        await _carregarPessoas();
      } else if (res case Failure(error: final err)) {
        errorMessage.value = _formatError(err);
      }
      return res;
    } finally {
      isLoading.value = false;
      notifyListeners();
    }
  }

  void setFiltroCurso(String? curso) {
    filtroCurso.value = (curso == null || curso.isEmpty) ? null : curso;
    notifyListeners();
  }

  void setBuscaTexto(String texto) {
    buscaTexto.value = texto;
    notifyListeners();
  }

  void limparFiltros() {
    filtroCurso.value = null;
    buscaTexto.value = '';
    notifyListeners();
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
