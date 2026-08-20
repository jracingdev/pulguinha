-- Tokens FCM para push remoto (alunos e admins).
ALTER TABLE alunos ADD COLUMN IF NOT EXISTS fcm_token TEXT;
ALTER TABLE admins ADD COLUMN IF NOT EXISTS fcm_token TEXT;

CREATE INDEX IF NOT EXISTS idx_alunos_fcm_token ON alunos(fcm_token) WHERE fcm_token IS NOT NULL AND fcm_token <> '';
CREATE INDEX IF NOT EXISTS idx_admins_fcm_token ON admins(fcm_token) WHERE fcm_token IS NOT NULL AND fcm_token <> '';

COMMENT ON COLUMN alunos.fcm_token IS 'Token Firebase Cloud Messaging do dispositivo do aluno';
COMMENT ON COLUMN admins.fcm_token IS 'Token Firebase Cloud Messaging do dispositivo do admin';
