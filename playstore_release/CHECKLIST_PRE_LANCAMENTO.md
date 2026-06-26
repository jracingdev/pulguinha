# Checklist Pre-Lancamento (Google Play)

## 1) Build e assinatura

- [ ] Configurar assinatura de release (keystore propria) em `android/app/build.gradle.kts`.
- [ ] Garantir que **nao** esta usando debug signing em release.
- [ ] Incrementar `version` no `pubspec.yaml`.
- [ ] Gerar bundle: `flutter build appbundle --release`.
- [ ] Validar instalacao local do build assinado.

## 2) Qualidade e testes

- [ ] Rodar `flutter analyze`.
- [ ] Rodar testes automatizados (quando existirem).
- [ ] Testar fluxo de login admin/aluno/publico.
- [ ] Testar agendamento (inclusive publico sem login).
- [ ] Testar notificacoes (aula, comunicacao, vencimento).
- [ ] Testar compras/checkout (MP e PagBank).
- [ ] Testar offline e online (Supabase indisponivel/disponivel).

## 3) Politicas Play Store e dados do app

- [x] Publicar URL publica da Politica de Privacidade (HTML em `docs/privacidade/` — falta deploy).
- [x] Publicar URL publica de Termos de Uso (HTML em `docs/termos/` — falta deploy).
- [ ] Preencher formulario de Data Safety no Play Console.
- [ ] Declarar uso de Camera (check-in QR) no Data Safety/Permissoes.
- [ ] Declarar uso de Notificacoes (POST_NOTIFICATIONS).
- [ ] Confirmar classificacao etaria.
- [ ] Revisar se app nao contem claims medicas proibidas.

## 4) Conteudo da ficha do app

- [ ] Titulo do app (ate 30 caracteres).
- [ ] Descricao curta (ate 80 caracteres).
- [ ] Descricao completa (ate 4000 caracteres).
- [ ] Categoria correta (Saude e fitness / Educacao / outro).
- [ ] E-mail de suporte.
- [ ] Telefone/site (opcional, recomendado).

## 5) Artes e midia

- [ ] Icone 512x512 PNG (sem transparencia).
- [ ] Feature Graphic 1024x500 PNG/JPG.
- [ ] Minimo de 2 screenshots por tipo de dispositivo.
- [ ] Screenshot celular: 16:9 ou 9:16, sem borda externa exagerada.
- [ ] (Opcional) Video de apresentacao.

## 6) Publicacao controlada

- [ ] Criar trilha de teste interno.
- [ ] Convidar testadores.
- [ ] Corrigir feedbacks.
- [ ] Publicar em producao com rollout gradual (ex: 10%).

## 7) Pos-publicacao

- [ ] Monitorar crashes/ANR.
- [ ] Monitorar reviews da loja.
- [ ] Planejar patch rapido para problemas criticos.
