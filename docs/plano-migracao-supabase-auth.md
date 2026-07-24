# Plano de migração para o Supabase Auth e recuperação de senha

Documento de referência da migração da autenticação do Pulguinha (app em produção,
v1.3.0) para o **Supabase Auth**, com redefinição de senha por e-mail.

Arquivos relacionados:

- `supabase/migration_supabase_auth.sql` — preparação do banco (seguro em produção).
- `supabase/scripts/provisionar_auth_users.sql` — provisionamento via SQL.
- `supabase/scripts/provisionar_auth_users.mjs` — provisionamento via Admin API (recomendado).
- `supabase/migration_supabase_auth_rls.sql` — RLS com `auth.uid()` (parte B ainda pendente).

---

## 1. Situação de origem

| Item | Como era |
| --- | --- |
| Login | Comparação direta de e-mail + senha **em texto claro** nas tabelas `alunos` e `admins` |
| Supabase Auth | Não utilizado |
| "Esqueci a senha" | Apenas confirmava o cadastro e **vazava** nome e final do telefone; não funcionava para admin |
| Reset de senha | Senha temporária definida pelo professor, exibida na tela |
| RLS | `FOR ALL USING (true)` — a chave anon lia e escrevia tudo, inclusive senhas |
| Deep links | Somente `pulguinha://payment` |
| Senha mínima | 4 caracteres |

## 2. Arquitetura escolhida

1. **Supabase Auth é a fonte da verdade das credenciais.** O login chama
   `signInWithPassword`; o perfil (`alunos` ou `admins`) é lido depois, só para
   montar os modelos `Aluno`/`Usuario` que o app já usa.
2. **Vínculo por `auth_user_id uuid`** nas tabelas `alunos` e `admins`, com FK
   para `auth.users(id)`. O e-mail continua sendo a chave natural de ligação
   (índice único em `lower(email)`), e um trigger em `auth.users` preenche o
   vínculo automaticamente em contas novas.
3. **Fallback legado temporário.** Se a conta ainda não existe no Auth, o login
   cai na comparação antiga. Isso mantém a produção funcionando durante a
   migração e é desligado com `--dart-define=PULG_LOGIN_LEGADO=false`
   (`lib/config/auth_config.dart`).
4. **A senha legada é invalidada** (substituída por um marcador aleatório) sempre
   que a conta passa a usar o Auth — assim a senha antiga não continua valendo
   pelo fallback.
5. **Recuperação oficial** via `resetPasswordForEmail` + evento
   `PASSWORD_RECOVERY` + `updateUser(password:)`. Sem Edge Function: o e-mail é
   enviado pelo próprio Supabase.

### Migração incremental (estado de cada fase)

| Fase | O que é | Status |
| --- | --- | --- |
| 0 | Código do app suportando Auth + fallback legado | **Feito** (este commit) |
| 1 | `migration_supabase_auth.sql` — colunas, funções, trigger | Feito (falta **executar** no painel) |
| 2 | Config do painel: redirect URLs, SMTP, template | **Manual — pendente** |
| 3 | Provisionar `auth.users` a partir de `alunos`/`admins` | **Manual — pendente** |
| 4 | Desligar o fallback legado (`PULG_LOGIN_LEGADO=false`) e proteger `admins` (RLS parte A) | Pendente |
| 5 | RLS completo + `DROP COLUMN senha` + carregar dados após login | Pendente (ver §8) |

> Nada em produção muda de comportamento até a fase 2/3 serem executadas: sem
> contas no Auth, o `signInWithPassword` falha e o login usa o caminho antigo.

## 3. Fluxo de recuperação ponta a ponta

```
Aluno/admin toca "Esqueci a senha" na tela de login
   -> AppState.solicitarRedefinicaoSenha(email)
   -> SupabaseService.enviarLinkRedefinicaoSenha(email)
        auth.resetPasswordForEmail(email, redirectTo: AuthConfig.resetRedirectUrl)
   -> UI mostra SEMPRE: "Se o e-mail estiver cadastrado, enviaremos um link..."
      (erros são engolidos de propósito: nada revela se a conta existe)

Supabase envia o e-mail (template "Reset Password")
   -> usuário clica no link -> /auth/v1/verify?type=recovery -> redirectTo

Retorno no app
   mobile: deep link pulguinha://reset-password
   web:    https://funcionaldopulguinha.com.br/reset-password (#access_token ou ?code)
   -> supabase_flutter valida o token e emite AuthChangeEvent.passwordRecovery
   -> SupabaseBootstrap (listener onAuthStateChange) -> PasswordRecoveryNotifier
   -> app.dart mostra DefinirNovaSenhaScreen
   -> AppState.definirNovaSenhaRecuperacao(novaSenha)
        auth.updateUser(UserAttributes(password: ...))
        + invalida a senha legada + signOut
   -> usuário volta ao login e entra com a senha nova
```

Detalhes de robustez:

- O evento pode chegar **antes** da árvore de widgets montar (deep link que abre o
  app), por isso o estado fica retido em `PasswordRecoveryNotifier`.
- Na web, `PasswordRecoveryNotifier.capturarLinkWeb()` roda **antes** de
  `Supabase.initialize`, porque o SDK limpa o fragment da URL ao processar o link.
  Se o token não validar em 12 s, a tela informa "link inválido ou expirou".
- `PASSWORD_RECOVERY` é emitido tanto no fluxo PKCE (`?code=`) quanto no
  implícito (`#access_token=...&type=recovery`).

## 4. Deep links por plataforma

| Plataforma | `redirectTo` | Onde está configurado |
| --- | --- | --- |
| Android | `pulguinha://reset-password` | `android/app/src/main/AndroidManifest.xml` (intent-filter, `launchMode=singleTop`) |
| iOS | `pulguinha://reset-password` | `ios/Runner/Info.plist` (`CFBundleURLTypes`, esquema `pulguinha`) |
| Web (produção) | `https://funcionaldopulguinha.com.br/reset-password` | `lib/config/auth_config.dart` (usa a origem atual) |
| Web (dev) | `http://localhost:<porta>/reset-password` | idem — resolvido em tempo de execução |

Para hospedagens estáticas sem reescrita de rotas, `web/reset-password/index.html`
é uma página-ponte que reencaminha o token para a raiz do app (onde o Flutter web
está servido). Ela é copiada automaticamente para `build/web` pelo
`flutter build web`.

Override manual, se algum ambiente precisar:
`--dart-define=PULG_RESET_REDIRECT=https://meu-preview/reset-password`.

## 5. Passos manuais no painel Supabase

### 5.1 Authentication → URL Configuration

- **Site URL**: `https://funcionaldopulguinha.com.br`
- **Redirect URLs** (adicionar todas):
  - `https://funcionaldopulguinha.com.br/reset-password`
  - `https://funcionaldopulguinha.com.br/**` (cobre a página-ponte e a raiz)
  - `pulguinha://reset-password`
  - `http://localhost:*/reset-password` (apenas se for testar em dev na web)

> Sem a URL na allow-list, o Supabase ignora o `redirectTo` e manda o usuário
> para a Site URL — o app não recebe o token e o fluxo falha silenciosamente.

### 5.2 Authentication → Providers → Email

- **Enable Email provider**: ligado.
- **Confirm email**: recomendo **desligar** durante a migração. Com a confirmação
  ligada, cadastros novos (`signUp` na tela de cadastro público) só conseguem
  entrar pelo Auth após confirmar o e-mail — hoje o fallback legado cobre isso,
  mas depois da fase 4 passaria a bloquear.
- **Minimum password length**: `6` (já alinhado no app via `AuthConfig.senhaMinima`).

### 5.3 Authentication → Emails → SMTP (obrigatório para produção)

O SMTP nativo do Supabase é limitado (poucos e-mails por hora, só para endereços
da equipe) — **não serve para produção**. Configure um provedor próprio em
*Project Settings → Authentication → SMTP Settings*:

1. Crie conta no Resend, SendGrid ou Amazon SES.
2. Verifique o domínio `funcionaldopulguinha.com.br` (registros SPF/DKIM no DNS).
3. Preencha host, porta (587), usuário, senha, *Sender email*
   (ex.: `nao-responda@funcionaldopulguinha.com.br`) e *Sender name*
   (`Funcional do Pulguinha`).
4. Ajuste o **rate limit** de e-mails em *Authentication → Rate Limits*.

### 5.4 Authentication → Emails → Templates → Reset Password

Sugestão de assunto: `Redefinir sua senha — Funcional do Pulguinha`.

```html
<h2>Redefinir senha</h2>
<p>Recebemos um pedido para redefinir a senha da sua conta no Funcional do Pulguinha.</p>
<p><a href="{{ .ConfirmationURL }}">Criar nova senha</a></p>
<p>O link expira em 1 hora. Se não foi você, ignore este e-mail.</p>
```

Mantenha `{{ .ConfirmationURL }}`: é ele que carrega o token e o `redirect_to`.

## 6. Executar as migrações de banco

1. **Backup**: *Database → Backups* (ou snapshot) antes de qualquer passo.
2. Rode `supabase/migration_supabase_auth.sql` no SQL Editor. Ele é idempotente e
   não altera RLS.
3. Confira o que falta provisionar:
   ```sql
   SELECT count(*) FROM alunos WHERE auth_user_id IS NULL;
   SELECT count(*) FROM admins WHERE auth_user_id IS NULL;
   ```

## 7. Provisionar os usuários existentes

Escolha **uma** das opções. Ambas reaproveitam a senha atual, então ninguém
precisa trocar de senha por causa da migração.

### Opção A — Admin API (recomendada)

```powershell
$env:SUPABASE_URL="https://tvztfgjmhxmwjzsnugic.supabase.co"
$env:SUPABASE_SERVICE_ROLE_KEY="<service_role — NUNCA comitar>"
node supabase/scripts/provisionar_auth_users.mjs --dry-run   # confere
node supabase/scripts/provisionar_auth_users.mjs             # executa
```

Usa `POST /auth/v1/admin/users` com `email_confirm: true` e grava o
`auth_user_id` de volta no perfil. Idempotente e independente do layout interno
do schema `auth`.

### Opção B — SQL

Rode `supabase/scripts/provisionar_auth_users.sql` no SQL Editor. Insere direto em
`auth.users`/`auth.identities` com `crypt(senha, gen_salt('bf'))`. Mais rápido,
mas depende do formato interno das tabelas de `auth` (o bloco de identidades
avisa e segue se o layout for diferente).

### Depois de provisionar

1. Teste o login de **um admin** e de **um aluno** no app.
2. Teste "Esqueci a senha" ponta a ponta (web e Android).
3. Rode a **parte A** de `migration_supabase_auth_rls.sql` para proteger a tabela
   `admins` (para a chave anon parar de ler e-mails/senhas de administradores).
4. Publique uma build com `--dart-define=PULG_LOGIN_LEGADO=false` para desligar o
   fallback de senha em texto.
5. Só então avalie a fase 5 (§8).

## 8. RLS

`migration_supabase_auth_rls.sql` está dividido:

- **Parte A (aplicável após o passo 7)** — `admins` deixa de ser legível pela
  chave anon; cada admin só vê/atualiza o próprio registro. As funções
  `public.eh_admin()` e `public.aluno_id_sessao()` (SECURITY DEFINER) resolvem a
  identidade dentro das políticas.
- **Parte B (comentada, NÃO rodar ainda)** — `alunos` e tabelas de conteúdo
  restritas a `authenticated`. **Pré-requisito de código**: hoje o `AppState`
  sincroniza *todas* as tabelas na inicialização, **antes** do login. Com RLS
  exigindo sessão, esse carregamento falharia e o app cairia em modo offline.
  Portanto a fase 5 precisa, na ordem:
  1. mover a carga de dados para depois do login;
  2. usar a RPC `public.email_ja_cadastrado()` no cadastro público (já criada na
     migração 1) em vez de ler `alunos` com a chave anon;
  3. expor os colegas de turma por uma view enxuta (nome/avatar/horário) em vez
     de liberar `SELECT *` em `alunos` para qualquer aluno logado;
  4. `ALTER TABLE alunos DROP COLUMN senha;` e o mesmo em `admins` — depois de
     remover `senha` de `Aluno.toInsertJson()` em `lib/models/models.dart`
     (o `toJson()` de update já não envia a coluna) e de apagar os métodos de
     fallback legado em `SupabaseService`.

## 9. Riscos e mitigações

| Risco | Impacto | Mitigação |
| --- | --- | --- |
| Redirect URL não cadastrada no painel | Link do e-mail volta para a Site URL e o app não recebe o token | Cadastrar as 4 URLs da §5.1 antes de anunciar o recurso |
| SMTP não configurado | E-mails não chegam (limite do SMTP nativo) | Provedor próprio (§5.3) antes de liberar para os alunos |
| Perfis com e-mail duplicado/inválido | Provisionamento falha para esses registros | Índice único em `lower(email)` na migração 1; scripts filtram e-mails inválidos e listam as falhas |
| Senha legada continuar valendo depois do reset | Senha antiga ainda entraria pelo fallback | `invalidarSenhaLegada()` sobrescreve a coluna com marcador aleatório; login legado rejeita senha vazia |
| Ativar RLS antes da hora | App cai em modo offline / cadastro público quebra | Parte B comentada, com pré-requisitos explícitos (§8) |
| Confirmação de e-mail ligada | Cadastro novo não entra via Auth | Fallback legado cobre; recomendação de desligar (§5.2) |
| Senhas atuais com menos de 6 caracteres | Login continua funcionando, mas trocas futuras exigem 6+ | Mensagem de validação já explica o mínimo |
| Aluno sem acesso ao e-mail | Não recebe o link | Admin → Alunos mantém "Definir senha temporária" (válida enquanto a conta não migrar) |

## 10. Rollback

Por camada, do menos ao mais invasivo:

1. **App**: publicar build com `PULG_LOGIN_LEGADO=true` (padrão) — o login volta a
   aceitar as senhas em texto imediatamente.
2. **RLS**: rodar o bloco de rollback no fim de cada parte de
   `migration_supabase_auth_rls.sql` (recria as políticas `anon_all_*`).
3. **Contas no Auth**: podem ficar como estão sem afetar o login legado. Para
   remover:
   ```sql
   DELETE FROM auth.users
    WHERE raw_user_meta_data ->> 'origem' = 'migracao_pulguinha';
   ```
   (a FK `ON DELETE SET NULL` limpa o `auth_user_id` dos perfis).
4. **Colunas/trigger**: `DROP TRIGGER trg_vincular_auth_user ON auth.users;` e
   `ALTER TABLE alunos DROP COLUMN auth_user_id;` (idem `admins`).
5. **Senhas invalidadas**: usuários que já redefiniram a senha via Auth têm a
   coluna `senha` com um marcador. No rollback, use "Definir senha temporária" no
   painel do admin para esses casos.

## 11. Checklist de validação

- [ ] `migration_supabase_auth.sql` executado; `auth_user_id` existe nas duas tabelas
- [ ] Redirect URLs cadastradas (web + `pulguinha://reset-password`)
- [ ] SMTP próprio configurado e template de recovery em português
- [ ] Provisionamento rodado; `alunos`/`admins` sem `auth_user_id` = 0
- [ ] Login de admin via Auth OK
- [ ] Login de aluno via Auth OK
- [ ] "Esqueci a senha" no web: e-mail chega, link abre a tela, senha nova entra
- [ ] "Esqueci a senha" no Android: deep link abre o app na tela de nova senha
- [ ] E-mail inexistente devolve a mesma mensagem genérica
- [ ] Alterar senha no perfil do aluno e no dashboard do admin funcionando
- [ ] RLS parte A aplicada; chave anon não lê mais `admins`
- [ ] Build de produção com `PULG_LOGIN_LEGADO=false`
