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

  Future<Aluno> insertAluno(Aluno aluno) async {
    final rows = await _db.from('alunos').insert(aluno.toJson()).select().single();
    return Aluno.fromJson(Map<String, dynamic>.from(rows as Map));
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

  Future<void> updateAlunoFields(int id, Map<String, dynamic> fields) async {
    await _db.from('alunos').update(fields).eq('id', id);
  }
}
