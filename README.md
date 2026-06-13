# Funcional do Pulguinha

App Flutter de gestão e agendamento para o estúdio **Funcional do Pulguinha**, baseado no protótipo React (`pulguinha-app.jsx`).

## Funcionalidades

- **Área pública** — agendar aula e assinar plano sem login
- **Login** — aluno e admin (Supabase ou modo demo offline)
- **Painel Admin** — dashboard, alunos, agenda, financeiro e loja
- **Área do Aluno** — início, agenda, loja e perfil
- **Loja + Mercado Pago** — fluxo simulado de pagamento (PIX, cartão, boleto)

## Credenciais demo

| Perfil | E-mail | Senha |
|--------|--------|-------|
| Admin | admin@pulguinha.com | admin123 |
| Aluno | ana@email.com | 1234 |

## Executar localmente

```bash
flutter pub get
flutter run
```

Sem variáveis de ambiente, o app roda em **modo demo** com dados mock locais.

### Testes e qualidade

```bash
flutter analyze
flutter test
flutter build web --release --base-href "/pulguinha/"
```

### Com Supabase

1. Crie um projeto em [supabase.com](https://supabase.com)
2. No **SQL Editor**, execute o arquivo `supabase/schema.sql`
3. Copie a **Project URL** e a **anon public key** (Settings → API)
4. Execute com:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://SEU_PROJETO.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sua_chave_anon_aqui
```

> **Nunca** commite chaves reais no repositório. Use `--dart-define` ou secrets do CI.

## Deploy no GitHub Pages

O workflow `.github/workflows/deploy.yml` faz build e deploy automático a cada push na branch `main`.

> **Se o site mostra o conteúdo deste README em vez do app**, a causa é quase sempre a origem do Pages estar em **"Deploy from a branch"** em vez de **GitHub Actions**. Veja a seção abaixo.

### Configuração obrigatória no GitHub (UI)

1. Abra **Settings → Pages → Build and deployment**
   - **Source:** selecione **GitHub Actions** (não use "Deploy from a branch" / `main` / `(root)`)
2. Em **Settings → Pages → Custom domain**
   - **Remova** qualquer valor inválido (ex.: `pulguinha` sem `.com`) e deixe o campo **vazio**
   - Salve; o banner de erro do domínio deve sumir
3. (Opcional, para Supabase em produção) **Settings → Secrets and variables → Actions** — adicione:
   - `SUPABASE_URL` — URL do projeto Supabase
   - `SUPABASE_ANON_KEY` — chave anon pública  
   Sem esses secrets o app publica em **modo demo** (comportamento esperado).
4. Dispare o deploy:
   - **Actions → Deploy GitHub Pages → Run workflow**, ou
   - faça push para `main`

Aguarde o workflow terminar com sucesso (check verde). O app ficará em:

**https://jracingdev.github.io/pulguinha/**

### Build web manual

```bash
flutter build web --release --base-href "/pulguinha/"
```

Com Supabase:

```bash
flutter build web --release --base-href "/pulguinha/" \
  --dart-define=SUPABASE_URL=https://SEU_PROJETO.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sua_chave_anon_aqui
```

## Estrutura

```
lib/
├── app.dart                      # Roteamento principal
├── config/supabase_config.dart   # URL e chave via --dart-define
├── data/mock_data.dart           # Fallback offline / demo
├── models/models.dart            # Aluno, Horario, Agendamento, etc.
├── providers/app_state.dart      # Estado global (Provider)
├── services/supabase_service.dart # CRUD Supabase
├── screens/                      # Telas por módulo
├── theme/                        # Cores e tema escuro neon
└── widgets/                      # Componentes reutilizáveis

supabase/
└── schema.sql                    # Tabelas, RLS e dados iniciais (seed)
```

## Roadmap (fora do escopo atual)

- Integração real com Mercado Pago
- Supabase Auth (substituir senha em texto)
- Políticas RLS mais restritivas em produção
- Push notifications para lembretes de aula
