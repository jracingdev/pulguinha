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
        id: _jsonInt(json['id']),
        alunoId: _jsonInt(json['aluno_id']),
        horarioId: _jsonInt(json['horario_id']),
        data: _formatDate(json['data']),
        horario: json['horario'] as String? ?? '',
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
    this.alunoDesde,
    this.horarioId,
    this.cep = '',
    this.logradouro = '',
    this.numero = '',
    this.complemento = '',
    this.bairro = '',
    this.cidade = '',
    this.uf = '',
    this.codigoIndicacao = '',
    this.creditoIndicacao = 0,
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
  final String? alunoDesde;
  final int? horarioId;
  final String cep;
  final String logradouro;
  final String numero;
  final String complemento;
  final String bairro;
  final String cidade;
  final String uf;
  /// Código único que o aluno pode compartilhar para o programa "Indique e Ganhe".
  final String codigoIndicacao;
  /// Crédito acumulado por indicações convertidas (R\$).
  final double creditoIndicacao;

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
    String? alunoDesde,
    int? horarioId,
    String? cep,
    String? logradouro,
    String? numero,
    String? complemento,
    String? bairro,
    String? cidade,
    String? uf,
    String? codigoIndicacao,
    double? creditoIndicacao,
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
      alunoDesde: alunoDesde ?? this.alunoDesde,
      horarioId: horarioId ?? this.horarioId,
      cep: cep ?? this.cep,
      logradouro: logradouro ?? this.logradouro,
      numero: numero ?? this.numero,
      complemento: complemento ?? this.complemento,
      bairro: bairro ?? this.bairro,
      cidade: cidade ?? this.cidade,
      uf: uf ?? this.uf,
      codigoIndicacao: codigoIndicacao ?? this.codigoIndicacao,
      creditoIndicacao: creditoIndicacao ?? this.creditoIndicacao,
    );
  }

  factory Aluno.fromJson(Map<String, dynamic> json) => Aluno(
        id: _jsonInt(json['id']),
        nome: json['nome'] as String? ?? '',
        email: json['email'] as String? ?? '',
        senha: json['senha'] as String? ?? '',
        telefone: json['telefone'] as String? ?? '',
        plano: json['plano'] as String? ?? 'Mensal',
        vencimento: _formatDate(json['vencimento']),
        status: json['status'] as String? ?? 'Ativo',
        avatar: json['avatar'] as String? ?? '',
        dataNascimento: json['data_nascimento'] != null ? _formatDate(json['data_nascimento']) : null,
        anamnese: Anamnese.fromJson(json['anamnese']),
        foto: json['foto'] as String?,
        streakPresenca: _jsonInt(json['streak_presenca']),
        pulguinhaPoints: _jsonInt(json['pulguinha_points']),
        dataCadastro: json['data_cadastro'] != null ? _formatDate(json['data_cadastro']) : null,
        alunoDesde: json['aluno_desde'] != null
            ? _formatDate(json['aluno_desde'])
            : json['data_cadastro'] != null
                ? _formatDate(json['data_cadastro'])
                : null,
        horarioId: _jsonIntOrNull(json['horario_id']),
        cep: json['cep'] as String? ?? '',
        logradouro: json['logradouro'] as String? ?? '',
        numero: json['numero'] as String? ?? '',
        complemento: json['complemento'] as String? ?? '',
        bairro: json['bairro'] as String? ?? '',
        cidade: json['cidade'] as String? ?? '',
        uf: json['uf'] as String? ?? '',
        codigoIndicacao: (json['codigo_indicacao'] as String?) ?? '',
        creditoIndicacao: _jsonDouble(json['credito_indicacao']),
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
        if (alunoDesde != null) 'aluno_desde': alunoDesde,
        if (horarioId != null) 'horario_id': horarioId,
        'cep': cep,
        'logradouro': logradouro,
        'numero': numero,
        'complemento': complemento,
        'bairro': bairro,
        'cidade': cidade,
        'uf': uf,
        if (codigoIndicacao.isNotEmpty) 'codigo_indicacao': codigoIndicacao,
        if (creditoIndicacao > 0) 'credito_indicacao': creditoIndicacao,
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

/// Registro de indicação entre alunos (programa Indique e Ganhe).
class Indicacao {
  const Indicacao({
    required this.id,
    required this.indicadorId,
    required this.indicadoId,
    required this.codigoUsado,
    this.status = 'pendente',
    required this.dataCriacao,
    this.dataConversao,
  });

  final int id;
  final int indicadorId;
  final int indicadoId;
  final String codigoUsado;
  /// pendente | convertida | cancelada
  final String status;
  final String dataCriacao;
  final String? dataConversao;

  Indicacao copyWith({
    int? id,
    int? indicadorId,
    int? indicadoId,
    String? codigoUsado,
    String? status,
    String? dataCriacao,
    String? dataConversao,
  }) {
    return Indicacao(
      id: id ?? this.id,
      indicadorId: indicadorId ?? this.indicadorId,
      indicadoId: indicadoId ?? this.indicadoId,
      codigoUsado: codigoUsado ?? this.codigoUsado,
      status: status ?? this.status,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataConversao: dataConversao ?? this.dataConversao,
    );
  }

  factory Indicacao.fromJson(Map<String, dynamic> json) => Indicacao(
        id: _jsonInt(json['id']),
        indicadorId: _jsonInt(json['indicador_id']),
        indicadoId: _jsonInt(json['indicado_id']),
        codigoUsado: json['codigo_usado'] as String? ?? '',
        status: json['status'] as String? ?? 'pendente',
        dataCriacao: _formatDate(json['data_criacao']),
        dataConversao: json['data_conversao'] != null ? _formatDate(json['data_conversao']) : null,
      );

  Map<String, dynamic> toJson() => {
        'indicador_id': indicadorId,
        'indicado_id': indicadoId,
        'codigo_usado': codigoUsado,
        'status': status,
        'data_criacao': dataCriacao,
        if (dataConversao != null) 'data_conversao': dataConversao,
      };
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
        id: _jsonInt(json['id']),
        hora: json['hora'] as String? ?? '',
        dias: json['dias'] as String? ?? '',
        capacidade: _jsonInt(json['capacidade'], fallback: 12),
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
    this.alunoId,
    required this.nomeAluno,
    required this.horarioId,
    required this.data,
    required this.horario,
    required this.status,
  });

  final int id;
  final int? alunoId;
  final String nomeAluno;
  final int horarioId;
  final String data;
  final String horario;
  final String status;

  factory Agendamento.fromJson(Map<String, dynamic> json) => Agendamento(
        id: _jsonInt(json['id']),
        alunoId: _jsonIntOrNull(json['aluno_id']),
        nomeAluno: json['nome_aluno'] as String? ?? 'Aluno',
        horarioId: _jsonInt(json['horario_id']),
        data: _formatDate(json['data']),
        horario: json['horario'] as String? ?? '',
        status: json['status'] as String? ?? 'Confirmado',
      );

  Map<String, dynamic> toJson() => {
        if (alunoId != null) 'aluno_id': alunoId,
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
      id: _jsonInt(json['id']),
      nome: json['nome'] as String? ?? '',
      desc: json['descricao'] as String? ?? '',
      preco: _jsonDouble(json['preco']),
      tipo: json['tipo'] as String? ?? 'produto',
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
        id: _jsonInt(json['id']),
        alunoId: _jsonInt(json['aluno_id']),
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

enum AutorPostTurma { aluno, admin }

class PostTurma {
  const PostTurma({
    required this.id,
    required this.alunoId,
    required this.nomeAluno,
    required this.horarioId,
    required this.texto,
    required this.dataHora,
    this.tipo = TipoPostTurma.texto,
    this.autorTipo = AutorPostTurma.aluno,
    this.oculto = false,
    this.fixado = false,
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
  final AutorPostTurma autorTipo;
  final bool oculto;
  final bool fixado;
  final String? figurinha;
  final String? linkUrl;
  final List<String> enqueteOpcoes;
  final Map<String, int> enqueteVotos;
  final List<int> reacoes;
  final List<ComentarioTurma> comentarios;

  int get totalReacoes => reacoes.length;
  bool reagiuPor(int alunoId) => reacoes.contains(alunoId);
  int? votoDoAluno(int alunoId) => enqueteVotos['$alunoId'];
  bool get isAdminPost => autorTipo == AutorPostTurma.admin;

  PostTurma copyWith({
    int? id,
    int? alunoId,
    String? nomeAluno,
    int? horarioId,
    String? texto,
    DateTime? dataHora,
    TipoPostTurma? tipo,
    AutorPostTurma? autorTipo,
    bool? oculto,
    bool? fixado,
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
      autorTipo: autorTipo ?? this.autorTipo,
      oculto: oculto ?? this.oculto,
      fixado: fixado ?? this.fixado,
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

  static AutorPostTurma _autorFrom(String? raw) =>
      raw == 'admin' ? AutorPostTurma.admin : AutorPostTurma.aluno;

  static String _autorTo(AutorPostTurma tipo) =>
      tipo == AutorPostTurma.admin ? 'admin' : 'aluno';

  factory PostTurma.fromJson(Map<String, dynamic> json) {
    final rawReacoes = json['reacoes'];
    final rawComentarios = json['comentarios'];
    final rawOpcoes = json['enquete_opcoes'];
    final rawVotos = json['enquete_votos'];
    Map<String, int> votos = {};
    if (rawVotos is Map) {
      votos = rawVotos.map((k, v) => MapEntry(k.toString(), _jsonInt(v)));
    }
    return PostTurma(
      id: _jsonInt(json['id']),
      alunoId: _jsonInt(json['aluno_id']),
      nomeAluno: json['nome_aluno'] as String? ?? '',
      horarioId: _jsonInt(json['horario_id']),
      texto: json['texto'] as String? ?? '',
      dataHora: DateTime.parse(json['data_hora'] as String),
      tipo: _tipoFrom(json['tipo'] as String?),
      autorTipo: _autorFrom(json['autor_tipo'] as String?),
      oculto: json['oculto'] as bool? ?? false,
      fixado: json['fixado'] as bool? ?? false,
      figurinha: json['figurinha'] as String?,
      linkUrl: json['link_url'] as String?,
      enqueteOpcoes: rawOpcoes is List ? rawOpcoes.map((e) => e.toString()).toList() : const [],
      enqueteVotos: votos,
      reacoes: rawReacoes is List ? rawReacoes.where((e) => e != null).map((e) => _jsonInt(e)).toList() : const [],
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
        'autor_tipo': _autorTo(autorTipo),
        'oculto': oculto,
        'fixado': fixado,
        if (figurinha != null) 'figurinha': figurinha,
        if (linkUrl != null) 'link_url': linkUrl,
        'enquete_opcoes': enqueteOpcoes,
        'enquete_votos': enqueteVotos,
        'reacoes': reacoes,
        'comentarios': comentarios.map((c) => c.toJson()).toList(),
      };
}

class Aviso {
  const Aviso({
    required this.id,
    required this.titulo,
    required this.texto,
    required this.autor,
    required this.dataHora,
    this.mencoes = const [],
    this.notificarTodos = true,
    this.fixado = false,
    this.ativo = true,
  });

  final int id;
  final String titulo;
  final String texto;
  final String autor;
  final DateTime dataHora;
  final List<int> mencoes;
  final bool notificarTodos;
  final bool fixado;
  final bool ativo;

  Aviso copyWith({
    int? id,
    String? titulo,
    String? texto,
    String? autor,
    DateTime? dataHora,
    List<int>? mencoes,
    bool? notificarTodos,
    bool? fixado,
    bool? ativo,
  }) {
    return Aviso(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      texto: texto ?? this.texto,
      autor: autor ?? this.autor,
      dataHora: dataHora ?? this.dataHora,
      mencoes: mencoes ?? this.mencoes,
      notificarTodos: notificarTodos ?? this.notificarTodos,
      fixado: fixado ?? this.fixado,
      ativo: ativo ?? this.ativo,
    );
  }

  factory Aviso.fromJson(Map<String, dynamic> json) => Aviso(
        id: _jsonInt(json['id']),
        titulo: json['titulo'] as String,
        texto: json['texto'] as String,
        autor: json['autor'] as String? ?? 'Admin',
        dataHora: DateTime.parse(json['data_hora'] as String),
        mencoes: _parseBigIntArray(json['mencoes']),
        notificarTodos: json['notificar_todos'] as bool? ?? true,
        fixado: json['fixado'] as bool? ?? false,
        ativo: json['ativo'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'texto': texto,
        'autor': autor,
        'data_hora': dataHora.toIso8601String(),
        'mencoes': mencoes,
        'notificar_todos': notificarTodos,
        'fixado': fixado,
        'ativo': ativo,
      };
}

class EventoEstudio {
  const EventoEstudio({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.dataInicio,
    this.dataFim,
    this.local,
    this.mencoes = const [],
    this.notificarTodos = true,
    this.lembreteDiasAntes = 1,
    this.ativo = true,
    this.criadoEm,
  });

  final int id;
  final String titulo;
  final String descricao;
  final DateTime dataInicio;
  final DateTime? dataFim;
  final String? local;
  final List<int> mencoes;
  final bool notificarTodos;
  final int lembreteDiasAntes;
  final bool ativo;
  final DateTime? criadoEm;

  EventoEstudio copyWith({
    int? id,
    String? titulo,
    String? descricao,
    DateTime? dataInicio,
    DateTime? dataFim,
    String? local,
    List<int>? mencoes,
    bool? notificarTodos,
    int? lembreteDiasAntes,
    bool? ativo,
    DateTime? criadoEm,
  }) {
    return EventoEstudio(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      local: local ?? this.local,
      mencoes: mencoes ?? this.mencoes,
      notificarTodos: notificarTodos ?? this.notificarTodos,
      lembreteDiasAntes: lembreteDiasAntes ?? this.lembreteDiasAntes,
      ativo: ativo ?? this.ativo,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }

  factory EventoEstudio.fromJson(Map<String, dynamic> json) => EventoEstudio(
        id: _jsonInt(json['id']),
        titulo: json['titulo'] as String? ?? '',
        descricao: json['descricao'] as String? ?? '',
        dataInicio: DateTime.parse(json['data_inicio'] as String),
        dataFim: json['data_fim'] != null ? DateTime.parse(json['data_fim'] as String) : null,
        local: json['local'] as String?,
        mencoes: _parseBigIntArray(json['mencoes']),
        notificarTodos: json['notificar_todos'] as bool? ?? true,
        lembreteDiasAntes: _jsonInt(json['lembrete_dias_antes'], fallback: 1),
        ativo: json['ativo'] as bool? ?? true,
        criadoEm: json['criado_em'] != null ? DateTime.parse(json['criado_em'] as String) : null,
      );

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'descricao': descricao,
        'data_inicio': dataInicio.toIso8601String(),
        if (dataFim != null) 'data_fim': dataFim!.toIso8601String(),
        if (local != null && local!.isNotEmpty) 'local': local,
        'mencoes': mencoes,
        'notificar_todos': notificarTodos,
        'lembrete_dias_antes': lembreteDiasAntes,
        'ativo': ativo,
      };
}

/// Postgres/Supabase no web pode devolver `null`, `double` ou `String` em colunas numéricas.
int _jsonInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

int? _jsonIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

double _jsonDouble(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? fallback;
  return fallback;
}

List<int> _parseBigIntArray(dynamic raw) {
  if (raw == null) return [];
  if (raw is! List) return [];
  return raw.where((e) => e != null).map((e) => _jsonInt(e)).toList();
}

String _formatDate(dynamic value) {
  if (value is String) return value.split('T').first;
  return value.toString().split('T').first;
}

enum TipoDesafio { checkins, streak, agua }

class DicaTreino {
  const DicaTreino({
    required this.id,
    required this.icon,
    required this.titulo,
    required this.texto,
    required this.categoria,
    this.ativo = true,
    this.ordem = 0,
  });

  final int id;
  final String icon;
  final String titulo;
  final String texto;
  final String categoria;
  final bool ativo;
  final int ordem;

  DicaTreino copyWith({
    int? id,
    String? icon,
    String? titulo,
    String? texto,
    String? categoria,
    bool? ativo,
    int? ordem,
  }) {
    return DicaTreino(
      id: id ?? this.id,
      icon: icon ?? this.icon,
      titulo: titulo ?? this.titulo,
      texto: texto ?? this.texto,
      categoria: categoria ?? this.categoria,
      ativo: ativo ?? this.ativo,
      ordem: ordem ?? this.ordem,
    );
  }

  factory DicaTreino.fromJson(Map<String, dynamic> json) => DicaTreino(
        id: _jsonInt(json['id']),
        icon: json['icon'] as String? ?? '💡',
        titulo: json['titulo'] as String? ?? '',
        texto: json['texto'] as String? ?? '',
        categoria: json['categoria'] as String? ?? 'Geral',
        ativo: json['ativo'] as bool? ?? true,
        ordem: _jsonInt(json['ordem']),
      );

  Map<String, dynamic> toJson() => {
        'icon': icon,
        'titulo': titulo,
        'texto': texto,
        'categoria': categoria,
        'ativo': ativo,
        'ordem': ordem,
      };

}

class Desafio {
  const Desafio({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.tipo,
    required this.meta,
    required this.pontosRecompensa,
    required this.dataInicio,
    this.dataFim,
    this.ativo = true,
  });

  final int id;
  final String titulo;
  final String descricao;
  final TipoDesafio tipo;
  final int meta;
  final int pontosRecompensa;
  final String dataInicio;
  final String? dataFim;
  final bool ativo;

  bool get vigente {
    final hoje = DateTime.now();
    final inicio = DateTime.parse(dataInicio);
    if (hoje.isBefore(DateTime(inicio.year, inicio.month, inicio.day))) return false;
    if (dataFim == null || dataFim!.isEmpty) return true;
    final fim = DateTime.parse(dataFim!);
    return !hoje.isAfter(DateTime(fim.year, fim.month, fim.day));
  }

  Desafio copyWith({
    int? id,
    String? titulo,
    String? descricao,
    TipoDesafio? tipo,
    int? meta,
    int? pontosRecompensa,
    String? dataInicio,
    String? dataFim,
    bool? ativo,
  }) {
    return Desafio(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      tipo: tipo ?? this.tipo,
      meta: meta ?? this.meta,
      pontosRecompensa: pontosRecompensa ?? this.pontosRecompensa,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      ativo: ativo ?? this.ativo,
    );
  }

  static TipoDesafio _tipoFrom(String? raw) => switch (raw) {
        'streak' => TipoDesafio.streak,
        'agua' => TipoDesafio.agua,
        _ => TipoDesafio.checkins,
      };

  static String _tipoTo(TipoDesafio tipo) => switch (tipo) {
        TipoDesafio.streak => 'streak',
        TipoDesafio.agua => 'agua',
        TipoDesafio.checkins => 'checkins',
      };

  factory Desafio.fromJson(Map<String, dynamic> json) => Desafio(
        id: _jsonInt(json['id']),
        titulo: json['titulo'] as String? ?? '',
        descricao: json['descricao'] as String? ?? '',
        tipo: _tipoFrom(json['tipo'] as String?),
        meta: _jsonInt(json['meta'], fallback: 5),
        pontosRecompensa: _jsonInt(json['pontos_recompensa'], fallback: 50),
        dataInicio: _formatDate(json['data_inicio']),
        dataFim: json['data_fim'] != null ? _formatDate(json['data_fim']) : null,
        ativo: json['ativo'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'descricao': descricao,
        'tipo': _tipoTo(tipo),
        'meta': meta,
        'pontos_recompensa': pontosRecompensa,
        'data_inicio': dataInicio,
        if (dataFim != null && dataFim!.isNotEmpty) 'data_fim': dataFim,
        'ativo': ativo,
      };
}

class DesafioProgresso {
  const DesafioProgresso({
    required this.desafioId,
    required this.alunoId,
    this.progresso = 0,
    this.concluidoEm,
  });

  final int desafioId;
  final int alunoId;
  final int progresso;
  final DateTime? concluidoEm;

  bool get concluido => concluidoEm != null;

  DesafioProgresso copyWith({
    int? desafioId,
    int? alunoId,
    int? progresso,
    DateTime? concluidoEm,
  }) {
    return DesafioProgresso(
      desafioId: desafioId ?? this.desafioId,
      alunoId: alunoId ?? this.alunoId,
      progresso: progresso ?? this.progresso,
      concluidoEm: concluidoEm ?? this.concluidoEm,
    );
  }

  factory DesafioProgresso.fromJson(Map<String, dynamic> json) => DesafioProgresso(
        desafioId: _jsonInt(json['desafio_id']),
        alunoId: _jsonInt(json['aluno_id']),
        progresso: _jsonInt(json['progresso']),
        concluidoEm: json['concluido_em'] != null ? DateTime.parse(json['concluido_em'] as String) : null,
      );

  Map<String, dynamic> toJson() => {
        'desafio_id': desafioId,
        'aluno_id': alunoId,
        'progresso': progresso,
        if (concluidoEm != null) 'concluido_em': concluidoEm!.toIso8601String(),
      };
}

