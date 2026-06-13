import 'package:intl/intl.dart';
import 'package:pulguinha/models/models.dart';

class MockData {
  static String get today => DateFormat('yyyy-MM-dd').format(DateTime.now());

  static const adminEmail = 'admin@pulguinha.com';
  static const adminSenha = 'admin123';
  static const adminNome = 'Pulguinha Admin';

  static final List<Aluno> alunosIniciais = [
    Aluno(
      id: 1,
      nome: 'Ana Costa',
      email: 'ana@email.com',
      senha: '1234',
      telefone: '(11) 98765-0001',
      plano: 'Mensal',
      vencimento: '2026-06-20',
      status: 'Ativo',
      avatar: 'AC',
      dataNascimento: '1995-06-13',
      anamnese: const Anamnese(objetivoTreino: 'Condicionamento', nivelExperiencia: 'Intermediário'),
      streakPresenca: 5,
      pulguinhaPoints: 50,
      dataCadastro: '2026-01-15',
    ),
    Aluno(
      id: 2,
      nome: 'Bruno Lima',
      email: 'bruno@email.com',
      senha: '1234',
      telefone: '(11) 98765-0002',
      plano: 'Trimestral',
      vencimento: '2026-08-10',
      status: 'Ativo',
      avatar: 'BL',
      dataNascimento: '1990-03-22',
      anamnese: const Anamnese(objetivoTreino: 'Emagrecer', nivelExperiencia: 'Iniciante'),
      streakPresenca: 3,
      pulguinhaPoints: 30,
      dataCadastro: '2026-02-01',
    ),
    const Aluno(
      id: 3,
      nome: 'Carla Dias',
      email: 'carla@email.com',
      senha: '1234',
      telefone: '(11) 98765-0003',
      plano: 'Mensal',
      vencimento: '2026-06-05',
      status: 'Inadimplente',
      avatar: 'CD',
      dataNascimento: '1988-11-08',
    ),
    Aluno(
      id: 4,
      nome: 'Diego Souza',
      email: 'diego@email.com',
      senha: '1234',
      telefone: '(11) 98765-0004',
      plano: 'Anual',
      vencimento: '2027-01-15',
      status: 'Ativo',
      avatar: 'DS',
      dataNascimento: '1992-07-04',
      anamnese: const Anamnese(restricoesMedicas: 'Joelho direito', nivelExperiencia: 'Avançado'),
      streakPresenca: 8,
      pulguinhaPoints: 80,
      dataCadastro: '2025-11-20',
    ),
    Aluno(
      id: 5,
      nome: 'Elisa Rocha',
      email: 'elisa@email.com',
      senha: '1234',
      telefone: '(11) 98765-0005',
      plano: 'Mensal',
      vencimento: '2026-06-28',
      status: 'Ativo',
      avatar: 'ER',
      dataNascimento: '1998-06-18',
      anamnese: const Anamnese(objetivoTreino: 'Força', nivelExperiencia: 'Intermediário'),
      streakPresenca: 2,
      pulguinhaPoints: 20,
      dataCadastro: '2026-05-01',
    ),
  ];

  static final List<Horario> horariosIniciais = [
    const Horario(id: 1, hora: '06:00', dias: 'Seg/Qua/Sex', capacidade: 12),
    const Horario(id: 2, hora: '07:00', dias: 'Seg/Qua/Sex', capacidade: 12),
    const Horario(id: 3, hora: '08:00', dias: 'Ter/Qui', capacidade: 10),
    const Horario(id: 4, hora: '09:00', dias: 'Seg a Sex', capacidade: 8),
    const Horario(id: 5, hora: '18:00', dias: 'Seg a Sex', capacidade: 15),
    const Horario(id: 6, hora: '19:00', dias: 'Seg a Sex', capacidade: 15),
    const Horario(id: 7, hora: '20:00', dias: 'Seg/Qua/Sex', capacidade: 12),
  ];

  static final List<Produto> produtosLoja = [
    const Produto(id: 1, nome: 'Plano Mensal', desc: 'Acesso ilimitado por 30 dias', preco: 150, tipo: 'plano', emoji: '📅'),
    const Produto(id: 2, nome: 'Plano Trimestral', desc: '3 meses com 10% de desconto', preco: 400, tipo: 'plano', emoji: '🗓️'),
    const Produto(id: 3, nome: 'Plano Semestral', desc: '6 meses com 20% de desconto', preco: 720, tipo: 'plano', emoji: '📆'),
    const Produto(id: 4, nome: 'Plano Anual', desc: '12 meses com 30% de desconto', preco: 1300, tipo: 'plano', emoji: '🏆'),
    const Produto(id: 5, nome: 'Camiseta Pulguinha', desc: 'Dry-fit tamanhos P/M/G/GG', preco: 69, tipo: 'produto', emoji: '👕'),
    const Produto(id: 6, nome: 'Squeeze 700ml', desc: 'Alumínio com logo bordado', preco: 49, tipo: 'produto', emoji: '🥤'),
    const Produto(id: 7, nome: 'Aula Avulsa', desc: '1 treino funcional à la carte', preco: 40, tipo: 'avulso', emoji: '🎟️'),
  ];

  static final List<Agendamento> agendamentosIniciais = [
    Agendamento(id: 1, alunoId: 1, nomeAluno: 'Ana Costa', horarioId: 5, data: today, horario: '18:00', status: 'Confirmado'),
    Agendamento(id: 2, alunoId: 2, nomeAluno: 'Bruno Lima', horarioId: 5, data: today, horario: '18:00', status: 'Confirmado'),
    Agendamento(id: 3, alunoId: 4, nomeAluno: 'Diego Souza', horarioId: 6, data: today, horario: '19:00', status: 'Confirmado'),
    Agendamento(id: 4, alunoId: 5, nomeAluno: 'Elisa Rocha', horarioId: 1, data: today, horario: '06:00', status: 'Confirmado'),
    const Agendamento(id: 5, alunoId: 1, nomeAluno: 'Ana Costa', horarioId: 7, data: '2026-06-14', horario: '20:00', status: 'Confirmado'),
  ];

  static List<Presenca> presencasIniciais() {
    final now = DateTime.now();
    String iso(int daysAgo) => DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days: daysAgo)));
    return [
      Presenca(id: 1, alunoId: 1, horarioId: 5, data: iso(4), horario: '18:00', timestamp: now.subtract(const Duration(days: 4)), tipo: TipoPresenca.scanProfessor, nomeAluno: 'Ana Costa'),
      Presenca(id: 2, alunoId: 1, horarioId: 5, data: iso(3), horario: '18:00', timestamp: now.subtract(const Duration(days: 3)), tipo: TipoPresenca.scanAluno, nomeAluno: 'Ana Costa'),
      Presenca(id: 3, alunoId: 1, horarioId: 5, data: iso(2), horario: '18:00', timestamp: now.subtract(const Duration(days: 2)), tipo: TipoPresenca.scanProfessor, nomeAluno: 'Ana Costa'),
      Presenca(id: 4, alunoId: 1, horarioId: 5, data: iso(1), horario: '18:00', timestamp: now.subtract(const Duration(days: 1)), tipo: TipoPresenca.scanAluno, nomeAluno: 'Ana Costa'),
      Presenca(id: 5, alunoId: 2, horarioId: 5, data: iso(2), horario: '18:00', timestamp: now.subtract(const Duration(days: 2)), tipo: TipoPresenca.scanProfessor, nomeAluno: 'Bruno Lima'),
      Presenca(id: 6, alunoId: 2, horarioId: 6, data: iso(1), horario: '19:00', timestamp: now.subtract(const Duration(days: 1)), tipo: TipoPresenca.scanAluno, nomeAluno: 'Bruno Lima'),
      Presenca(id: 7, alunoId: 4, horarioId: 1, data: iso(1), horario: '06:00', timestamp: now.subtract(const Duration(days: 1)), tipo: TipoPresenca.scanProfessor, nomeAluno: 'Diego Souza'),
      Presenca(id: 8, alunoId: 5, horarioId: 1, data: today, horario: '06:00', timestamp: now, tipo: TipoPresenca.scanAluno, nomeAluno: 'Elisa Rocha'),
      Presenca(id: 9, alunoId: 4, horarioId: 6, data: iso(3), horario: '19:00', timestamp: now.subtract(const Duration(days: 3)), tipo: TipoPresenca.scanProfessor, nomeAluno: 'Diego Souza'),
      Presenca(id: 10, alunoId: 4, horarioId: 5, data: iso(5), horario: '18:00', timestamp: now.subtract(const Duration(days: 5)), tipo: TipoPresenca.scanAluno, nomeAluno: 'Diego Souza'),
    ];
  }

  static const valoresPlano = {
    'Mensal': 150.0,
    'Trimestral': 400.0,
    'Semestral': 720.0,
    'Anual': 1300.0,
  };

  static const mesesPlano = {
    'Mensal': 1,
    'Trimestral': 3,
    'Semestral': 6,
    'Anual': 12,
  };

  static const mesesPorNomePlano = {
    'Plano Mensal': 1,
    'Plano Trimestral': 3,
    'Plano Semestral': 6,
    'Plano Anual': 12,
  };

  static const streakMilestones = [5, 10, 20];
  static const pointsPorCheckin = 10;
}
