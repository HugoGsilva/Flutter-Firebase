import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../../core/di/injection.dart';
import '../../../domain/models/pessoa_model.dart';
import '../../viewmodels/pessoa_viewmodel.dart';

class PessoasListView extends StatefulWidget {
  const PessoasListView({super.key});

  @override
  State<PessoasListView> createState() => _PessoasListViewState();
}

class _PessoasListViewState extends State<PessoasListView> {
  final _searchController = TextEditingController();
  PessoaViewModel? _pessoaViewModel;

  static const List<String> _cursosFiltro = [
    'Todos',
    ...PessoaModel.cursosValidos,
  ];

  @override
  void initState() {
    super.initState();
    if (sl.isRegistered<PessoaViewModel>()) {
      _pessoaViewModel = sl<PessoaViewModel>();
      _searchController.text = _pessoaViewModel!.buscaTexto.value;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pessoaViewModel?.carregarPessoasCommand();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_pessoaViewModel == null) {
      return const Center(child: Text('Carregando pessoas...'));
    }

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
                          _pessoaViewModel?.setBuscaTexto('');
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                _pessoaViewModel?.setBuscaTexto(value);
                setState(() {});
              },
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _cursosFiltro.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final curso = _cursosFiltro[index];
                return SignalBuilder(
                  builder: (context) {
                    final filtroAtivo = _pessoaViewModel!.filtroCurso.value;
                    final isSelected = curso == 'Todos'
                        ? (filtroAtivo == null || filtroAtivo.isEmpty)
                        : filtroAtivo == curso;

                    return FilterChip(
                      selected: isSelected,
                      label: Text(curso),
                      onSelected: (_) {
                        if (curso == 'Todos') {
                          _pessoaViewModel?.setFiltroCurso(null);
                        } else {
                          _pessoaViewModel?.setFiltroCurso(
                            isSelected ? null : curso,
                          );
                        }
                      },
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
                final isLoading = _pessoaViewModel!.isLoading.value;
                final lista = _pessoaViewModel!.pessoasFiltradas.value;

                if (isLoading && lista.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (lista.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      await _pessoaViewModel?.carregarPessoasCommand();
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: colorScheme.outline,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Nenhuma pessoa encontrada',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Cadastre uma nova pessoa no botão "+" abaixo.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await _pessoaViewModel?.carregarPessoasCommand();
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: lista.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final pessoa = lista[index];
                      return _buildPessoaCard(context, pessoa);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/pessoas/novo'),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Nova Pessoa'),
      ),
    );
  }

  Widget _buildPessoaCard(BuildContext context, PessoaModel pessoa) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(
          '/pessoas/detalhes/${pessoa.id}',
          extra: pessoa,
        ),
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
                    Text(
                      pessoa.nome,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (pessoa.apelido.isNotEmpty)
                      Text(
                        '@${pessoa.apelido}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            pessoa.curso,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
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
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
