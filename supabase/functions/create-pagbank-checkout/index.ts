import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import {
  carregarProduto,
  corsHeaders,
  emailValido,
  json,
  urlRetornoValida,
} from "../_shared/produto.ts";

// Cria o checkout do PagBank no servidor. Secrets:
//   PAGBANK_TOKEN   – token da conta PagBank da academia
//   PAGBANK_SANDBOX – "true" para ambiente de testes
// Nome e preço vêm da tabela `produtos` pelo product_id.

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") return json({ error: "Método não permitido" }, 405);

  try {
    const token = (Deno.env.get("PAGBANK_TOKEN") ?? "").trim();
    if (!token) {
      return json({ error: "PAGBANK_TOKEN não configurado nos secrets do Supabase" }, 500);
    }
    const sandbox = (Deno.env.get("PAGBANK_SANDBOX") ?? "false").toLowerCase() === "true";
    const apiBase = sandbox ? "https://sandbox.api.pagseguro.com" : "https://api.pagseguro.com";

    const body = await req.json().catch(() => ({}));
    const produto = await carregarProduto(body.product_id);
    if (!produto) {
      return json({ error: "Produto inválido. Atualize o app." }, 400);
    }

    // Grade (tamanho) só vale se existir no cadastro do produto.
    const grade = typeof body.grade === "string" && produto.grades.includes(body.grade)
      ? body.grade
      : undefined;
    const itemName = grade ? `${produto.nome} (${grade})` : produto.nome;

    const referenceId =
      typeof body.reference_id === "string" && body.reference_id.length <= 64
        ? body.reference_id
        : `pulguinha_pb_${produto.id}_${Date.now()}`;

    const payload: Record<string, unknown> = {
      reference_id: referenceId,
      customer_modifiable: true,
      items: [
        {
          reference_id: `prod_${produto.id}`,
          name: itemName.slice(0, 100),
          description: (produto.descricao || produto.nome).slice(0, 255),
          quantity: 1,
          unit_amount: Math.round(produto.preco * 100),
        },
      ],
    };

    const redirect = urlRetornoValida(body.redirect_url);
    if (redirect && redirect.startsWith("https://")) payload.redirect_url = redirect;

    const email = emailValido(body.customer_email);
    const nome = typeof body.customer_name === "string" ? body.customer_name.trim().slice(0, 100) : "";
    if (email && nome) {
      payload.customer = { name: nome, email };
      payload.customer_modifiable = false;
    }

    const res = await fetch(`${apiBase}/checkouts`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });
    const data = await res.json();

    if (!res.ok) {
      console.error("PagBank erro", res.status, data);
      return json({ error: "Não foi possível criar o pagamento." }, 502);
    }

    return json({ id: data.id, links: data.links });
  } catch (error) {
    console.error("create-pagbank-checkout", error);
    return json({ error: "Erro interno" }, 500);
  }
});
