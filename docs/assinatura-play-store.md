# Assinatura Android / Google Play — evitar divergência entre computadores

## Por que dá erro ao publicar de outro PC?

A Play Store exige que o **mesmo upload key** assine o `.aab`/`.apk` de cada versão.
Se neste PC for gerada uma keystore nova (ou o release continuar com a chave **debug**), o Console rejeita com erro de assinatura.

Arquivos locais (não vão para o Git — estão no `.gitignore`):

| Arquivo | Função |
| --- | --- |
| `android/pulguinha-release.jks` (ou outro `.jks`) | Keystore de upload |
| `android/key.properties` | Senhas + alias + caminho do `.jks` |

O `build.gradle.kts` só usa a keystore de release se `key.properties` existir; caso contrário, o release ainda cai no debug (útil para testes locais, **não** para a loja).

## Caminho A — ideal: copiar do PC antigo

No computador que já publicou:

1. Localize o `.jks` (ex.: `pulguinha-release.jks`) e o `android/key.properties`.
2. Copie os dois para este PC, na pasta `android/` do projeto.
3. Ajuste `storeFile` no `key.properties` se o caminho mudar (ex.: `../pulguinha-release.jks` relativo a `android/app/`).
4. Confirme:

```powershell
cd D:\pulguinha
flutter build appbundle --release
```

5. Faça **backup** do `.jks` + senhas (pendrive criptografado / cofre de senhas). Sem isso, o próximo PC terá o mesmo problema.

## Caminho B — perdeu o `.jks`, mas tem acesso ao Play Console

Com **Play App Signing** ativo (padrão nas apps novas), o Google guarda a **chave de assinatura do app**. Você só precisa de um **novo upload key**:

1. Gere uma keystore nova neste PC:

```powershell
cd D:\pulguinha\android
keytool -genkey -v -keystore pulguinha-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias pulguinha
```

2. Exporte o certificado público:

```powershell
keytool -export -rfc -keystore pulguinha-upload.jks -alias pulguinha -file upload_certificate.pem
```

3. No [Play Console](https://play.google.com/console) → app Pulguinha → **Configuração** → **Integridade do app** (App integrity) → **Upload key certificate** → **Solicitar redefinição da chave de upload**.
4. Envie o `upload_certificate.pem` e aguarde a aprovação do Google (pode levar alguns dias).
5. Crie `android/key.properties` apontando para o novo `.jks` (veja `key.properties.example`).
6. Só depois publique o novo `.aab` assinado com essa keystore.

## Caminho C — conferir se a app já usa Play App Signing

Play Console → **Integridade do app**. Se estiver ativo, o certificado **App signing key** é o do Google; o seu `.jks` é só o **upload key**. Perder o upload key **não** impede redefinição (caminho B). Perder a app signing key sem Play App Signing é cenário grave e raro em apps recentes.

## Checklist antes de subir a nova versão

- [ ] `android/key.properties` presente e correto neste PC
- [ ] Release **não** assinado com debug (`signingConfigs.release` ativo)
- [ ] `version` incrementada no `pubspec.yaml` (`versionName+versionCode`, ex. `1.4.0+6`)
- [ ] `flutter build appbundle --release`
- [ ] Upload do `build/app/outputs/bundle/release/app-release.aab` na trilha desejada

## Como validar a assinatura localmente

```powershell
# SHA-256 do certificado do AAB gerado
keytool -printcert -jarfile build\app\outputs\bundle\release\app-release.aab
```

Compare com o **Upload key certificate** exibido no Play Console. Se o fingerprint for outro, a loja vai rejeitar.
