# Funcional do Pulguinha

App Flutter de gestão e agendamento para o estúdio **Funcional do Pulguinha**, baseado no protótipo React (`pulguinha-app.jsx`).

## Funcionalidades

- **Área pública** — agendar aula e assinar plano sem login
- **Login** — aluno e admin (Supabase ou modo demo offline)
- **Painel Admin** — dashboard com KPIs/gráficos, alunos, agenda, **presença (QR)**, financeiro e loja
- **Área do Aluno** — início, **check-in QR**, agenda, loja e perfil
- **Presença QR** — admin exibe QR da aula/dia; aluno escaneia ao chegar (Android, iOS e web)
- **Anamnese, fotos, aniversariantes** — cadastro completo e gamificação (streak, Pulguinha Points)
- **Loja + Mercado Pago** — Checkout Pro real (Payment Links ou Edge Function Supabase) com fallback demo
- **Tema claro/escuro** — alternância persistida em Perfil e Admin
- **Sobre o app** — versão, desenvolvedor e logo

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

> **Fotos:** armazenadas em base64 no campo `foto` do aluno (demo). Em produção, prefira Supabase Storage.

### Mercado Pago (Checkout Pro)

A integração real está implementada em `lib/services/mercado_pago_service.dart`. O **access token nunca vai para o app** — apenas para a Edge Function.

#### Opção A — Payment Links (mais rápido)

1. Crie links de pagamento no [painel Mercado Pago](https://www.mercadopago.com.br/developers/panel/app)
2. Execute com `--dart-define` por produto:

```bash
flutter run \
  --dart-define=MP_PUBLIC_KEY=SUA_PUBLIC_KEY \
  --dart-define=MP_LINK_PLANO_MENSAL=https://mpago.la/... \
  --dart-define=MP_LINK_PLANO_TRIMESTRAL=https://mpago.la/... \
  --dart-define=MP_LINK_PLANO_SEMESTRAL=https://mpago.la/... \
  --dart-define=MP_LINK_PLANO_ANUAL=https://mpago.la/...
```

#### Opção B — Edge Function Supabase (Checkout Pro dinâmico)

1. Deploy da function:

```bash
supabase functions deploy create-mp-preference
supabase secrets set MP_ACCESS_TOKEN=SEU_ACCESS_TOKEN_MP
```

2. Execute com Supabase + public key:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://SEU_PROJETO.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sua_chave_anon \
  --dart-define=MP_PUBLIC_KEY=SUA_PUBLIC_KEY
```

3. (Opcional) Deep link de retorno: `--dart-define=MP_BACK_URL=pulguinha://payment/success`

Sem credenciais configuradas, a loja usa **modo demonstração** com aviso explícito.

### Check-in QR (fluxo correto)

1. **Admin/Professor** — aba Presença → exibe QR da aula ou QR do dia em tela cheia (projetor/TV)
2. **Aluno** — botão "Fazer Check-in" → escaneia o QR com a câmera
3. **Web** — scanner via `mobile_scanner`; se a câmera falhar, use entrada manual do código

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
├── config/
│   ├── supabase_config.dart      # URL e chave via --dart-define
│   └── mercado_pago_config.dart  # MP public key, payment links
├── services/
│   ├── supabase_service.dart     # CRUD Supabase
│   └── mercado_pago_service.dart # Checkout Pro / Payment Links
├── screens/                      # Telas por módulo
├── theme/                        # Cores e tema escuro neon
└── widgets/                      # Componentes reutilizáveis

supabase/
├── schema.sql                              # Tabelas, RLS e dados iniciais (seed)
└── functions/create-mp-preference/index.ts # Cria preferência MP (access token no secret)
```

## Roadmap (fora do escopo atual)

- Webhook MP para confirmação automática de pagamento
- Supabase Auth (substituir senha em texto)
- Políticas RLS mais restritivas em produção
- Push notifications para lembretes de aula
