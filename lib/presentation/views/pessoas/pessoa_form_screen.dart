import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/di/injection.dart';
import '../../../core/result/result.dart';
import '../../../domain/models/pessoa_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/pessoa_viewmodel.dart';

class PessoaFormScreen extends StatefulWidget {
  const PessoaFormScreen({super.key, this.pessoaParaEditar});

  final PessoaModel? pessoaParaEditar;

  @override
  State<PessoaFormScreen> createState() => _PessoaFormScreenState();
}

class _PessoaFormScreenState extends State<PessoaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _apelidoController = TextEditingController();
  final _dataNascimentoController = TextEditingController();

  String? _cursoSelecionado;
  int? _turmaSelecionada;
  DateTime? _dataNascimentoSelecionada;

  late final PessoaViewModel _pessoaViewModel;
  late final AuthViewModel _authViewModel;

  bool get _isEditing => widget.pessoaParaEditar != null;

  static const List<String> _cursos = PessoaModel.cursosValidos;
  static final List<int> _anos = List.generate(
    PessoaModel.turmaAnoMaximo - PessoaModel.turmaAnoMinimo + 1,
    (index) => PessoaModel.turmaAnoMaximo - index,
  );

  @override
  void initState() {
    super.initState();
    _pessoaViewModel = sl<PessoaViewModel>();
    _authViewModel = sl<AuthViewModel>();

    if (_isEditing) {
      final p = widget.pessoaParaEditar!;
      _nomeController.text = p.nome;
      _apelidoController.text = p.apelido;
      _cursoSelecionado = p.curso.toUpperCase();
      _turmaSelecionada = p.turma;
      _dataNascimentoSelecionada = p.dataNascimento;
      _dataNascimentoController.text = DateFormat('dd/MM/yyyy')
          .format(p.dataNascimento);
    } else {
      _cursoSelecionado = _cursos.first;
      _turmaSelecionada = DateTime.now().year.clamp(
        PessoaModel.turmaAnoMinimo,
        PessoaModel.turmaAnoMaximo,
      );
      _dataNascimentoSelecionada = DateTime(2005, 1, 1);
      _dataNascimentoController.text = DateFormat('dd/MM/yyyy')
          .format(_dataNascimentoSelecionada!);
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _apelidoController.dispose();
    _dataNascimentoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarDataNascimento() async {
    final DateTime initial = _dataNascimentoSelecionada ?? DateTime(2005, 1, 1);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950, 1, 1),
      lastDate: DateTime.now(),
      helpText: 'Selecione a data de nascimento',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );

    if (picked != null) {
      setState(() {
        _dataNascimentoSelecionada = picked;
        _dataNascimentoController.text = DateFormat('dd/MM/yyyy')
            .format(picked);
      });
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final currentUid = _authViewModel.currentUser.value?.uid ?? '';
    final nome = _nomeController.text.trim();
    final apelido = _apelidoController.text.trim();
    final curso = _cursoSelecionado ?? _cursos.first;
    final turma = _turmaSelecionada ?? 2026;
    final dataNasc = _dataNascimentoSelecionada ?? DateTime(2000, 1, 1);

    final PessoaModel pessoa;
    if (_isEditing) {
      pessoa = widget.pessoaParaEditar!.copyWith(
        nome: nome,
        apelido: apelido,
        curso: curso,
        turma: turma,
        dataNascimento: dataNasc,
      );
    } else {
      final novoId = 'pes_${DateTime.now().millisecondsSinceEpoch}';
      pessoa = PessoaModel(
        id: novoId,
        nome: nome,
        apelido: apelido,
        curso: curso,
        turma: turma,
        dataNascimento: dataNasc,
        criadoPor: currentUid,
      );
    }

    final result = _isEditing
        ? await _pessoaViewModel.alterarPessoaCommand(pessoa)
        : await _pessoaViewModel.cadastrarPessoaCommand(pessoa);

    if (!mounted) return;

    if (result case Success()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Dados de $apelido atualizados com sucesso!'
                : '$nome cadastrado com sucesso!',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      try {
        context.pop();
      } catch (_) {
        Navigator.of(context).maybePop();
      }
    } else if (result case Failure()) {
      final msg =
          _pessoaViewModel.errorMessage.value ??
          'Erro ao salvar cadastro da pessoa.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _pessoaViewModel.limparErro();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Pessoa' : 'Cadastrar Pessoa'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: SignalBuilder(
                  builder: (context) {
                    final loading = _pessoaViewModel.isLoading.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _nomeController,
                          enabled: !loading,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Nome completo',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Informe o nome completo';
                            }
                            if (value.trim().length < 2) {
                              return 'O nome deve ter no mínimo 2 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _apelidoController,
                          enabled: !loading,
                          decoration: const InputDecoration(
                            labelText: 'Apelido ou Como é conhecido',
                            hintText: 'Ex: Batata, Zé, Biologia...',
                            prefixIcon: Icon(Icons.alternate_email),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Informe um apelido ou forma como é conhecido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _cursoSelecionado,
                          decoration: const InputDecoration(
                            labelText: 'Curso',
                            prefixIcon: Icon(Icons.school_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: _cursos.map((c) {
                            return DropdownMenuItem<String>(
                              value: c,
                              child: Text(c),
                            );
                          }).toList(),
                          onChanged: loading
                              ? null
                              : (val) {
                                  if (val != null) {
                                    setState(() => _cursoSelecionado = val);
                                  }
                                },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Selecione o curso';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          initialValue: _turmaSelecionada,
                          decoration: const InputDecoration(
                            labelText: 'Turma / Ano',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: _anos.map((ano) {
                            return DropdownMenuItem<int>(
                              value: ano,
                              child: Text(ano.toString()),
                            );
                          }).toList(),
                          onChanged: loading
                              ? null
                              : (val) {
                                  if (val != null) {
                                    setState(() => _turmaSelecionada = val);
                                  }
                                },
                          validator: (value) {
                            if (value == null) {
                              return 'Selecione a turma/ano';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _dataNascimentoController,
                          readOnly: true,
                          enabled: !loading,
                          decoration: InputDecoration(
                            labelText: 'Data de nascimento',
                            hintText: 'dd/MM/yyyy',
                            prefixIcon: const Icon(Icons.cake_outlined),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.date_range_outlined),
                              onPressed: loading
                                  ? null
                                  : _selecionarDataNascimento,
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          onTap: loading ? null : _selecionarDataNascimento,
                          validator: (value) {
                            if (_dataNascimentoSelecionada == null) {
                              return 'Informe a data de nascimento';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),
                        FilledButton.icon(
                          onPressed: loading ? null : _salvar,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            _isEditing ? 'Atualizar Dados' : 'Salvar Cadastro',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
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
