import 'package:flutter/foundation.dart';
import 'package:pulguinha/config/supabase_config.dart';
import 'package:pulguinha/data/mock_data.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/services/supabase_service.dart';

enum AppScreen { public, login, admin, aluno }

class AppState extends ChangeNotifier {
  AppScreen screen = AppScreen.public;
  Usuario? usuario;
  List<Aluno> alunos = [];
  List<Horario> horarios = [];
  List<Agendamento> agendamentos = [];
  List<Produto> produtos = [];
  String adminTab = 'dashboard';
  String alunoTab = 'home';

  bool loading = true;
  bool useMock = true;
  String? initError;

  AppState() {
    init();
  }

  Future<void> init() async {
    loading = true;
    initError = null;
    notifyListeners();

    if (SupabaseConfig.isConfigured) {
      try {
        final svc = SupabaseService.instance;
        final results = await Future.wait([
          svc.fetchAlunos(),
          svc.fetchHorarios(),
          svc.fetchAgendamentos(),
          svc.fetchProdutos(),
        ]);
        alunos = results[0] as List<Aluno>;
        horarios = results[1] as List<Horario>;
        agendamentos = results[2] as List<Agendamento>;
        produtos = results[3] as List<Produto>;
        useMock = false;
      } catch (e) {
        debugPrint('Supabase indisponível, usando mock: $e');
        initError = 'Modo demo (Supabase indisponível)';
        _carregarMock();
      }
    } else {
      _carregarMock();
    }

    loading = false;
    notifyListeners();
  }

  void _carregarMock() {
    useMock = true;
    alunos = List.from(MockData.alunosIniciais);
    horarios = List.from(MockData.horariosIniciais);
    agendamentos = List.from(MockData.agendamentosIniciais);
    produtos = List.from(MockData.produtosLoja);
  }

  void irParaLogin() {
    screen = AppScreen.login;
    notifyListeners();
  }

  void login(Usuario user) {
    usuario = user;
    screen = user.isAdmin ? AppScreen.admin : AppScreen.aluno;
    adminTab = 'dashboard';
    alunoTab = 'home';
    notifyListeners();
  }

  void logout() {
    usuario = null;
    screen = AppScreen.public;
    notifyListeners();
  }

  void setAdminTab(String tab) {
    adminTab = tab;
    notifyListeners();
  }

  void setAlunoTab(String tab) {
    alunoTab = tab;
    notifyListeners();
  }

  Future<Usuario?> autenticar(String email, String senha, UserType tipo) async {
    if (tipo == UserType.admin) {
      if (!useMock) {
        return SupabaseService.instance.autenticarAdmin(email, senha);
      }
      if (email == MockData.adminEmail && senha == MockData.adminSenha) {
        return Usuario(tipo: UserType.admin, nome: MockData.adminNome, email: email);
      }
      return null;
    }

    if (!useMock) {
      final aluno = await SupabaseService.instance.autenticarAluno(email, senha);
      return aluno?.toUsuario();
    }

    final aluno = alunos.where((a) => a.email == email && a.senha == senha).firstOrNull;
    return aluno?.toUsuario();
  }

  void salvarAluno({Aluno? editando, required Aluno dados}) {
    if (editando != null) {
      alunos = alunos.map((a) => a.id == editando.id ? dados : a).toList();
      if (!useMock) {
        SupabaseService.instance.updateAluno(dados).catchError((Object e) {
          debugPrint('Erro ao atualizar aluno: $e');
          return dados;
        });
      }
    } else {
      if (useMock) {
        alunos = [...alunos, dados];
      } else {
        SupabaseService.instance.insertAluno(dados).then((saved) {
          alunos = [...alunos, saved];
          notifyListeners();
        }).catchError((Object e) {
          debugPrint('Erro ao criar aluno: $e');
        });
      }
    }
    notifyListeners();
  }

  void removerAluno(int id) {
    alunos = alunos.where((a) => a.id != id).toList();
    notifyListeners();
    if (!useMock) {
      SupabaseService.instance.deleteAluno(id).catchError((Object e) {
        debugPrint('Erro ao remover aluno: $e');
      });
    }
  }

  void marcarPago(int alunoId) {
    alunos = alunos.map((a) {
      if (a.id != alunoId) return a;
      final meses = MockData.mesesPlano[a.plano] ?? 1;
      final novaData = DateTime.parse(MockData.today).add(Duration(days: meses * 30));
      return a.copyWith(
        status: 'Ativo',
        vencimento: _formatDate(novaData),
      );
    }).toList();
    notifyListeners();
    _syncAluno(alunoId);
  }

  void renovarPlano(Aluno aluno) {
    final meses = MockData.mesesPlano[aluno.plano] ?? 1;
    final base = DateTime.parse(aluno.vencimento);
    final novaData = DateTime(base.year, base.month + meses, base.day);
    alunos = alunos.map((a) {
      if (a.id != aluno.id) return a;
      return a.copyWith(vencimento: _formatDate(novaData));
    }).toList();
    notifyListeners();
    _syncAluno(aluno.id);
  }

  void ativarPlanoAluno(int alunoId, Produto produto) {
    final meses = MockData.mesesPorNomePlano[produto.nome] ?? 1;
    final novaData = DateTime.parse(MockData.today).add(Duration(days: meses * 30));
    final plano = produto.nome.replaceFirst('Plano ', '');
    alunos = alunos.map((a) {
      if (a.id != alunoId) return a;
      return a.copyWith(
        plano: plano,
        status: 'Ativo',
        vencimento: _formatDate(novaData),
      );
    }).toList();
    notifyListeners();
    _syncAluno(alunoId);
  }

  void _syncAluno(int alunoId) {
    if (useMock) return;
    final aluno = alunos.firstWhere((a) => a.id == alunoId);
    SupabaseService.instance.updateAluno(aluno).catchError((Object e) {
      debugPrint('Erro ao sincronizar aluno: $e');
      return aluno;
    });
  }

  List<Agendamento> agendamentosPorDataHorario(String data, int horarioId) {
    return agendamentos.where((ag) => ag.data == data && ag.horarioId == horarioId).toList();
  }

  bool aulaLotada(String data, int horarioId) {
    final h = horarios.firstWhere((x) => x.id == horarioId);
    return agendamentosPorDataHorario(data, horarioId).length >= h.capacidade;
  }

  void criarAgendamento({
    required int alunoId,
    required String nomeAluno,
    required int horarioId,
    required String data,
    required String horario,
  }) {
    final novo = Agendamento(
      id: DateTime.now().millisecondsSinceEpoch,
      alunoId: alunoId,
      nomeAluno: nomeAluno,
      horarioId: horarioId,
      data: data,
      horario: horario,
      status: 'Confirmado',
    );

    if (useMock) {
      agendamentos = [...agendamentos, novo];
      notifyListeners();
      return;
    }

    SupabaseService.instance.insertAgendamento(novo).then((saved) {
      agendamentos = [...agendamentos, saved];
      notifyListeners();
    }).catchError((Object e) {
      debugPrint('Erro ao criar agendamento: $e');
    });
  }

  void cancelarAgendamento(int id) {
    agendamentos = agendamentos.where((a) => a.id != id).toList();
    notifyListeners();
    if (!useMock) {
      SupabaseService.instance.deleteAgendamento(id).catchError((Object e) {
        debugPrint('Erro ao cancelar agendamento: $e');
      });
    }
  }

  double get receitaMensalEstimada {
    return alunos.where((a) => a.status == 'Ativo').fold<double>(0, (s, a) {
      final valor = MockData.valoresPlano[a.plano] ?? 0;
      final meses = MockData.mesesPlano[a.plano] ?? 1;
      return s + valor / meses;
    });
  }

  Aluno? alunoPorId(int? id) {
    if (id == null) return null;
    return alunos.where((a) => a.id == id).firstOrNull;
  }

  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
