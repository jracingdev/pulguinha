enum UserType { admin, aluno, publico }

class Usuario {
  const Usuario({
    required this.tipo,
    required this.nome,
    required this.email,
    this.id,
    this.telefone,
    this.plano,
    this.vencimento,
    this.status,
    this.avatar,
    this.senha,
  });

  final UserType tipo;
  final int? id;
  final String nome;
  final String email;
  final String? telefone;
  final String? plano;
  final String? vencimento;
  final String? status;
  final String? avatar;
  final String? senha;

  bool get isAdmin => tipo == UserType.admin;
  bool get isAluno => tipo == UserType.aluno;

  Usuario copyWith({
    UserType? tipo,
    int? id,
    String? nome,
    String? email,
    String? telefone,
    String? plano,
    String? vencimento,
    String? status,
    String? avatar,
    String? senha,
  }) {
    return Usuario(
      tipo: tipo ?? this.tipo,
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      plano: plano ?? this.plano,
      vencimento: vencimento ?? this.vencimento,
      status: status ?? this.status,
      avatar: avatar ?? this.avatar,
      senha: senha ?? this.senha,
    );
  }
}

class Aluno {
  const Aluno({
    required this.id,
    required this.nome,
    required this.email,
    required this.senha,
    required this.telefone,
    required this.plano,
    required this.vencimento,
    required this.status,
    required this.avatar,
  });

  final int id;
  final String nome;
  final String email;
  final String senha;
  final String telefone;
  final String plano;
  final String vencimento;
  final String status;
  final String avatar;

  Aluno copyWith({
    int? id,
    String? nome,
    String? email,
    String? senha,
    String? telefone,
    String? plano,
    String? vencimento,
    String? status,
    String? avatar,
  }) {
    return Aluno(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      senha: senha ?? this.senha,
      telefone: telefone ?? this.telefone,
      plano: plano ?? this.plano,
      vencimento: vencimento ?? this.vencimento,
      status: status ?? this.status,
      avatar: avatar ?? this.avatar,
    );
  }

  factory Aluno.fromJson(Map<String, dynamic> json) => Aluno(
        id: json['id'] as int,
        nome: json['nome'] as String,
        email: json['email'] as String,
        senha: json['senha'] as String,
        telefone: json['telefone'] as String? ?? '',
        plano: json['plano'] as String? ?? 'Mensal',
        vencimento: _formatDate(json['vencimento']),
        status: json['status'] as String? ?? 'Ativo',
        avatar: json['avatar'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'email': email,
        'senha': senha,
        'telefone': telefone,
        'plano': plano,
        'vencimento': vencimento,
        'status': status,
        'avatar': avatar,
      };

  Usuario toUsuario() => Usuario(
        tipo: UserType.aluno,
        id: id,
        nome: nome,
        email: email,
        telefone: telefone,
        plano: plano,
        vencimento: vencimento,
        status: status,
        avatar: avatar,
        senha: senha,
      );
}

class Horario {
  const Horario({
    required this.id,
    required this.hora,
    required this.dias,
    required this.capacidade,
  });

  final int id;
  final String hora;
  final String dias;
  final int capacidade;

  Horario copyWith({
    int? id,
    String? hora,
    String? dias,
    int? capacidade,
  }) {
    return Horario(
      id: id ?? this.id,
      hora: hora ?? this.hora,
      dias: dias ?? this.dias,
      capacidade: capacidade ?? this.capacidade,
    );
  }

  factory Horario.fromJson(Map<String, dynamic> json) => Horario(
        id: json['id'] as int,
        hora: json['hora'] as String,
        dias: json['dias'] as String,
        capacidade: json['capacidade'] as int,
      );

  Map<String, dynamic> toJson() => {
        'hora': hora,
        'dias': dias,
        'capacidade': capacidade,
      };
}

class Agendamento {
  const Agendamento({
    required this.id,
    required this.alunoId,
    required this.nomeAluno,
    required this.horarioId,
    required this.data,
    required this.horario,
    required this.status,
  });

  final int id;
  final int alunoId;
  final String nomeAluno;
  final int horarioId;
  final String data;
  final String horario;
  final String status;

  factory Agendamento.fromJson(Map<String, dynamic> json) => Agendamento(
        id: json['id'] as int,
        alunoId: json['aluno_id'] as int,
        nomeAluno: json['nome_aluno'] as String,
        horarioId: json['horario_id'] as int,
        data: _formatDate(json['data']),
        horario: json['horario'] as String,
        status: json['status'] as String? ?? 'Confirmado',
      );

  Map<String, dynamic> toJson() => {
        'aluno_id': alunoId,
        'nome_aluno': nomeAluno,
        'horario_id': horarioId,
        'data': data,
        'horario': horario,
        'status': status,
      };
}

class Produto {
  const Produto({
    required this.id,
    required this.nome,
    required this.desc,
    required this.preco,
    required this.tipo,
    required this.emoji,
  });

  final int id;
  final String nome;
  final String desc;
  final double preco;
  final String tipo;
  final String emoji;

  factory Produto.fromJson(Map<String, dynamic> json) => Produto(
        id: json['id'] as int,
        nome: json['nome'] as String,
        desc: json['descricao'] as String? ?? '',
        preco: (json['preco'] as num).toDouble(),
        tipo: json['tipo'] as String,
        emoji: json['emoji'] as String? ?? '📦',
      );
}

String _formatDate(dynamic value) {
  if (value is String) return value.split('T').first;
  return value.toString().split('T').first;
}
