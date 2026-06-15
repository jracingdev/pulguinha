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
- **Sobre o app** — versão, desenvolvedor, termos e política de privacidade
- **Auto-cadastro** — alunos se cadastram com foto; admin aprova cadastros pendentes
- **Gestão admin** — horários/vagas, planos/preços e produtos da loja editáveis

## Acesso administrativo

O primeiro admin é criado pelo `supabase/schema.sql` ao configurar o banco. Em **modo demo** (sem Supabase), use as mesmas credenciais definidas no seed.

| Campo | Valor inicial |
|--------|----------------|
| **E-mail** | `admin@pulguinha.com` |
| **Senha** | `admin123` |

Na tela de login, selecione o perfil **Admin** antes de entrar.

> Altere a senha no banco (`admins`) antes de usar em produção. As credenciais não aparecem mais na interface do app.

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
   - Deixe vazio até configurar o DNS no Registro.br (veja seção abaixo)
   - Depois informe o domínio completo (ex.: `app.seudominio.com.br`)
3. Em **Settings → Secrets and variables → Actions → Variables**, adicione:
   - `PAGES_CUSTOM_DOMAIN` — domínio completo (ex.: `app.seudominio.com.br`)  
   Quando preenchida, o deploy usa `base-href /` e gera o arquivo `CNAME` automaticamente.
4. (Opcional, para Supabase em produção) **Settings → Secrets and variables → Actions → Secrets** — adicione:
   - `SUPABASE_URL` — URL do projeto Supabase
   - `SUPABASE_ANON_KEY` — chave anon pública  
   Sem esses secrets o app publica em **modo demo** (comportamento esperado).
4. Dispare o deploy:
   - **Actions → Deploy GitHub Pages → Run workflow**, ou
   - faça push para `main`

Aguarde o workflow terminar com sucesso (check verde). O app ficará em:

**https://jracingdev.github.io/pulguinha/**

### Domínio personalizado (Registro.br)

Recomendamos um **subdomínio** (ex.: `app.funcionaldopulguinha.com.br`) — configuração mais simples e estável.

#### 1. DNS no Registro.br

1. Acesse [registro.br](https://registro.br) → **Meus domínios** → seu domínio → **DNS**
2. Se o modo for “Página de redirecionamento”, altere para **Modo avançado / DNS**
3. Crie o registro conforme o tipo desejado:

**Opção A — Subdomínio (recomendado)** — ex.: `app.seudominio.com.br`

| Tipo  | Nome | Destino              |
|-------|------|----------------------|
| CNAME | app  | `jracingdev.github.io` |

**Opção B — Domínio raiz (apex)** — ex.: `seudominio.com.br`

| Tipo | Nome | Destino              |
|------|------|----------------------|
| A    | @    | `185.199.108.153`    |
| A    | @    | `185.199.109.153`    |
| A    | @    | `185.199.110.153`    |
| A    | @    | `185.199.111.153`    |

(Opcional, IPv6 — adicione também 4 registros AAAA com os valores oficiais do [GitHub Pages](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site).)

Para `www.seudominio.com.br`, adicione CNAME `www` → `jracingdev.github.io`.

A propagação DNS pode levar de alguns minutos até 24 horas.

#### 2. GitHub

1. **Settings → Pages → Custom domain** → informe o domínio (ex.: `app.seudominio.com.br`) → **Save**
2. Aguarde o **DNS check** ficar verde e o certificado HTTPS ser emitido
3. **Settings → Secrets and variables → Actions → Variables** → crie `PAGES_CUSTOM_DOMAIN` com o mesmo domínio
4. Rode o workflow **Deploy GitHub Pages** (ou push em `main`)

O app passará a abrir em `https://app.seudominio.com.br/` (sem `/pulguinha/` no final).

> **Mercado Pago / Supabase:** se usar callbacks ou URLs de retorno, atualize-as para o novo domínio.

### Link público da loja

- **URL principal:** `https://funcionaldopulguinha.com.br/loja` — abre a loja sem login
- **Admin → Loja:** botão para copiar o link
- **Atalho `loja.funcionaldopulguinha.com.br`:** o GitHub Pages aceita apenas um domínio por repositório. Remova o CNAME de `loja` e configure **redirecionamento** no Registro.br:
  - De: `loja.funcionaldopulguinha.com.br`
  - Para: `https://funcionaldopulguinha.com.br/loja`

### APK (Android) e Supabase

O APK publicado **não embute** credenciais Supabase (diferente do site, que recebe `--dart-define` no GitHub Actions). Na primeira instalação o app roda em **modo local** até o admin configurar a conexão.

**No celular (uma vez por aparelho):**

1. Abra o app → **Entrar** → perfil **Admin**
2. Login offline: `admin@pulguinha.com` / `admin123`
3. **Início → Configurações → Conexão Supabase**
4. Desbloqueie com a senha de admin e cole a **Project URL** e a **anon public key** (as mesmas dos secrets `SUPABASE_URL` e `SUPABASE_ANON_KEY` no GitHub)
5. Toque em **Salvar e conectar** — cadastros da web (ex.: alunos pendentes) passam a aparecer sem reiniciar o app

**Build APK com Supabase embutido (opcional, white-label):**

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://SEU_PROJETO.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sua_chave_anon_aqui
```

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
- Alteração de senha do admin pela interface
