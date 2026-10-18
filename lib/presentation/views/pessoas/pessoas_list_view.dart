import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/di/injection.dart';
import '../../../core/router/app_router.dart';
import '../../../domain/models/pessoa_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/avaliacao_viewmodel.dart';
import '../../viewmodels/pessoa_viewmodel.dart';
import '../widgets/feedback.dart';

class PessoasListView extends StatefulWidget {
  const PessoasListView({super.key});

  @override
  State<PessoasListView> createState() => _PessoasListViewState();
}

class _PessoasListViewState extends State<PessoasListView> {
  final _searchController = TextEditingController();
  final _pessoaViewModel = sl<PessoaViewModel>();
  final _avaliacaoViewModel = sl<AvaliacaoViewModel>();
  final _authViewModel = sl<AuthViewModel>();

  static const List<String> _cursosFiltro = [
    'Todos',
    ...PessoaModel.cursosValidos,
  ];

  @override
  void initState() {
    super.initState();
    _searchController.text = _pessoaViewModel.buscaTexto.value;
    WidgetsBinding.instance.addPostFrameCallback((_) => _recarregar());
  }

  Future<void> _recarregar() async {
    await Future.wait([
      _pessoaViewModel.carregarPessoasCommand(),
      _avaliacaoViewModel.carregarMinhasAvaliacoesCommand(),
    ]);
    final erro = _pessoaViewModel.errorMessage.value;
    if (erro != null && mounted) {
      mostrarErro(context, erro);
      _pessoaViewModel.limparErro();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nome ou apelido...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _pessoaViewModel.setBuscaTexto('');
                          setState(() {});
                        },
                      )
                    : null,
                fillColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                _pessoaViewModel.setBuscaTexto(value);
                setState(() {});
              },
            ),
          ),
          SizedBox(
            height: 48,
            child: SignalBuilder(
              builder: (context) {
                final filtroAtivo = _pessoaViewModel.filtroCurso.value;
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _cursosFiltro.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final curso = _cursosFiltro[index];
                    final todos = curso == 'Todos';
                    final selecionado = todos
                        ? filtroAtivo == null
                        : filtroAtivo == curso;

                    return FilterChip(
                      selected: selecionado,
                      label: Text(curso),
                      onSelected: (_) => _pessoaViewModel.setFiltroCurso(
                        todos || selecionado ? null : curso,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: SignalBuilder(
              builder: (context) {
                final carregando =
                    _pessoaViewModel.carregarPessoasCommand.runningSignal.value;
                final lista = _pessoaViewModel.pessoasFiltradas.value;
                final notas = _avaliacaoViewModel.minhasAvaliacoes.value;
                final minhaPessoaId =
                    _authViewModel.currentUser.value?.pessoaId;

                if (carregando && lista.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                return RefreshIndicator(
                  onRefresh: _recarregar,
                  child: lista.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 60),
                            EstadoVazio(
                              icone: Icons.people_outline,
                              titulo: 'Nenhuma pessoa encontrada',
                              mensagem: 'Cadastre uma nova pessoa no botão "Nova Pessoa".',
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                          itemCount: lista.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final pessoa = lista[index];
                            return _PessoaCard(
                              pessoa: pessoa,
                              minhaNota: notas[pessoa.id]?.pontuacaoTotal,
                              souEu: pessoa.id == minhaPessoaId,
                            );
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'nova_pessoa',
        onPressed: () async {
          await context.push(AppRoutes.novaPessoa);
          _avaliacaoViewModel.carregarMinhasAvaliacoesCommand();
        },
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Nova Pessoa'),
      ),
    );
  }
}

class _PessoaCard extends StatelessWidget {
  const _PessoaCard({
    required this.pessoa,
    required this.minhaNota,
    required this.souEu,
  });

  final PessoaModel pessoa;
  final int? minhaNota;
  final bool souEu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.detalhes(pessoa.id), extra: pessoa),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  pessoa.nome.isNotEmpty ? pessoa.nome[0].toUpperCase() : '?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            pessoa.nome,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (souEu) ...[
                          const SizedBox(width: 6),
                          _Etiqueta(
                            texto: 'Você',
                            fundo: colorScheme.tertiaryContainer,
                            cor: colorScheme.onTertiaryContainer,
                          ),
                        ],
                      ],
                    ),
                    if (pessoa.apelido.isNotEmpty)
                      Text(
                        '"${pessoa.apelido}"',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _Etiqueta(
                          texto: pessoa.curso,
                          fundo: colorScheme.secondaryContainer,
                          cor: colorScheme.onSecondaryContainer,
                        ),
                        Text(
                          'Turma ${pessoa.turma}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (minhaNota != null)
                Column(
                  children: [
                    Text(
                      '$minhaNota',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text('Nível Lenda', style: theme.textTheme.labelSmall),
                  ],
                )
              else
                Icon(Icons.chevron_right, color: colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({
    required this.texto,
    required this.fundo,
    required this.cor,
  });

  final String texto;
  final Color fundo;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: cor, fontWeight: FontWeight.bold),
      ),
    );
  }
}
