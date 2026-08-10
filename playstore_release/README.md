# Play Store Release Pack

Esta pasta centraliza tudo que voce precisa para publicar o app na Google Play.

## Conteudo desta pasta

- `CHECKLIST_PRE_LANCAMENTO.md`: checklist tecnico e de compliance.
- `METADADOS_PLAYSTORE.md`: textos da ficha do app (titulo, descricao curta, completa etc.).
- `LINKS_OBRIGATORIOS.md`: links publicos exigidos para publicacao.
- `TERMOS_USO.md`: termo de uso pronto para publicar em URL publica.
- `POLITICA_PRIVACIDADE.md`: politica de privacidade pronta para URL publica.
- `../docs/privacidade/` e `../docs/termos/`: paginas HTML prontas para deploy.
- `ASSETS/`: artes prontas (`icon-512.png`, `feature-graphic-1024x500.png`) + guia de screenshots.
- `ASSETS/README.md`: tamanhos e especificacoes das imagens da Play Store.

## Estado atual detectado no projeto

- `applicationId`: `com.pulguinha.pulguinha`
- `minSdk`: `23`
- `targetSdk`: via Flutter (ok, mas conferir no build final)
- Permissoes declaradas: camera e notificacoes (exige justificativa na ficha de dados/uso)
- **Atencao**: assinatura de release usa `android/key.properties` + `.jks` quando presentes (veja `docs/assinatura-play-store.md`). Sem esses arquivos o release cai no debug — **nao publique assim**. **Faca backup da keystore e das senhas** antes de publicar.

## URLs legais (Play Store)

| Documento | URL |
|-----------|-----|
| Politica de Privacidade | https://funcionaldopulguinha.com.br/privacidade |
| Termos de Uso | https://funcionaldopulguinha.com.br/termos |

Arquivos HTML prontos em `docs/privacidade/index.html` e `docs/termos/index.html`.

## Como publicar as paginas legais

### Opcao A — GitHub Pages (automatico)

O workflow `.github/workflows/deploy.yml` ja copia `docs/privacidade/` e `docs/termos/` para o build web a cada push na branch `main`. Com o dominio customizado `funcionaldopulguinha.com.br` configurado no GitHub Pages, as URLs ficam ativas apos o deploy.

1. Faca commit e push das alteracoes em `docs/` para `main`.
2. Aguarde o workflow **Deploy GitHub Pages** concluir.
3. Teste no navegador: `/privacidade` e `/termos`.

### Opcao B — Upload manual (cPanel / FTP no Registro.br)

Se o site esta hospedado fora do GitHub Pages:

1. Conecte via FTP ou Gerenciador de Arquivos do cPanel.
2. Na raiz do dominio `funcionaldopulguinha.com.br`, crie as pastas `privacidade/` e `termos/`.
3. Envie `docs/privacidade/index.html` para `privacidade/index.html`.
4. Envie `docs/termos/index.html` para `termos/index.html`.
5. Acesse as URLs no navegador para confirmar HTTPS e conteudo.

### Opcao C — GitHub Pages sem dominio proprio

Sem dominio customizado, o app fica em `https://jracingdev.github.io/pulguinha/`. Nesse caso, as paginas legais ficariam em `/pulguinha/privacidade/` — ajuste as URLs em `lib/config/app_links.dart` e `METADADOS_PLAYSTORE.md` se usar essa opcao.

## Ordem recomendada

1. Revisar `CHECKLIST_PRE_LANCAMENTO.md`.
2. Fazer deploy das paginas legais (secao acima).
3. Gerar e validar as artes em `ASSETS/`.
4. Preencher `METADADOS_PLAYSTORE.md` (e-mail de suporte ainda pendente).
5. Corrigir assinatura de release e gerar `.aab`.
6. Subir no Google Play Console.
