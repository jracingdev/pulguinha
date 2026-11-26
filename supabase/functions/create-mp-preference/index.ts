import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import {
  carregarProduto,
  corsHeaders,
  emailValido,
  json,
  urlRetornoValida,
} from "../_shared/produto.ts";

// Cria a preferência do Checkout Pro. O Access Token fica só no secret
// MP_ACCESS_TOKEN; nome e preço vêm da tabela `produtos` pelo product_id.
// Campos title/price enviados pelo app são ignorados.

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") return json({ error: "Método não permitido" }, 405);

  try {
    const accessToken = Deno.env.get("MP_ACCESS_TOKEN");
    if (!accessToken) {
      return json({ error: "MP_ACCESS_TOKEN não configurado nos secrets do Supabase" }, 500);
    }

    const body = await req.json().catch(() => ({}));
    const produto = await carregarProduto(body.product_id);
    if (!produto) {
      return json({ error: "Produto inválido. Atualize o app." }, 400);
    }

    const backUrl = urlRetornoValida(body.back_url);
    const payerEmail = emailValido(body.payer_email);
    const externalReference =
      typeof body.external_reference === "string" ? body.external_reference.slice(0, 200) : undefined;

    const preference = {
      items: [
        {
          id: String(produto.id),
          title: produto.nome,
          description: produto.descricao || produto.nome,
          quantity: 1,
          unit_price: produto.preco,
          currency_id: "BRL",
        },
      ],
      payer: payerEmail ? { email: payerEmail } : undefined,
      external_reference: externalReference,
      back_urls: backUrl
        ? {
            success: backUrl,
            failure: backUrl.replace("success", "failure"),
            pending: backUrl.replace("success", "pending"),
          }
        : undefined,
      auto_return: backUrl ? "approved" : undefined,
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
      console.error("Mercado Pago erro", mpResponse.status, mpData);
      return json({ error: "Não foi possível criar o pagamento." }, 502);
    }

    return json({
      id: mpData.id,
      init_point: mpData.init_point,
      sandbox_init_point: mpData.sandbox_init_point,
    });
  } catch (error) {
    console.error("create-mp-preference", error);
    return json({ error: "Erro interno" }, 500);
  }
});
