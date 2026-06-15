# Changelog — Funcional do Pulguinha

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/).
Versão segue [Semantic Versioning](https://semver.org/lang/pt-BR/).

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
