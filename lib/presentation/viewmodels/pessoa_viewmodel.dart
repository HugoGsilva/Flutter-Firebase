import 'package:signals_flutter/signals_flutter.dart';

import '../../core/command/command.dart';
import '../../core/result/result.dart';
import '../../domain/facades/pessoa_facade.dart';
import '../../domain/models/pessoa_model.dart';
import 'base_viewmodel.dart';

class PessoaViewModel extends BaseViewModel {
  PessoaViewModel(this._pessoaFacade) {
    carregarPessoasCommand = Command0<List<PessoaModel>>(_carregarPessoas);
    buscarPessoaCommand = Command1<PessoaModel?, String>(_buscarPessoa);
    cadastrarPessoaCommand = Command1<PessoaModel, PessoaModel>(
      _cadastrarPessoa,
    );
    alterarPessoaCommand = Command1<PessoaModel, PessoaModel>(_alterarPessoa);
    removerPessoaCommand = Command2<void, String, bool>(_removerPessoa);
  }

  final PessoaFacade _pessoaFacade;

  final pessoas = signal<List<PessoaModel>>([]);
  final filtroCurso = signal<String?>(null);
  final buscaTexto = signal<String>('');

  late final pessoasFiltradas = computed(() {
    final curso = filtroCurso.value;
    final busca = buscaTexto.value.trim().toLowerCase();

    return pessoas.value.where((p) {
      final cursoOk = curso == null || p.curso == curso;
      final buscaOk =
          busca.isEmpty ||
          p.nome.toLowerCase().contains(busca) ||
          p.apelido.toLowerCase().contains(busca);
      return cursoOk && buscaOk;
    }).toList();
  });

  late final Command0<List<PessoaModel>> carregarPessoasCommand;
  late final Command1<PessoaModel?, String> buscarPessoaCommand;
  late final Command1<PessoaModel, PessoaModel> cadastrarPessoaCommand;
  late final Command1<PessoaModel, PessoaModel> alterarPessoaCommand;
  late final Command2<void, String, bool> removerPessoaCommand;

  PessoaModel? pessoaPorId(String id) {
    return pessoas.value.where((p) => p.id == id).firstOrNull;
  }

  Future<Result<List<PessoaModel>>> _carregarPessoas() {
    return executar(
      _pessoaFacade.listar,
      aoConcluir: (lista) => pessoas.value = lista,
    );
  }

  Future<Result<PessoaModel?>> _buscarPessoa(String id) {
    return executar(
      () => _pessoaFacade.buscar(id),
      aoConcluir: (pessoa) {
        if (pessoa != null) _substituirNaLista(pessoa);
      },
    );
  }

  Future<Result<PessoaModel>> _cadastrarPessoa(PessoaModel pessoa) {
    return executar(
      () => _pessoaFacade.cadastrar(pessoa),
      aoConcluir: (salva) =>
          pessoas.value = _ordenar([...pessoas.value, salva]),
    );
  }

  Future<Result<PessoaModel>> _alterarPessoa(PessoaModel pessoa) {
    return executar(
      () => _pessoaFacade.alterar(pessoa),
      aoConcluir: _substituirNaLista,
    );
  }

  Future<Result<void>> _removerPessoa(String pessoaId, bool confirmou) {
    return executar(
      () => _pessoaFacade.remover(pessoaId, confirmado: confirmou),
      aoConcluir: (_) =>
          pessoas.value = pessoas.value.where((p) => p.id != pessoaId).toList(),
    );
  }

  void _substituirNaLista(PessoaModel pessoa) {
    final semEla = pessoas.value.where((p) => p.id != pessoa.id);
    pessoas.value = _ordenar([...semEla, pessoa]);
  }

  List<PessoaModel> _ordenar(List<PessoaModel> lista) {
    return lista
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
  }

  void setFiltroCurso(String? curso) {
    filtroCurso.value = (curso == null || curso.isEmpty) ? null : curso;
  }

  void setBuscaTexto(String texto) => buscaTexto.value = texto;

  void limparFiltros() {
    filtroCurso.value = null;
    buscaTexto.value = '';
  }

  void limpar() {
    pessoas.value = [];
    limparFiltros();
  }
}
