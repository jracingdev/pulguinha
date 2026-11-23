-- ==============================================================================
-- CREDENCIAIS DE TESTE - GOOGLE PLAY STORE REVIEW & DEMO
-- Execute este script no SQL Editor do Supabase para garantir que as credenciais
-- do revisor da Google Play e do administrador estejam ativas e funcionando.
-- ==============================================================================

-- 1. Conta de administrador: NÃO é criada/redefinida aqui.
--    Antes este script gravava a senha 'admin123' no admin real da academia.
--    Para o revisor da Google Play, crie um admin de demonstração com e-mail e
--    senha próprios pelo painel do Supabase (Auth) e troque a senha depois da
--    revisão. Nunca reutilize a senha do professor.

-- 2. Garante a conta de Aluno de Teste
INSERT INTO alunos (
    nome, 
    email, 
    senha, 
    telefone, 
    plano, 
    vencimento, 
    status, 
    avatar, 
    data_nascimento, 
    anamnese, 
    streak_presenca, 
    pulguinha_points
)
VALUES (
    'Aluno Teste Play Store',
    'aluno.teste@pulguinha.com',
    'teste123',
    '(11) 99999-0000',
    'Mensal',
    '2029-12-31'::date,
    'Ativo',
    'AT',
    '1995-01-01'::date,
    '{"objetivo_treino": "Condicionamento", "nivel_experiencia": "Iniciante"}'::jsonb,
    3,
    50
)
ON CONFLICT (email) DO UPDATE 
SET senha = 'teste123',
    status = 'Ativo',
    vencimento = '2029-12-31'::date,
    nome = 'Aluno Teste Play Store';

-- Confirmação dos registros criados/atualizados
SELECT 'ADMIN' as tipo, id, email, nome FROM admins WHERE email = 'admin@pulguinha.com'
UNION ALL
SELECT 'ALUNO' as tipo, id, email, nome FROM alunos WHERE email = 'aluno.teste@pulguinha.com';
