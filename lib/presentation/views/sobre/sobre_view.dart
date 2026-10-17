import 'package:flutter/material.dart';

import '../../../domain/models/criterios_avaliacao.dart';

class SobreView extends StatelessWidget {
  const SobreView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.military_tech_rounded,
                      size: 52,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'PiramidGame IFPR-Pgua',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'IFPR – Campus Paranaguá',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Versão 1.0.0 • Dispositivos Móveis',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              color: colorScheme.primaryContainer.withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.format_quote_rounded,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Apresentação Oficial',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'O PiramidGame IFPR-Pgua é um aplicativo desenvolvido em Flutter para fins didáticos. Ele permite cadastrar pessoas do IFPR – Campus Paranaguá e avaliá-las em critérios descontraídos de convivência, destaque e participação.\n\n'
                      'Cada avaliação atribui notas de 1 a 5 estrelas em 15 categorias. A soma dessas notas forma o Nível Lenda.\n\n'
                      'Cada usuário possui um ranking pessoal, baseado exclusivamente nas avaliações que realizou. O aplicativo também possui um ranking global, calculado a partir das avaliações realizadas pelos diferentes usuários.\n\n'
                      'Os dados são armazenados remotamente no Firestore e o acesso ao aplicativo utiliza Firebase Authentication.\n\n'
                      'O aplicativo também permite alternar entre tema claro e tema escuro.',
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              context,
              icon: Icons.auto_awesome,
              title: 'Cálculo do Nível Lenda',
              content:
                  'A pontuação do Nível Lenda é a soma direta das notas de 1 a 5 estrelas atribuídas em todos os 15 critérios. Portanto:\n\n'
                  '• Pontuação mínima: 15 pontos (1 estrela em cada categoria)\n'
                  '• Pontuação máxima: 75 pontos (5 estrelas em cada categoria)\n'
                  '• Cada usuário possui apenas uma avaliação ativa por pessoa, podendo alterá-la a qualquer momento sem duplicar votos.',
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              context,
              icon: Icons.leaderboard_rounded,
              title: 'Rankings Pessoal e Global',
              content:
                  '• Ranking Pessoal: Responde à pergunta "Na minha opinião, quem possui o maior Nível Lenda?". É baseado estritamente nas avaliações concedidas pelo usuário logado.\n\n'
                  '• Ranking Global: Responde à pergunta "Na opinião dos usuários do aplicativo, quem possui o maior Nível Lenda?". Considera as avaliações no Firestore de todos os participantes e calcula a média aritmética de cada pessoa.',
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              context,
              icon: Icons.cloud_done_outlined,
              title: 'Armazenamento & Autenticação',
              content:
                  '• Firestore: Armazena coleções remotas de usuários, pessoas cadastradas e avaliações de modo multiusuário e em tempo real.\n\n'
                  '• Firebase Authentication: Gerencia o acesso com segurança através de login por E-mail/Senha e autenticação integrada via Google.\n\n'
                  '• SharedPreferences: Utilizado de maneira complementar estritamente para preferências locais de tema (claro/escuro) e cache auxiliar de sessão.',
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: ExpansionTile(
                title: Text(
                  'Os 15 Critérios de Avaliação',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                leading: Icon(
                  Icons.checklist_rounded,
                  color: colorScheme.primary,
                ),
                children: CriterioAvaliacao.values.map((c) {
                  return ListTile(
                    dense: true,
                    title: Text(
                      c.nome,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(c.descricao),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.45,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
