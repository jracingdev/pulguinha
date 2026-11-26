-- Proteção das senhas — PASSO 1 de 2 (pode rodar já: não quebra nenhuma versão do app)
--
-- Problema: a política "anon_all_*" deixa qualquer pessoa com a chave pública
-- do app ler a coluna `senha` de `alunos` e `admins`, e o realtime de `alunos`
-- envia a linha inteira (com senha) para quem estiver inscrito.
--
-- Este passo só ADICIONA:
--   a) função que confere a senha antiga no servidor, sem expor a coluna;
--   b) tabela `alunos_sinal` para o realtime avisar mudanças sem dados pessoais.
--
-- Depois: publique a versão nova do app (web + Android) e só então rode o
-- PASSO 2 (migration_protege_senhas_2_bloquear.sql).

-- a) Conferência da senha legada no servidor --------------------------------
CREATE OR REPLACE FUNCTION public.conferir_senha_legada(p_tabela TEXT, p_email TEXT, p_senha TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  ok BOOLEAN := false;
BEGIN
  -- Senha vazia ou marcador de conta já migrada para o Supabase Auth nunca valem.
  IF coalesce(p_senha, '') = '' OR p_senha LIKE 'supabase_auth:%' THEN
    RETURN false;
  END IF;

  IF p_tabela = 'alunos' THEN
    SELECT EXISTS (
      SELECT 1 FROM alunos WHERE lower(email) = lower(trim(p_email)) AND senha = p_senha
    ) INTO ok;
  ELSIF p_tabela = 'admins' THEN
    SELECT EXISTS (
      SELECT 1 FROM admins WHERE lower(email) = lower(trim(p_email)) AND senha = p_senha
    ) INTO ok;
  END IF;

  -- Atraso pequeno em tentativa errada para dificultar tentativa e erro em massa.
  IF NOT ok THEN
    PERFORM pg_sleep(0.3);
  END IF;
  RETURN ok;
END;
$$;

REVOKE ALL ON FUNCTION public.conferir_senha_legada(TEXT, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.conferir_senha_legada(TEXT, TEXT, TEXT) TO anon, authenticated;

-- b) Sinal de realtime sem dados pessoais -----------------------------------
CREATE TABLE IF NOT EXISTS public.alunos_sinal (
  id SMALLINT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  atualizado_em TIMESTAMPTZ NOT NULL DEFAULT now()
);
INSERT INTO public.alunos_sinal (id) VALUES (1) ON CONFLICT (id) DO NOTHING;

ALTER TABLE public.alunos_sinal ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "le_alunos_sinal" ON public.alunos_sinal;
CREATE POLICY "le_alunos_sinal" ON public.alunos_sinal FOR SELECT TO anon, authenticated USING (true);

CREATE OR REPLACE FUNCTION public.marcar_alunos_sinal()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE alunos_sinal SET atualizado_em = now() WHERE id = 1;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_alunos_sinal ON public.alunos;
CREATE TRIGGER trg_alunos_sinal
  AFTER INSERT OR UPDATE OR DELETE ON public.alunos
  FOR EACH STATEMENT EXECUTE FUNCTION public.marcar_alunos_sinal();

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.alunos_sinal;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
