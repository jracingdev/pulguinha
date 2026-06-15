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
    this.dataNascimento,
    this.foto,
    this.streakPresenca,
    this.pulguinhaPoints,
    this.horarioId,
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
  final String? dataNascimento;
  final String? foto;
  final int? streakPresenca;
  final int? pulguinhaPoints;
  final int? horarioId;

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
    String? dataNascimento,
    String? foto,
    int? streakPresenca,
    int? pulguinhaPoints,
    int? horarioId,
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
      dataNascimento: dataNascimento ?? this.dataNascimento,
      foto: foto ?? this.foto,
      streakPresenca: streakPresenca ?? this.streakPresenca,
      pulguinhaPoints: pulguinhaPoints ?? this.pulguinhaPoints,
      horarioId: horarioId ?? this.horarioId,
    );
  }
}

class Anamnese {
  const Anamnese({
    this.restricoesMedicas = '',
    this.medicamentos = '',
    this.objetivoTreino = '',
    this.nivelExperiencia = 'Iniciante',
    this.contatoEmergencia = '',
    this.telefoneEmergencia = '',
  });

  final String restricoesMedicas;
  final String medicamentos;
  final String objetivoTreino;
  final String nivelExperiencia;
  final String contatoEmergencia;
  final String telefoneEmergencia;

  bool get isEmpty =>
      restricoesMedicas.isEmpty &&
      medicamentos.isEmpty &&
      objetivoTreino.isEmpty &&
      contatoEmergencia.isEmpty &&
      telefoneEmergencia.isEmpty;

  Anamnese copyWith({
    String? restricoesMedicas,
    String? medicamentos,
    String? objetivoTreino,
    String? nivelExperiencia,
    String? contatoEmergencia,
    String? telefoneEmergencia,
  }) {
    return Anamnese(
      restricoesMedicas: restricoesMedicas ?? this.restricoesMedicas,
      medicamentos: medicamentos ?? this.medicamentos,
      objetivoTreino: objetivoTreino ?? this.objetivoTreino,
      nivelExperiencia: nivelExperiencia ?? this.nivelExperiencia,
      contatoEmergencia: contatoEmergencia ?? this.contatoEmergencia,
      telefoneEmergencia: telefoneEmergencia ?? this.telefoneEmergencia,
    );
  }

  factory Anamnese.fromJson(dynamic json) {
    if (json == null) return const Anamnese();
    final map = json is Map ? Map<String, dynamic>.from(json) : <String, dynamic>{};
    return Anamnese(
      restricoesMedicas: map['restricoes_medicas'] as String? ?? map['restricoesMedicas'] as String? ?? '',
      medicamentos: map['medicamentos'] as String? ?? '',
      objetivoTreino: map['objetivo_treino'] as String? ?? map['objetivoTreino'] as String? ?? '',
      nivelExperiencia: map['nivel_experiencia'] as String? ?? map['nivelExperiencia'] as String? ?? 'Iniciante',
      contatoEmergencia: map['contato_emergencia'] as String? ?? map['contatoEmergencia'] as String? ?? '',
      telefoneEmergencia: map['telefone_emergencia'] as String? ?? map['telefoneEmergencia'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'restricoes_medicas': restricoesMedicas,
        'medicamentos': medicamentos,
        'objetivo_treino': objetivoTreino,
        'nivel_experiencia': nivelExperiencia,
        'contato_emergencia': contatoEmergencia,
        'telefone_emergencia': telefoneEmergencia,
      };
}

enum TipoPresenca { scanProfessor, scanAluno }

extension TipoPresencaX on TipoPresenca {
  String get dbValue => this == TipoPresenca.scanProfessor ? 'scan_professor' : 'scan_aluno';

  static TipoPresenca fromDb(String? v) =>
      v == 'scan_aluno' ? TipoPresenca.scanAluno : TipoPresenca.scanProfessor;
}

class Presenca {
  const Presenca({
    required this.id,
    required this.alunoId,
    required this.horarioId,
    required this.data,
    required this.horario,
    required this.timestamp,
    required this.tipo,
    this.nomeAluno,
  });

  final int id;
  final int alunoId;
  final int horarioId;
  final String data;
  final String horario;
  final DateTime timestamp;
  final TipoPresenca tipo;
  final String? nomeAluno;

  factory Presenca.fromJson(Map<String, dynamic> json) => Presenca(
        id: json['id'] as int,
        alunoId: json['aluno_id'] as int,
        horarioId: json['horario_id'] as int,
        data: _formatDate(json['data']),
        horario: json['horario'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String? ?? json['created_at'] as String? ?? DateTime.now().toIso8601String()),
        tipo: TipoPresencaX.fromDb(json['tipo'] as String?),
        nomeAluno: json['nome_aluno'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'aluno_id': alunoId,
        'horario_id': horarioId,
        'data': data,
        'horario': horario,
        'timestamp': timestamp.toIso8601String(),
        'tipo': tipo.dbValue,
        if (nomeAluno != null) 'nome_aluno': nomeAluno,
      };
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
    this.dataNascimento,
    this.anamnese = const Anamnese(),
    this.foto,
    this.streakPresenca = 0,
    this.pulguinhaPoints = 0,
    this.dataCadastro,
    this.horarioId,
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
  final String? dataNascimento;
  final Anamnese anamnese;
  final String? foto;
  final int streakPresenca;
  final int pulguinhaPoints;
  final String? dataCadastro;
  final int? horarioId;

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
    String? dataNascimento,
    Anamnese? anamnese,
    String? foto,
    int? streakPresenca,
    int? pulguinhaPoints,
    String? dataCadastro,
    int? horarioId,
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
      dataNascimento: dataNascimento ?? this.dataNascimento,
      anamnese: anamnese ?? this.anamnese,
      foto: foto ?? this.foto,
      streakPresenca: streakPresenca ?? this.streakPresenca,
      pulguinhaPoints: pulguinhaPoints ?? this.pulguinhaPoints,
      dataCadastro: dataCadastro ?? this.dataCadastro,
      horarioId: horarioId ?? this.horarioId,
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
        dataNascimento: json['data_nascimento'] != null ? _formatDate(json['data_nascimento']) : null,
        anamnese: Anamnese.fromJson(json['anamnese']),
        foto: json['foto'] as String?,
        streakPresenca: json['streak_presenca'] as int? ?? 0,
        pulguinhaPoints: json['pulguinha_points'] as int? ?? 0,
        dataCadastro: json['data_cadastro'] != null ? _formatDate(json['data_cadastro']) : null,
        horarioId: json['horario_id'] as int?,
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
        if (dataNascimento != null) 'data_nascimento': dataNascimento,
        'anamnese': anamnese.toJson(),
        if (foto != null && foto!.isNotEmpty) 'foto': foto,
        'streak_presenca': streakPresenca,
        'pulguinha_points': pulguinhaPoints,
        if (dataCadastro != null) 'data_cadastro': dataCadastro,
        if (horarioId != null) 'horario_id': horarioId,
      };

  /// Payload para INSERT — nunca envia `id` (BIGSERIAL no Postgres).
  Map<String, dynamic> toInsertJson() => toJson();

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
        dataNascimento: dataNascimento,
        foto: foto,
        streakPresenca: streakPresenca,
        pulguinhaPoints: pulguinhaPoints,
        horarioId: horarioId,
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
    this.foto,
    this.grades = const [],
  });

  final int id;
  final String nome;
  final String desc;
  final double preco;
  final String tipo;
  final String emoji;
  final String? foto;
  final List<String> grades;

  Produto copyWith({
    int? id,
    String? nome,
    String? desc,
    double? preco,
    String? tipo,
    String? emoji,
    String? foto,
    List<String>? grades,
  }) {
    return Produto(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      desc: desc ?? this.desc,
      preco: preco ?? this.preco,
      tipo: tipo ?? this.tipo,
      emoji: emoji ?? this.emoji,
      foto: foto ?? this.foto,
      grades: grades ?? this.grades,
    );
  }

  factory Produto.fromJson(Map<String, dynamic> json) {
    final rawGrades = json['grades'];
    List<String> grades = const [];
    if (rawGrades is List) {
      grades = rawGrades.map((e) => e.toString()).toList();
    } else if (rawGrades is String && rawGrades.isNotEmpty) {
      grades = rawGrades.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return Produto(
      id: json['id'] as int,
      nome: json['nome'] as String,
      desc: json['descricao'] as String? ?? '',
      preco: (json['preco'] as num).toDouble(),
      tipo: json['tipo'] as String,
      emoji: json['emoji'] as String? ?? '📦',
      foto: json['foto'] as String?,
      grades: grades,
    );
  }

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'descricao': desc,
        'preco': preco,
        'tipo': tipo,
        'emoji': emoji,
        if (foto != null && foto!.isNotEmpty) 'foto': foto,
        'grades': grades,
      };
}

class ComentarioTurma {
  const ComentarioTurma({
    required this.id,
    required this.alunoId,
    required this.nomeAluno,
    required this.texto,
    required this.dataHora,
  });

  final int id;
  final int alunoId;
  final String nomeAluno;
  final String texto;
  final DateTime dataHora;

  factory ComentarioTurma.fromJson(Map<String, dynamic> json) => ComentarioTurma(
        id: json['id'] as int,
        alunoId: json['aluno_id'] as int,
        nomeAluno: json['nome_aluno'] as String,
        texto: json['texto'] as String,
        dataHora: DateTime.parse(json['data_hora'] as String),
      );

  Map<String, dynamic> toJson() => {
        'aluno_id': alunoId,
        'nome_aluno': nomeAluno,
        'texto': texto,
        'data_hora': dataHora.toIso8601String(),
      };
}

enum TipoPostTurma { texto, figurinha, enquete, link }

class PostTurma {
  const PostTurma({
    required this.id,
    required this.alunoId,
    required this.nomeAluno,
    required this.horarioId,
    required this.texto,
    required this.dataHora,
    this.tipo = TipoPostTurma.texto,
    this.figurinha,
    this.linkUrl,
    this.enqueteOpcoes = const [],
    this.enqueteVotos = const {},
    this.reacoes = const [],
    this.comentarios = const [],
  });

  final int id;
  final int alunoId;
  final String nomeAluno;
  final int horarioId;
  final String texto;
  final DateTime dataHora;
  final TipoPostTurma tipo;
  final String? figurinha;
  final String? linkUrl;
  final List<String> enqueteOpcoes;
  final Map<String, int> enqueteVotos;
  final List<int> reacoes;
  final List<ComentarioTurma> comentarios;

  int get totalReacoes => reacoes.length;
  bool reagiuPor(int alunoId) => reacoes.contains(alunoId);
  int? votoDoAluno(int alunoId) => enqueteVotos['$alunoId'];

  PostTurma copyWith({
    int? id,
    int? alunoId,
    String? nomeAluno,
    int? horarioId,
    String? texto,
    DateTime? dataHora,
    TipoPostTurma? tipo,
    String? figurinha,
    String? linkUrl,
    List<String>? enqueteOpcoes,
    Map<String, int>? enqueteVotos,
    List<int>? reacoes,
    List<ComentarioTurma>? comentarios,
  }) {
    return PostTurma(
      id: id ?? this.id,
      alunoId: alunoId ?? this.alunoId,
      nomeAluno: nomeAluno ?? this.nomeAluno,
      horarioId: horarioId ?? this.horarioId,
      texto: texto ?? this.texto,
      dataHora: dataHora ?? this.dataHora,
      tipo: tipo ?? this.tipo,
      figurinha: figurinha ?? this.figurinha,
      linkUrl: linkUrl ?? this.linkUrl,
      enqueteOpcoes: enqueteOpcoes ?? this.enqueteOpcoes,
      enqueteVotos: enqueteVotos ?? this.enqueteVotos,
      reacoes: reacoes ?? this.reacoes,
      comentarios: comentarios ?? this.comentarios,
    );
  }

  static TipoPostTurma _tipoFrom(String? raw) {
    return switch (raw) {
      'figurinha' => TipoPostTurma.figurinha,
      'enquete' => TipoPostTurma.enquete,
      'link' => TipoPostTurma.link,
      _ => TipoPostTurma.texto,
    };
  }

  static String _tipoTo(TipoPostTurma tipo) {
    return switch (tipo) {
      TipoPostTurma.figurinha => 'figurinha',
      TipoPostTurma.enquete => 'enquete',
      TipoPostTurma.link => 'link',
      TipoPostTurma.texto => 'texto',
    };
  }

  factory PostTurma.fromJson(Map<String, dynamic> json) {
    final rawReacoes = json['reacoes'];
    final rawComentarios = json['comentarios'];
    final rawOpcoes = json['enquete_opcoes'];
    final rawVotos = json['enquete_votos'];
    Map<String, int> votos = {};
    if (rawVotos is Map) {
      votos = rawVotos.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
    }
    return PostTurma(
      id: json['id'] as int,
      alunoId: json['aluno_id'] as int,
      nomeAluno: json['nome_aluno'] as String,
      horarioId: json['horario_id'] as int,
      texto: json['texto'] as String? ?? '',
      dataHora: DateTime.parse(json['data_hora'] as String),
      tipo: _tipoFrom(json['tipo'] as String?),
      figurinha: json['figurinha'] as String?,
      linkUrl: json['link_url'] as String?,
      enqueteOpcoes: rawOpcoes is List ? rawOpcoes.map((e) => e.toString()).toList() : const [],
      enqueteVotos: votos,
      reacoes: rawReacoes is List ? rawReacoes.map((e) => (e as num).toInt()).toList() : const [],
      comentarios: rawComentarios is List
          ? rawComentarios.map((c) => ComentarioTurma.fromJson(Map<String, dynamic>.from(c as Map))).toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'aluno_id': alunoId,
        'nome_aluno': nomeAluno,
        'horario_id': horarioId,
        'texto': texto,
        'data_hora': dataHora.toIso8601String(),
        'tipo': _tipoTo(tipo),
        if (figurinha != null) 'figurinha': figurinha,
        if (linkUrl != null) 'link_url': linkUrl,
        'enquete_opcoes': enqueteOpcoes,
        'enquete_votos': enqueteVotos,
        'reacoes': reacoes,
        'comentarios': comentarios.map((c) => c.toJson()).toList(),
      };
}

String _formatDate(dynamic value) {
  if (value is String) return value.split('T').first;
  return value.toString().split('T').first;
}
