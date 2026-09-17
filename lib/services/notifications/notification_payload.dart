enum NotificationPayloadType {
  aula,
  vencimento,
  cadastro,
  pagamento,
  aviso,
  evento,
  mencao,
}

class NotificationPayload {
  const NotificationPayload({required this.type, this.itemId, this.alunoId});

  final NotificationPayloadType type;
  final int? itemId;
  final int? alunoId;

  String encode() => '${type.name}|${itemId ?? 0}|${alunoId ?? 0}';

  static NotificationPayload? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split('|');
    if (parts.isEmpty) return null;
    final type = NotificationPayloadType.values.where((t) => t.name == parts[0]).firstOrNull;
    if (type == null) return null;
    return NotificationPayload(
      type: type,
      itemId: parts.length > 1 ? int.tryParse(parts[1]) : null,
      alunoId: parts.length > 2 ? int.tryParse(parts[2]) : null,
    );
  }

  /// Interpreta `data` de uma mensagem FCM (`type`/`tipo`/`payload`).
  static NotificationPayload? fromFcmData(Map<String, dynamic> data) {
    final decoded = decode(data['payload']?.toString());
    if (decoded != null) return decoded;
    final type = (data['type'] ?? data['tipo'] ?? '').toString().trim().toLowerCase();
    if (type.isEmpty) return null;
    if (type == 'cadastro' || type.contains('pendente')) {
      return const NotificationPayload(type: NotificationPayloadType.cadastro);
    }
    final known = NotificationPayloadType.values.where((t) => t.name == type).firstOrNull;
    if (known == null) return null;
    return NotificationPayload(type: known);
  }
}

extension _FirstOrNullNotif<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
