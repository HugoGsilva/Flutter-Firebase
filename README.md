# PiramidGame IFPR-Pgua

Aplicativo móvel desenvolvido para a disciplina de Programação para Dispositivos Móveis no Instituto Federal do Paraná (IFPR) - Campus Paranaguá.

O projeto implementa uma plataforma de avaliação e classificação colaborativa baseada na "Pirâmide de Lendas", permitindo cadastro de pessoas, avaliação segundo 15 critérios objetivos (notas de 1 a 5 estrelas) e geração dinâmica de rankings pessoais e globais.

---

## Funcionalidades Principais

- **Autenticação de Usuários**: Login e cadastro com e-mail/senha e autenticação via Google (Firebase Auth).
- **Gestão de Pessoas (CRUD)**: Cadastro, listagem com busca e filtro por curso, edição e remoção com diálogo de confirmação.
- **Sistema de Avaliação por Estrelas (Star Rating)**: Avaliação interativa em 15 critérios, cálculo dinâmico do Nível Lenda (Bronze a Diamante) e bloqueio estrito de autoavaliação.
- **Rankings em Tempo Real**:
  - **Ranking Pessoal**: Exibe a lista ordenada pelas pontuações concedidas pelo usuário logado ("Quem eu acho mais lenda?").
  - **Ranking Global**: Média aritmética ponderada e classificação geral de todos os avaliadores da turma/campus ("Quem a galera acha mais lenda?").
- **Personalização de Tema**: Alternância entre tema claro e escuro persistida localmente.
- **Tela Sobre Acadêmica**: Apresentação institucional com contexto do jogo e descrição completa dos critérios.

---

## Tecnologias Utilizadas

- **Flutter / Dart** (SDK 3.9+)
- **Firebase Authentication** (Gestão de contas e login social)
- **Cloud Firestore** (Persistência NoSQL e sincronização em tempo real)
- **Signals (`signals_flutter`)** (Gerenciamento de estado reativo e Command Pattern)
- **GoRouter** (Navegação declarativa com redirecionamentos de autenticação)
- **SharedPreferences** (Armazenamento de preferências locais e tema)

---

## Como Executar o Projeto

### Pré-requisitos
- Flutter SDK instalado e configurado no PATH
- Dispositivo físico conectado (com depuração USB) ou emulador Android/iOS

### Passo a Passo

1. Obtenha as dependências do projeto:
   ```bash
   flutter pub get
   ```

2. Verifique a integridade do código e execute os testes:
   ```bash
   flutter analyze
   flutter test
   ```

3. Execute o aplicativo:
   ```bash
   flutter run
   ```

---

## Estrutura do Projeto

```
lib/
├── core/             # Utilitários, Command pattern, injeção de dependência e rotas
├── data/             # Serviços (Auth, Firestore, LocalStorage) e repositórios
├── domain/           # Entidades/modelos, interfaces, use cases e facades
├── presentation/     # ViewModels (Signals), telas (Views) e componentes reutilizáveis
└── main.dart         # Ponto de entrada e inicialização das dependências
```