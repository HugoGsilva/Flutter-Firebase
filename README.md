# PiramidGame IFPR-Pgua

Aplicativo Flutter da disciplina de Programação para Dispositivos Móveis do IFPR – Campus Paranaguá.

Permite cadastrar pessoas do campus e avaliá-las em 15 critérios descontraídos de popularidade (1 a 5 estrelas cada). A soma das notas forma o **Nível Lenda** (15 a 75 pontos). Cada usuário tem o seu **ranking pessoal** e todos contribuem para o **ranking global**, calculado pela média das avaliações recebidas.

## Funcionalidades

- Cadastro e login com e-mail/senha e login com conta Google (Firebase Authentication)
- Sessão mantida ao reabrir o app (a validade é sempre decidida pelo Firebase)
- Cadastro, listagem com busca e filtro por curso, detalhes, edição e remoção de pessoas
- Curso (INFO, MEC, MAMB, PROD, TADS, TGA), turma/ano (1998–2026) e data de nascimento por seleção
- Avaliação com Star Rating nos 15 critérios e alteração posterior da avaliação
- Uma avaliação por usuário e pessoa (`usuário + pessoa = uma avaliação`)
- Bloqueio de autoavaliação: o usuário vincula o próprio cadastro com **"Esta pessoa sou eu"**
- Ranking pessoal e ranking global (média + quantidade de avaliações)
- Tema claro/escuro alternado em tempo de execução e salvo no aparelho
- Tela Sobre o App

## Regras de negócio

| Regra | Onde é validada |
| --- | --- |
| Avaliar exige usuário autenticado | `ValidarAvaliacaoUseCase` + `firestore.rules` |
| Notas entre 1 e 5 nos 15 critérios | `ValidarAvaliacaoUseCase` + `firestore.rules` |
| Pontuação total calculada automaticamente | `ValidarAvaliacaoUseCase` + `firestore.rules` |
| Não é permitido avaliar a si próprio | `VerificarAutoavaliacaoUseCase` + `firestore.rules` |
| Uma avaliação ativa por usuário/pessoa | id `<uid>_<pessoaId>`, `RegistrarAvaliacaoUseCase` / `AlterarAvaliacaoUseCase` |
| Remoção pede confirmação e só quem cadastrou remove | `RemoverPessoaUseCase` + `firestore.rules` |
| Ao remover uma pessoa, as avaliações dela saem dos rankings | `FirestoreService.removerPessoa` (batch) |
| Uma pessoa só pode estar vinculada a uma conta | `VincularPessoaUseCase` |

## Tecnologias

Flutter, Firebase Authentication, Cloud Firestore, SharedPreferences, go_router e signals_flutter.

## Arquitetura

O projeto segue MVVM com Arquitetura Limpa, usando os padrões Command (ações da interface) e Result (retornos entre camadas):

```
UI → ViewModel (Signals + Commands) → Facade → Use Cases → Repositories → Services → Firebase
```

```
lib/
├── core/           # Command, Result, injeção de dependências, rotas e tema
├── data/
│   ├── errors/     # Conversão de erros do Firebase em mensagens para o usuário
│   ├── services/   # AuthService, GoogleAuthService, FirestoreService, LocalStorageService
│   └── repositories/
├── domain/
│   ├── models/
│   ├── repositories/  # Interfaces
│   ├── usecases/      # Regras de negócio (auth, pessoa, avaliação, ranking, tema)
│   └── facades/       # AuthFacade, PessoaFacade, AvaliacaoFacade, RankingFacade, TemaFacade
└── presentation/
    ├── viewmodels/
    └── views/
```

A UI conversa apenas com as ViewModels; Firebase e SharedPreferences ficam restritos aos services.

### Firestore

```
usuarios/{uid}          nome, email, foto, provider, pessoaId
pessoas/{id}            nome, apelido, curso, turma, dataNascimento, criadoPor
avaliacoes/{uid_pessoa} avaliadorUid, pessoaId, resenha, presencaVip, aura, ...,
                        caosControlado, pontuacaoTotal, dataAvaliacao
```

O SharedPreferences guarda somente a preferência de tema e um cache simples do usuário logado (nunca a senha).

## Configuração do Firebase

1. No console do Firebase, em **Authentication → Sign-in method**, habilite **E-mail/senha** e **Google**.
2. Em **Authentication → Settings → Authorized domains**, confira se `localhost` está na lista.
3. (Opcional) Publique as regras de segurança: `firebase deploy --only firestore:rules`.

As configurações dos apps web e Android (`br.edu.ifpr.piramid_game`) estão em `lib/firebase_options.dart`. Para o login com Google no Android, o SHA-1 do certificado de assinatura precisa estar cadastrado no app Android do Firebase.

## Como executar

```bash
flutter pub get
flutter run -d chrome
```

## Testes

```bash
flutter analyze
flutter test
```

Os testes de `test/` usam repositórios em memória e cobrem modelos, use cases, ViewModels e o fluxo completo da interface com o router real.

Os testes de `integration_test/` rodam contra o Firebase real. No navegador é necessário um [ChromeDriver](https://googlechromelabs.github.io/chrome-for-testing/) da mesma versão do Chrome rodando na porta 4444:

```bash
chromedriver --port=4444

# use cases + Firestore (com o banco em modo de teste)
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/firestore_e2e_test.dart -d web-server --browser-name=chrome

# fluxo completo pela interface (requer o Authentication habilitado)
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/app_e2e_test.dart -d web-server --browser-name=chrome
```

Os dois testes apagam os dados que criam ao final.
