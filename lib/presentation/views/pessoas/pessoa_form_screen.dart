import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/di/injection.dart';
import '../../../core/result/result.dart';
import '../../../domain/models/pessoa_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/pessoa_viewmodel.dart';
import '../widgets/feedback.dart';

class PessoaFormScreen extends StatefulWidget {
  const PessoaFormScreen({super.key, this.pessoaId, this.pessoaParaEditar});

  /// Quando informado, a tela abre em modo de edição.
  final String? pessoaId;
  final PessoaModel? pessoaParaEditar;

  @override
  State<PessoaFormScreen> createState() => _PessoaFormScreenState();
}

class _PessoaFormScreenState extends State<PessoaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _apelidoController = TextEditingController();
  final _dataNascimentoController = TextEditingController();
  final _formatoData = DateFormat('dd/MM/yyyy');

  final _pessoaViewModel = sl<PessoaViewModel>();
  final _authViewModel = sl<AuthViewModel>();

  String _cursoSelecionado = PessoaModel.cursosValidos.first;
  int _turmaSelecionada = PessoaModel.turmaAnoMaximo;
  DateTime? _dataNascimento;
  bool _souEu = false;

  PessoaModel? _original;
  bool _carregando = false;

  String? get _idEdicao => widget.pessoaId ?? widget.pessoaParaEditar?.id;
  bool get _isEditing => _idEdicao != null;

  static final List<int> _anos = [
    for (
      var ano = PessoaModel.turmaAnoMaximo;
      ano >= PessoaModel.turmaAnoMinimo;
      ano--
    )
      ano,
  ];

  @override
  void initState() {
    super.initState();
    final id = _idEdicao;
    if (id == null) return;

    final conhecida =
        widget.pessoaParaEditar ?? _pessoaViewModel.pessoaPorId(id);
    if (conhecida != null) {
      _preencher(conhecida);
    } else {
      _carregando = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _buscar(id));
    }
  }

  Future<void> _buscar(String id) async {
    final result = await _pessoaViewModel.buscarPessoaCommand(id);
    if (!mounted) return;
    setState(() => _carregando = false);
    if (result case Success(data: final pessoa?)) {
      setState(() => _preencher(pessoa));
    } else {
      mostrarErro(context, 'Pessoa não encontrada.');
      context.pop();
    }
  }

  void _preencher(PessoaModel p) {
    _original = p;
    _nomeController.text = p.nome;
    _apelidoController.text = p.apelido;
    _cursoSelecionado = PessoaModel.isCursoValido(p.curso)
        ? p.curso.toUpperCase()
        : PessoaModel.cursosValidos.first;
    _turmaSelecionada = PessoaModel.isTurmaValida(p.turma)
        ? p.turma
        : PessoaModel.turmaAnoMaximo;
    _dataNascimento = p.dataNascimento;
    _dataNascimentoController.text = _formatoData.format(p.dataNascimento);
    _souEu = _authViewModel.currentUser.value?.pessoaId == p.id;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _apelidoController.dispose();
    _dataNascimentoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarDataNascimento() async {
    final hoje = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataNascimento ?? DateTime(hoje.year - 16),
      firstDate: DateTime(1940),
      lastDate: hoje,
      helpText: 'Selecione a data de nascimento',
    );

    if (picked != null) {
      setState(() {
        _dataNascimento = picked;
        _dataNascimentoController.text = _formatoData.format(picked);
      });
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final dados = PessoaModel(
      id: _original?.id ?? '',
      nome: _nomeController.text,
      apelido: _apelidoController.text,
      curso: _cursoSelecionado,
      turma: _turmaSelecionada,
      dataNascimento: _dataNascimento!,
      criadoPor: _original?.criadoPor ?? '',
    );

    final result = _isEditing
        ? await _pessoaViewModel.alterarPessoaCommand(dados)
        : await _pessoaViewModel.cadastrarPessoaCommand(dados);
    if (!mounted) return;

    final salva = result.dataOrNull;
    if (salva == null) {
      mostrarErro(
        context,
        _pessoaViewModel.errorMessage.value ?? 'Erro ao salvar o cadastro.',
      );
      _pessoaViewModel.limparErro();
      return;
    }

    final vinculoAtual = _authViewModel.currentUser.value?.pessoaId;
    final eraEu = vinculoAtual == salva.id;
    if (_souEu != eraEu) {
      final vinculo = await _authViewModel.vincularPessoaCommand(
        _souEu ? salva.id : null,
      );
      if (!mounted) return;
      if (vinculo case Failure()) {
        mostrarErro(
          context,
          _authViewModel.errorMessage.value ??
              'Não foi possível vincular a pessoa à sua conta.',
        );
        _authViewModel.limparErro();
      }
    }

    mostrarSucesso(
      context,
      _isEditing
          ? 'Dados de ${salva.nome} atualizados!'
          : '${salva.nome} cadastrado(a) com sucesso!',
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vinculoAtual = _authViewModel.currentUser.value?.pessoaId;
    final podeMarcarSouEu =
        vinculoAtual == null || vinculoAtual == _original?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Pessoa' : 'Cadastrar Pessoa'),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Form(
                      key: _formKey,
                      child: SignalBuilder(
                        builder: (context) {
                          final loading =
                              _pessoaViewModel.isLoading.value ||
                              _authViewModel.isLoading.value;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                key: const Key('pessoa_nome'),
                                controller: _nomeController,
                                enabled: !loading,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Nome completo',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (value) {
                                  if ((value?.trim().length ?? 0) < 2) {
                                    return 'Informe o nome (mínimo 2 caracteres)';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                key: const Key('pessoa_apelido'),
                                controller: _apelidoController,
                                enabled: !loading,
                                decoration: const InputDecoration(
                                  labelText: 'Apelido',
                                  hintText: 'Como a pessoa é conhecida',
                                  prefixIcon: Icon(Icons.alternate_email),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Informe o apelido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                key: const Key('pessoa_curso'),
                                initialValue: _cursoSelecionado,
                                decoration: const InputDecoration(
                                  labelText: 'Curso',
                                  prefixIcon: Icon(Icons.school_outlined),
                                ),
                                items: [
                                  for (final c in PessoaModel.cursosValidos)
                                    DropdownMenuItem(value: c, child: Text(c)),
                                ],
                                onChanged: loading
                                    ? null
                                    : (val) => setState(
                                        () => _cursoSelecionado = val!,
                                      ),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<int>(
                                key: const Key('pessoa_turma'),
                                initialValue: _turmaSelecionada,
                                menuMaxHeight: 320,
                                decoration: const InputDecoration(
                                  labelText: 'Turma / Ano',
                                  prefixIcon: Icon(
                                    Icons.calendar_today_outlined,
                                  ),
                                ),
                                items: [
                                  for (final ano in _anos)
                                    DropdownMenuItem(
                                      value: ano,
                                      child: Text('$ano'),
                                    ),
                                ],
                                onChanged: loading
                                    ? null
                                    : (val) => setState(
                                        () => _turmaSelecionada = val!,
                                      ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                key: const Key('pessoa_nascimento'),
                                controller: _dataNascimentoController,
                                readOnly: true,
                                enabled: !loading,
                                decoration: const InputDecoration(
                                  labelText: 'Data de nascimento',
                                  hintText: 'dd/mm/aaaa',
                                  prefixIcon: Icon(Icons.cake_outlined),
                                  suffixIcon: Icon(Icons.date_range_outlined),
                                ),
                                onTap: loading
                                    ? null
                                    : _selecionarDataNascimento,
                                validator: (_) => _dataNascimento == null
                                    ? 'Selecione a data de nascimento'
                                    : null,
                              ),
                              const SizedBox(height: 8),
                              CheckboxListTile(
                                key: const Key('pessoa_sou_eu'),
                                value: _souEu,
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: const Text('Esta pessoa sou eu'),
                                subtitle: Text(
                                  podeMarcarSouEu
                                      ? 'Vincula o cadastro à sua conta. Você não poderá se autoavaliar.'
                                      : 'Sua conta já está vinculada a outra pessoa.',
                                  style: theme.textTheme.bodySmall,
                                ),
                                onChanged: loading || !podeMarcarSouEu
                                    ? null
                                    : (v) => setState(() => _souEu = v!),
                              ),
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                onPressed: loading ? null : _salvar,
                                icon: loading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.save_outlined),
                                label: Text(
                                  _isEditing
                                      ? 'Atualizar Dados'
                                      : 'Salvar Cadastro',
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
