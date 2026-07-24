#!/usr/bin/env node
/**
 * Migração 2/3 (opção B — Admin API) — provisiona auth.users a partir de
 * alunos/admins reusando a senha atual em texto.
 *
 * Usa a Admin API oficial do Supabase, então não depende do layout interno das
 * tabelas do schema `auth`. É idempotente: perfis já vinculados são ignorados.
 *
 * Requisitos: Node 18+ (fetch nativo). Nenhuma dependência externa.
 *
 * A service_role key NUNCA deve ir para o app nem para o git — passe por
 * variável de ambiente, apenas nesta execução local:
 *
 *   PowerShell:
 *     $env:SUPABASE_URL="https://xxxx.supabase.co"
 *     $env:SUPABASE_SERVICE_ROLE_KEY="<service_role>"
 *     node supabase/scripts/provisionar_auth_users.mjs --dry-run
 *     node supabase/scripts/provisionar_auth_users.mjs
 *
 *   bash:
 *     SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... node supabase/scripts/provisionar_auth_users.mjs
 */

const url = (process.env.SUPABASE_URL || '').replace(/\/+$/, '');
const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || '';
const dryRun = process.argv.includes('--dry-run');

if (!url || !serviceKey) {
  console.error('Defina SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY no ambiente.');
  process.exit(1);
}

const headers = {
  apikey: serviceKey,
  Authorization: `Bearer ${serviceKey}`,
  'Content-Type': 'application/json',
};

const emailValido = (email) => /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email);

async function rest(caminho, init = {}) {
  const resp = await fetch(`${url}/rest/v1/${caminho}`, { ...init, headers });
  if (!resp.ok) throw new Error(`${caminho}: ${resp.status} ${await resp.text()}`);
  return resp.status === 204 ? null : resp.json();
}

async function criarConta(email, senha, metadata) {
  const resp = await fetch(`${url}/auth/v1/admin/users`, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      email,
      password: senha,
      email_confirm: true,
      user_metadata: metadata,
    }),
  });
  const corpo = await resp.json().catch(() => ({}));
  if (resp.ok) return corpo.id;
  // Conta já existente: recupera o id para completar o vínculo.
  const jaExiste = resp.status === 422 || /already.*registered|already exists/i.test(JSON.stringify(corpo));
  if (jaExiste) return buscarContaPorEmail(email);
  throw new Error(`criarConta(${email}): ${resp.status} ${JSON.stringify(corpo)}`);
}

async function buscarContaPorEmail(email) {
  const resp = await fetch(
    `${url}/auth/v1/admin/users?filter=${encodeURIComponent(email)}&per_page=1`,
    { headers },
  );
  if (!resp.ok) return null;
  const corpo = await resp.json();
  const achado = (corpo.users || []).find((u) => (u.email || '').toLowerCase() === email);
  return achado ? achado.id : null;
}

async function migrarTabela(tabela, perfil) {
  const registros = await rest(
    `${tabela}?select=id,nome,email,senha,auth_user_id&auth_user_id=is.null`,
  );
  console.log(`\n${tabela}: ${registros.length} perfil(is) sem conta no Auth.`);

  const resumo = { criados: 0, vinculados: 0, ignorados: 0, falhas: 0 };

  for (const registro of registros) {
    const email = (registro.email || '').trim().toLowerCase();
    const senha = registro.senha || '';

    if (!emailValido(email) || senha.length === 0) {
      console.warn(`  ignorado (e-mail/senha inválidos): ${registro.email}`);
      resumo.ignorados += 1;
      continue;
    }

    if (dryRun) {
      console.log(`  [dry-run] criaria conta para ${email}`);
      resumo.criados += 1;
      continue;
    }

    try {
      const authUserId = await criarConta(email, senha, { nome: registro.nome, perfil });
      if (!authUserId) {
        console.warn(`  sem id retornado para ${email}`);
        resumo.falhas += 1;
        continue;
      }
      await rest(`${tabela}?id=eq.${registro.id}`, {
        method: 'PATCH',
        body: JSON.stringify({ auth_user_id: authUserId }),
      });
      resumo.criados += 1;
      console.log(`  ok ${email}`);
    } catch (e) {
      resumo.falhas += 1;
      console.error(`  falha ${email}: ${e.message}`);
    }
  }

  return resumo;
}

const alunos = await migrarTabela('alunos', 'aluno');
const admins = await migrarTabela('admins', 'admin');

console.log('\nResumo:');
console.log('  alunos:', alunos);
console.log('  admins:', admins);
if (dryRun) console.log('\nNada foi gravado (--dry-run).');
