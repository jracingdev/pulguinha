// Edge Function opcional — envio de push via Firebase Admin.
// Deploy: supabase functions deploy send-push
// Secrets: FIREBASE_SERVICE_ACCOUNT (JSON da service account)

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  const { token, title, body } = await req.json()
  if (!token || !title) {
    return new Response(JSON.stringify({ error: 'token e title são obrigatórios' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  const saRaw = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
  if (!saRaw) {
    return new Response(
      JSON.stringify({
        error: 'FIREBASE_SERVICE_ACCOUNT não configurado',
        hint: 'Configure o secret e use a Admin SDK / HTTP v1 do FCM',
      }),
      { status: 501, headers: { 'Content-Type': 'application/json' } },
    )
  }

  // Placeholder: integre com FCM HTTP v1 usando a service account.
  // https://firebase.google.com/docs/cloud-messaging/send-message
  return new Response(
    JSON.stringify({
      ok: false,
      message: 'Implemente a chamada FCM HTTP v1 com FIREBASE_SERVICE_ACCOUNT',
      preview: { token, title, body },
    }),
    { status: 501, headers: { 'Content-Type': 'application/json' } },
  )
})
