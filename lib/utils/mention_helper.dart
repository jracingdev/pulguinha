import 'package:pulguinha/models/models.dart';

class MentionHelper {
  static List<int> parseMencoesFromText(String texto, List<Aluno> alunos) {
    final ids = <int>{};
    for (final a in alunos) {
      final tag = '@${a.nome}';
      if (texto.contains(tag)) ids.add(a.id);
      final first = a.nome.split(' ').first;
      if (texto.contains('@$first')) ids.add(a.id);
    }
    return ids.toList();
  }

  static bool alunoMencionado(int alunoId, List<int> mencoes) => mencoes.contains(alunoId);
}
