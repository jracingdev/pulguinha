import 'package:flutter/foundation.dart';
import 'package:pulguinha/models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();
  static final instance = SupabaseService._();

  SupabaseClient get _db => Supabase.instance.client;

  List<T> _mapRows<T>(List<dynamic> rows, T Function(Map<String, dynamic>) fromJson, String table) {
    final out = <T>[];
    for (final raw in rows) {
      try {
        out.add(fromJson(Map<String, dynamic>.from(raw as Map)));
      } catch (e, st) {
        debugPrint('Ignorando linha inválida em $table: $e\n$st\n$raw');
      }
    }
    return out;
  }

  /// Colunas leves — sem `foto` (base64 pode passar de 200 KB por aluno e derrubar o web).
  static const _alunoColumnsSemFoto =
      'id,nome,email,senha,telefone,plano,vencimento,status,avatar,data_nascimento,anamnese,'
      'streak_presenca,pulguinha_points,data_cadastro,aluno_desde,horario_id,cep,logradouro,'
      'numero,complemento,bairro,cidade,uf,codigo_indicacao,credito_indicacao';

  Future<List<Aluno>> fetchAlunos({bool includeFoto = false}) async {
    final columns = includeFoto ? '*' : _alunoColumnsSemFoto;
    final rows = await _db.from('alunos').select(columns).order('nome');
    return _mapRows(rows as List, Aluno.fromJson, 'alunos');
  }

  Future<List<Horario>> fetchHorarios() async {
    final rows = await _db.from('horarios').select().order('hora');
    return _mapRows(rows as List, Horario.fromJson, 'horarios');
  }

  Future<List<Agendamento>> fetchAgendamentos() async {
    final rows = await _db.from('agendamentos').select().order('data');
    return _mapRows(rows as List, Agendamento.fromJson, 'agendamentos');
  }

  Future<List<Produto>> fetchProdutos() async {
    final rows = await _db.from('produtos').select().order('id');
    return _mapRows(rows as List, Produto.fromJson, 'produtos');
  }

  Future<List<Presenca>> fetchPresencas() async {
    final rows = await _db.from('presencas').select().order('timestamp', ascending: false);
    return _mapRows(rows as List, Presenca.fromJson, 'presencas');
  }

  Future<Usuario?> autenticarAdmin(String email, String senha) async {
    final rows = await _db.from('admins').select().eq('email', email).eq('senha', senha).maybeSingle();
    if (rows == null) return null;
    final map = Map<String, dynamic>.from(rows as Map);
    return Usuario(tipo: UserType.admin, nome: map['nome'] as String, email: map['email'] as String);
  }

  Future<Aluno?> autenticarAluno(String email, String senha) async {
    final rows = await _db.from('alunos').select().eq('email', email).eq('senha', senha).maybeSingle();
    if (rows == null) return null;
    return Aluno.fromJson(Map<String, dynamic>.from(rows as Map));
  }

  Future<bool> emailExiste(String email) async {
    final normalizado = email.trim().toLowerCase();
    final rows = await _db.from('alunos').select('id').eq('email', normalizado).maybeSingle();
    return rows != null;
  }

  Future<Aluno> insertAluno(Aluno aluno) async {
    final payload = aluno.toInsertJson();
    final rows = await _db.from('alunos').insert(payload).select().single();
    return Aluno.fromJson(Map<String, dynamic>.from(rows as Map));
  }

  Future<bool> verificarAlunoSalvo(String email) async {
    final normalizado = email.trim().toLowerCase();
    final rows = await _db.from('alunos').select('id, status').eq('email', normalizado).maybeSingle();
    return rows != null;
  }

  Future<Aluno> updateAluno(Aluno aluno) async {
    final rows = await _db.from('alunos').update(aluno.toJson()).eq('id', aluno.id).select().single();
    return Aluno.fromJson(Map<String, dynamic>.from(rows as Map));
  }

  Future<void> deleteAluno(int id) async {
    await _db.from('alunos').delete().eq('id', id);
  }

  Future<Agendamento> insertAgendamento(Agendamento ag) async {
    final rows = await _db.from('agendamentos').insert(ag.toJson()).select().single();
    return Agendamento.fromJson(Map<String, dynamic>.from(rows as Map));
  }

  Future<void> deleteAgendamento(int id) async {
    await _db.from('agendamentos').delete().eq('id', id);
  }

  Future<Presenca> insertPresenca(Presenca presenca) async {
    final rows = await _db.from('presencas').insert(presenca.toJson()).select().single();
    return Presenca.fromJson(Map<String, dynamic>.from(rows as Map));
  }

  Future<void> updateAlunoFields(int id, Map<String, dynamic> fields) async {
    await _db.from('alunos').update(fields).eq('id', id);
  }

  Future<Horario> insertHorario(Horario h) async {
    final rows = await _db.from('horarios').insert(h.toJson()).select().single();
    return Horario.fromJson(Map<String, dynamic>.from(rows as Map));
  }

  Future<Horario> updateHorario(Horario h) async {
    final rows = await _db.from('horarios').update(h.toJson()).eq('id', h.id).select().single();
    return Horario.fromJson(Map<String, dynamic>.from(rows as Map));
  }

  Future<void> deleteHorario(int id) async {
    await _db.from('horarios').delete().eq('id', id);
  }

  Future<Produto> insertProduto(Produto p) async {
    final rows = await _db.from('produtos').insert(p.toJson()).select().single();
    return Produto.fromJson(Map<String, dynamic>.from(rows as Map));
  }

  Future<Produto> updateProduto(Produto p) async {
    final rows = await _db.from('produtos').update(p.toJson()).eq('id', p.id).select().single();
    return Produto.fromJson(Map<String, dynamic>.from(rows as Map));
  }

  Future<void> deleteProduto(int id) async {
    await _db.from('produtos').delete().eq('id', id);
  }

  Future<bool> emailAlunoExiste(String email) async {
    final rows = await _db.from('alunos').select('id').eq('email', email).maybeSingle();
    return rows != null;
  }

  Future<List<PostTurma>> fetchPostsTurma() async {
    final rows = await _db.from('posts_turma').select().order('data_hora', ascending: false);
    return _mapRows(rows as List, PostTurma.fromJson, 'posts_turma');
  }

  Future<PostTurma> insertPostTurma(PostTurma post) async {
    final payload = post.toJson();
    final rows = await _db.from('posts_turma').insert(payload).select().single();
    return PostTurma.fromJson(Map<String, dynamic>.from(rows as Map));
  }

  Future<PostTurma> updatePostTurma(PostTurma post) async {
    final payload = post.toJson();
    final rows = await _db.from('posts_turma').update(payload).eq('id', post.id).select().single();
    return PostTurma.fromJson(Map<String, dynamic>.from(rows as Map));
  }

  Future<void> deletePostTurma(int id) async {
    await _db.from('posts_turma').delete().eq('id', id);
  }

  Future<void> updateAlunoSenha(int id, String novaSenha) async {
    await _db.from('alunos').update({'senha': novaSenha}).eq('id', id);
  }

  Future<void> updateAdminSenha(String email, String novaSenha) async {
    await _db.from('admins').update({'senha': novaSenha}).eq('email', email);
  }

  Future<Aluno?> buscarAlunoPorEmail(String email) async {
    final rows = await _db.from('alunos').select().eq('email', email.trim().toLowerCase()).maybeSingle();
    if (rows == null) return null;
    return Aluno.fromJson(Map<String, dynamic>.from(rows as Map));
  }

  Future<List<DicaTreino>> fetchDicas() async {
    final rows = await _db.from('dicas_treino').select().order('ordem');
    return _mapRows(rows as List, DicaTreino.fromJson, 'dicas_treino');
  }

  Future<DicaTreino> insertDica(DicaTreino dica) async {
    final rows = await _db.from('dicas_treino').insert(dica.toJson()).select().single();
    return DicaTreino.fromJson(Map<String, dynamic>.from(rows as Map));
  }

  Future<DicaTreino> updateDica(DicaTreino dica) async {
    final rows = await _db.from('dicas_treino').update(dica.toJson()).eq('id', dica.id).select().single();
    return DicaTreino.fromJson(Map<String, dynamic>.from(rows as Map));
  }

  Future<void> deleteDica(int id) async {
    await _db.from('dicas_treino').delete().eq('id', id);
  }

  Future<List<Desafio>> fetchDesafios() async {
    final rows = await _db.from('desafios').select().order('data_inicio', ascending: false);
    return _mapRows(rows as List, Desafio.fromJson, 'desafios');
  }

  Future<Desafio> insertDesafio(Desafio d) async {
    final rows = await _db.from('desafios').insert(d.toJson()).select().single();
    return Desafio.fromJson(Map<String, dynamic>.from(rows as Map));
  }

  Future<Desafio> updateDesafio(Desafio d) async {
    final rows = await _db.from('desafios').update(d.toJson()).eq('id', d.id).select().single();
    return Desafio.fromJson(Map<String, dynamic>.from(rows as Map));
  }

  Future<void> deleteDesafio(int id) async {
    await _db.from('desafios').delete().eq('id', id);
  }

  Future<List<DesafioProgresso>> fetchDesafioProgresso() async {
    final rows = await _db.from('desafio_progresso').select();
    return _mapRows(rows as List, DesafioProgresso.fromJson, 'desafio_progresso');
  }

  Future<void> upsertDesafioProgresso(DesafioProgresso prog) async {
    await _db.from('desafio_progresso').upsert(prog.toJson());
  }

  Future<List<Aviso>> fetchAvisos() async {
    final rows = await _db.from('avisos').select().eq('ativo', true).order('fixado', ascending: false).order('data_hora', ascending: false);
    return _mapRows(rows as List, Aviso.fromJson, 'avisos');
  }

  Future<Aviso> insertAviso(Aviso aviso) async {
    final rows = await _db.from('avisos').insert(aviso.toJson()).select().single();
    return Aviso.fromJson(Map<String, dynamic>.from(rows as Map));
  }

  Future<Aviso> updateAviso(Aviso aviso) async {
    final rows = await _db.from('avisos').update(aviso.toJson()).eq('id', aviso.id).select().single();
    return Aviso.fromJson(Map<String, dynamic>.from(rows as Map));
  }

  Future<void> deleteAviso(int id) async {
    await _db.from('avisos').delete().eq('id', id);
  }

  Future<List<EventoEstudio>> fetchEventos() async {
    final rows = await _db.from('eventos').select().eq('ativo', true).order('data_inicio');
    return _mapRows(rows as List, EventoEstudio.fromJson, 'eventos');
  }

  Future<EventoEstudio> insertEvento(EventoEstudio evento) async {
    final rows = await _db.from('eventos').insert(evento.toJson()).select().single();
    return EventoEstudio.fromJson(Map<String, dynamic>.from(rows as Map));
  }

  Future<EventoEstudio> updateEvento(EventoEstudio evento) async {
    final rows = await _db.from('eventos').update(evento.toJson()).eq('id', evento.id).select().single();
    return EventoEstudio.fromJson(Map<String, dynamic>.from(rows as Map));
  }

  Future<void> deleteEvento(int id) async {
    await _db.from('eventos').delete().eq('id', id);
  }

  Future<Set<String>> fetchLeiturasAluno(int alunoId) async {
    final rows = await _db.from('comunicacao_leituras').select().eq('aluno_id', alunoId);
    return (rows as List)
        .map((r) {
          final m = Map<String, dynamic>.from(r as Map);
          return '${m['item_tipo']}_${m['item_id']}';
        })
        .toSet();
  }

  Future<void> marcarComunicacaoLida(int alunoId, String itemTipo, int itemId) async {
    await _db.from('comunicacao_leituras').upsert({
      'aluno_id': alunoId,
      'item_tipo': itemTipo,
      'item_id': itemId,
      'lido_em': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Indicacao>> fetchIndicacoes() async {
    final rows = await _db.from('indicacoes').select().order('data_criacao', ascending: false);
    return _mapRows(rows as List, Indicacao.fromJson, 'indicacoes');
  }

  Future<Indicacao> insertIndicacao(Indicacao indicacao) async {
    final payload = indicacao.toJson();
    final rows = await _db.from('indicacoes').insert(payload).select().single();
    return Indicacao.fromJson(Map<String, dynamic>.from(rows as Map));
  }

  Future<Indicacao> updateIndicacao(Indicacao indicacao) async {
    final rows = await _db
        .from('indicacoes')
        .update(indicacao.toJson())
        .eq('id', indicacao.id)
        .select()
        .single();
    return Indicacao.fromJson(Map<String, dynamic>.from(rows as Map));
  }
}
