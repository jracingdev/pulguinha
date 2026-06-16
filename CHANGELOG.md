# Changelog — Funcional do Pulguinha

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/).
Versão segue [Semantic Versioning](https://semver.org/lang/pt-BR/).

## [1.3.0] - 2026-06-15

### Adicionado
- Admin pode moderar murais das turmas (ocultar, fixar, excluir) sem ver dados privados dos alunos
- Participação opcional do professor no mural (toggle + posts identificados)
- Alteração de senha pelo aluno (perfil) e pelo admin (painel)
- Reset de senha pelo admin com senha temporária
- Recuperação de senha: verificação de e-mail + orientação para contato com recepção
- CRUD admin de dicas da tela Evolução (Supabase `dicas_treino`)
- Desafios gamificados criados pelo admin (check-ins, streak, água) com recompensa em points
- Migration `supabase/migration_mural_dicas_desafios.sql`

### Alterado
- Versão do app: **1.3.0+4**
- Dicas e desafios na aba Evolução passam a usar conteúdo dinâmico do admin

## [1.2.0] - 2026-06-15

### Adicionado
- Widget `DateField` com calendário nativo (pt_BR) em cadastro, alunos, agenda admin e aluno
- Notificações locais: lembrete de aula (1h antes), vencimento (3 dias e no dia), cadastro pendente (admin), pagamento, avisos e eventos
- Arquitetura preparada para FCM (`NotificationService`, stub `FcmNotificationService`)
- Configurações de notificações no painel admin (som, tipos)
- Quadro de avisos e agenda de eventos do estúdio (aba Comunicação no admin)
- Menções `@aluno` com autocomplete e destaque neon
- Aba Avisos no aluno com seções "Para você", quadro e próximos eventos
- Resumo de avisos/eventos na home do aluno; badge vermelho em menções não lidas
- Migration SQL `supabase/migration_comunicacao.sql` (avisos, eventos, leituras)

### Alterado
- Versão do app: **1.2.0+3**

## [1.1.0] - 2026-06-15

### Adicionado
- Supabase embutido no APK (zero configuração por celular)
- PagBank / PagSeguro na loja
- Link público da loja (`/loja`)
- Domínio personalizado `funcionaldopulguinha.com.br`
- Campo **Aluno desde** no cadastro
- Pull-to-refresh na web e botão ↻ no header
- Realtime de alunos e agendamentos (Supabase)
- Mural da turma: figurinhas, enquetes e links
- Scripts `build_apk.ps1` e `bump_version.ps1`
- Workflow GitHub Actions para build do APK
- Versionamento visível no app (`v1.1.0`) e APK nomeado
- Dia de vencimento configurável (Financ.) e baixa manual (💰)
- Aprovação de aluno com data de vencimento e opção "já pagou"

### Corrigido
- Cadastro web grava no Supabase (sem falso sucesso offline)
- Pendentes não mostram mais "Vence hoje"
- Novo aluno não nasce devedor — vencimento no dia configurado do próximo ciclo
- Turma atribuída não restringe agendamento (textos na Agenda)
- Card Supabase removido do painel (app já vem configurado)
- Schema SQL separado do seed (sem erro de FK)
- Gráficos admin mais legíveis
- Mercado Pago com token no app (admin)

## [1.0.0] - 2026-06-01

### Adicionado
- Versão inicial: admin, aluno, agenda, QR, loja, Mercado Pago
