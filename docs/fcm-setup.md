# Configurar FCM (Firebase Cloud Messaging) — Pulguinha

O app já tem o código de FCM. Sem o projeto Firebase, as notificações
continuam **locais** (agendamento/vencimento no aparelho). Com Firebase,
o token é salvo no Supabase e você pode enviar push remoto.

## 1. Criar projeto no Firebase

1. Acesse [Firebase Console](https://console.firebase.google.com/)
2. Adicione um app **Android** com package `com.pulguinha.pulguinha`
3. Baixe `google-services.json`
4. Coloque em: `android/app/google-services.json`
5. (Opcional iOS) adicione o app iOS e o `GoogleService-Info.plist` em `ios/Runner/`

O Gradle aplica o plugin Google Services **somente** se o JSON existir.

## 2. Banco

No SQL Editor do Supabase, rode:

`supabase/migration_fcm_tokens.sql`

## 3. Rebuild do app

```powershell
cd D:\pulguinha
C:\src\flutter\bin\flutter.bat pub get
C:\src\flutter\bin\flutter.bat build appbundle --release
```

No login, o app tenta registrar o token e gravar em `alunos.fcm_token` ou `admins.fcm_token`.

## 4. Enviar push (servidor)

Use a Cloud Function / Edge Function com a **Firebase Admin SDK** (service account).
Exemplo de payload:

```json
{
  "token": "<fcm_token do aluno>",
  "notification": {
    "title": "Pulguinha",
    "body": "Sua aula começa em 1 hora"
  }
}
```

Template inicial: `supabase/functions/send-push/index.ts` (requer secrets Firebase).

## 5. Conferência

```sql
SELECT id, nome, fcm_token IS NOT NULL AS tem_token FROM alunos ORDER BY nome;
SELECT id, nome, fcm_token IS NOT NULL AS tem_token FROM admins;
```
