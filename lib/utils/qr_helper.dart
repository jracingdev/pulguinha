import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Gera e valida payloads QR do Pulguinha.
class QrHelper {
  static const _secret = 'pulguinha2026';

  static String hashAluno(int alunoId) {
    final bytes = utf8.encode('$_secret:$alunoId');
    return sha256.convert(bytes).toString().substring(0, 12);
  }

  /// QR pessoal do aluno: pulguinha:aluno:{id}:{hash}
  static String payloadAluno(int alunoId) => 'pulguinha:aluno:$alunoId:${hashAluno(alunoId)}';

  /// QR de aula: pulguinha:aula:{horarioId}:{dataISO}
  static String payloadAula(int horarioId, String dataIso) => 'pulguinha:aula:$horarioId:$dataIso';

  /// QR do dia (todas as aulas): pulguinha:dia:{dataISO}
  static String payloadDia(String dataIso) => 'pulguinha:dia:$dataIso';

  static QrParseResult? parse(String raw) {
    final trimmed = raw.trim();
    if (!trimmed.startsWith('pulguinha:')) return null;
    final parts = trimmed.split(':');
    if (parts.length < 3) return null;

    switch (parts[1]) {
      case 'aluno':
        if (parts.length < 4) return null;
        final id = int.tryParse(parts[2]);
        if (id == null) return null;
        if (parts[3] != hashAluno(id)) return null;
        return QrParseResult.aluno(id);
      case 'aula':
        if (parts.length < 4) return null;
        final horarioId = int.tryParse(parts[2]);
        if (horarioId == null) return null;
        return QrParseResult.aula(horarioId, parts[3]);
      case 'dia':
        if (parts.length < 3) return null;
        return QrParseResult.dia(parts[2]);
      default:
        return null;
    }
  }
}

sealed class QrParseResult {
  const QrParseResult();

  factory QrParseResult.aluno(int alunoId) = QrAluno;
  factory QrParseResult.aula(int horarioId, String data) = QrAula;
  factory QrParseResult.dia(String data) = QrDia;
}

class QrAluno extends QrParseResult {
  const QrAluno(this.alunoId);
  final int alunoId;
}

class QrAula extends QrParseResult {
  const QrAula(this.horarioId, this.data);
  final int horarioId;
  final String data;
}

class QrDia extends QrParseResult {
  const QrDia(this.data);
  final String data;
}
