-- ==============================================================================
-- CREDENCIAIS DE TESTE - GOOGLE PLAY STORE REVIEW & DEMO
-- Execute este script no SQL Editor do Supabase para garantir que as credenciais
-- do revisor da Google Play e do administrador estejam ativas e funcionando.
-- ==============================================================================

-- 1. Garante a conta de Administrador / Instrutor
INSERT INTO admins (email, senha, nome)
VALUES ('admin@pulguinha.com', 'admin123', 'Pulguinha Admin')
ON CONFLICT (email) DO UPDATE 
SET senha = 'admin123',
    nome = 'Pulguinha Admin';

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
