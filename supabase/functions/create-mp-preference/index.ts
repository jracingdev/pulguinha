import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface PreferenceRequest {
  title: string;
  description?: string;
  price: number;
  quantity?: number;
  payer_email?: string;
  external_reference?: string;
  back_url?: string;
  notification_url?: string | null;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const accessToken = Deno.env.get("MP_ACCESS_TOKEN");
    if (!accessToken) {
      return new Response(
        JSON.stringify({ error: "MP_ACCESS_TOKEN não configurado nos secrets do Supabase" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const body = (await req.json()) as PreferenceRequest;
    const quantity = body.quantity ?? 1;

    const preference = {
      items: [
        {
          title: body.title,
          description: body.description ?? body.title,
          quantity,
          unit_price: body.price,
          currency_id: "BRL",
        },
      ],
      payer: body.payer_email ? { email: body.payer_email } : undefined,
      external_reference: body.external_reference,
      back_urls: body.back_url
        ? {
            success: body.back_url,
            failure: body.back_url.replace("success", "failure"),
            pending: body.back_url.replace("success", "pending"),
          }
        : undefined,
      auto_return: body.back_url ? "approved" : undefined,
      notification_url: body.notification_url ?? undefined,
    };

    const mpResponse = await fetch("https://api.mercadopago.com/checkout/preferences", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(preference),
    });

    const mpData = await mpResponse.json();

    if (!mpResponse.ok) {
      return new Response(JSON.stringify(mpData), {
        status: mpResponse.status,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify(mpData), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
