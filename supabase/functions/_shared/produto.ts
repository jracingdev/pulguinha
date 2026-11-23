// Produto e preço sempre lidos do banco pelo servidor: o app só informa o id.
// Assim ninguém consegue gerar um checkout com preço alterado.
import { serviceClient } from "./wellhub.ts";

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

export function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

export type ProdutoServidor = {
  id: number;
  nome: string;
  descricao: string;
  preco: number;
  grades: string[];
};

export async function carregarProduto(productId: unknown): Promise<ProdutoServidor | null> {
  const id = Number(productId);
  if (!Number.isInteger(id) || id <= 0) return null;

  const { data, error } = await serviceClient()
    .from("produtos")
    .select("id,nome,descricao,preco,grades")
    .eq("id", id)
    .maybeSingle();
  if (error || !data) return null;

  const preco = Number(data.preco);
  if (!Number.isFinite(preco) || preco <= 0) return null;

  const grades = Array.isArray(data.grades) ? data.grades.map((g: unknown) => String(g)) : [];
  return {
    id: data.id,
    nome: String(data.nome ?? ""),
    descricao: String(data.descricao ?? ""),
    preco,
    grades,
  };
}

/** Aceita só e-mail com formato válido (evita repassar lixo ao gateway). */
export function emailValido(value: unknown): string | undefined {
  const v = typeof value === "string" ? value.trim() : "";
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v) && v.length <= 254 ? v : undefined;
}

/** Só aceita URL de retorno https ou o deep link do app. */
export function urlRetornoValida(value: unknown): string | undefined {
  const v = typeof value === "string" ? value.trim() : "";
  if (v.startsWith("pulguinha://")) return v;
  try {
    const u = new URL(v);
    return u.protocol === "https:" ? v : undefined;
  } catch {
    return undefined;
  }
}
