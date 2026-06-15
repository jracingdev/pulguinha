import 'package:pulguinha/models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();
  static final instance = SupabaseService._();

  SupabaseClient get _db => Supabase.instance.client;

  Future<List<Aluno>> fetchAlunos() async {
    final rows = await _db.from('alunos').select().order('nome');
    return (rows as List).map((r) => Aluno.fromJson(Map<String, dynamic>.from(r as Map))).toList();
  }

  Future<List<Horario>> fetchHorarios() async {
    final rows = await _db.from('horarios').select().order('hora');
    return (rows as List).map((r) => Horario.fromJson(Map<String, dynamic>.from(r as Map))).toList();
  }

  Future<List<Agendamento>> fetchAgendamentos() async {
    final rows = await _db.from('agendamentos').select().order('data');
    return (rows as List).map((r) => Agendamento.fromJson(Map<String, dynamic>.from(r as Map))).toList();
  }

  Future<List<Produto>> fetchProdutos() async {
    final rows = await _db.from('produtos').select().order('id');
    return (rows as List).map((r) => Produto.fromJson(Map<String, dynamic>.from(r as Map))).toList();
  }

  Future<List<Presenca>> fetchPresencas() async {
    final rows = await _db.from('presencas').select().order('timestamp', ascending: false);
    return (rows as List).map((r) => Presenca.fromJson(Map<String, dynamic>.from(r as Map))).toList();
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
    return (rows as List).map((r) => PostTurma.fromJson(Map<String, dynamic>.from(r as Map))).toList();
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
}
