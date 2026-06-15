import 'package:flutter/material.dart';
import 'package:pulguinha/config/supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pulguinha/data/mock_data.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/services/supabase_bootstrap.dart';
import 'package:pulguinha/services/supabase_service.dart';
import 'package:pulguinha/utils/date_helper.dart';

enum AppScreen { public, login, admin, aluno }

class RegistrarPresencaResult {
  const RegistrarPresencaResult({
    required this.ok,
    this.mensagem,
    this.aluno,
    this.novoStreak = 0,
    this.milestoneAtingido,
    this.pointsGanhos = 0,
  });

  final bool ok;
  final String? mensagem;
  final Aluno? aluno;
  final int novoStreak;
  final int? milestoneAtingido;
  final int pointsGanhos;
}

class AppState extends ChangeNotifier {
  AppScreen screen = AppScreen.public;
  Usuario? usuario;
  List<Aluno> alunos = [];
  List<Horario> horarios = [];
  List<Agendamento> agendamentos = [];
  List<Produto> produtos = [];
  List<Presenca> presencas = [];
  List<PostTurma> postsTurma = [];
  String adminTab = 'dashboard';
  String alunoTab = 'home';
  ThemeMode themeMode = ThemeMode.dark;

  bool loading = true;
  bool useMock = true;
  String? initError;

  RealtimeChannel? _realtimeChannel;

  AppState() {
    init();
  }

  static const _themePrefKey = 'pulguinha_theme_mode';

  Future<void> init() async {
    loading = true;
    initError = null;
    notifyListeners();

    await _loadThemeMode();

    if (SupabaseConfig.isConfigured) {
      try {
        await SupabaseBootstrap.ensureInitialized(
          url: SupabaseConfig.url,
          anonKey: SupabaseConfig.anonKey,
        );
        final svc = SupabaseService.instance;
        final results = await Future.wait([
          svc.fetchAlunos(),
          svc.fetchHorarios(),
          svc.fetchAgendamentos(),
          svc.fetchProdutos(),
          svc.fetchPresencas(),
          svc.fetchPostsTurma(),
        ]);
        alunos = results[0] as List<Aluno>;
        horarios = results[1] as List<Horario>;
        agendamentos = results[2] as List<Agendamento>;
        produtos = results[3] as List<Produto>;
        presencas = results[4] as List<Presenca>;
        postsTurma = results[5] as List<PostTurma>;
        useMock = false;
        try {
          _subscribeRealtime();
        } catch (e) {
          debugPrint('Realtime indisponível (dados online OK): $e');
        }
      } catch (e) {
        debugPrint('Supabase indisponível, usando mock: $e');
        initError = 'Modo offline (dados locais)';
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
    presencas = MockData.presencasIniciais();
    postsTurma = MockData.postsTurmaIniciais();
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
    if (user.isAdmin && SupabaseConfig.isConfigured) {
      if (useMock) {
        conectarSupabase();
      } else {
        recarregarDados();
      }
    }
  }

  void logout() {
    usuario = null;
    screen = AppScreen.public;
    notifyListeners();
  }

  void setAdminTab(String tab) {
    adminTab = tab;
    notifyListeners();
    if (!useMock && (tab == 'alunos' || tab == 'dashboard' || tab == 'agenda')) {
      recarregarDados();
    }
  }

  void setAlunoTab(String tab) {
    alunoTab = tab;
    notifyListeners();
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_themePrefKey);
      if (saved == 'light') themeMode = ThemeMode.light;
      if (saved == 'dark') themeMode = ThemeMode.dark;
    } catch (e) {
      debugPrint('Erro ao carregar tema: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themePrefKey, mode == ThemeMode.light ? 'light' : 'dark');
    } catch (e) {
      debugPrint('Erro ao salvar tema: $e');
    }
  }

  void toggleThemeMode() {
    setThemeMode(themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  bool get precisaConfigurarSupabase => useMock && !SupabaseConfig.isConfigured;

  Future<Usuario?> autenticar(String email, String senha, UserType tipo) async {
    final em = email.trim().toLowerCase();
    final sn = senha;

    if (tipo == UserType.admin) {
      if (!useMock) {
        return SupabaseService.instance.autenticarAdmin(em, sn);
      }
      if (em == MockData.adminEmail && sn == MockData.adminSenha) {
        return Usuario(tipo: UserType.admin, nome: MockData.adminNome, email: MockData.adminEmail);
      }
      return null;
    }

    if (!useMock) {
      final aluno = await SupabaseService.instance.autenticarAluno(em, sn);
      if (aluno == null) return null;
      if (aluno.status == 'Pendente') return null;
      return aluno.toUsuario();
    }

    final aluno = alunos
        .where((a) => a.email.toLowerCase() == em && a.senha == sn)
        .firstOrNull;
    if (aluno == null) return null;
    if (aluno.status == 'Pendente') return null;
    return aluno.toUsuario();
  }

  bool emailJaCadastrado(String email) {
    return alunos.any((a) => a.email.toLowerCase() == email.toLowerCase());
  }

  Future<bool> emailJaCadastradoRemoto(String email) async {
    if (!useMock && SupabaseConfig.isConfigured) {
      return SupabaseService.instance.emailExiste(email);
    }
    return emailJaCadastrado(email);
  }

  Aluno? buscarAlunoPorEmail(String email) {
    return alunos.where((a) => a.email.toLowerCase() == email.toLowerCase()).firstOrNull;
  }

  Future<String?> cadastrarAlunoPublico(Aluno dados) async {
    await garantirConexaoSupabase();

    if (await emailJaCadastradoRemoto(dados.email)) {
      return 'Este e-mail já está cadastrado.';
    }
    final novo = dados.copyWith(
      status: 'Pendente',
      plano: 'Mensal',
      vencimento: MockData.vencimentoPendente,
      dataCadastro: MockData.today,
      alunoDesde: dados.alunoDesde ?? MockData.today,
    );
    if (useMock) {
      return 'Cadastro não enviado — servidor não conectado. Cadastros não sincronizam neste modo.';
    }
    try {
      final saved = await SupabaseService.instance.insertAluno(novo);
      final confirmado = await SupabaseService.instance.verificarAlunoSalvo(saved.email);
      if (!confirmado) {
        return 'Cadastro não confirmado no servidor. Verifique a conexão e tente novamente.';
      }
      alunos = [...alunos, saved];
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('Erro insertAluno: $e');
      return 'Erro ao cadastrar: ${e.toString().split('\n').first}';
    }
  }

  /// Tenta conectar ao Supabase quando há credenciais mas o app caiu em modo mock.
  Future<bool> garantirConexaoSupabase() async {
    if (!SupabaseConfig.isConfigured) return false;
    if (!useMock) return true;
    return conectarSupabase();
  }

  /// Reinicializa o cliente Supabase e recarrega dados (sem reiniciar o app).
  Future<bool> conectarSupabase() async {
    if (!SupabaseConfig.isConfigured) return false;
    try {
      await SupabaseBootstrap.ensureInitialized(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
      await recarregarDados();
      return !useMock;
    } catch (e) {
      debugPrint('Falha ao conectar Supabase: $e');
      initError = 'Sem conexão com o banco';
      notifyListeners();
      return false;
    }
  }

  void validarAluno(int id) {
    alunos = alunos.map((a) {
      if (a.id != id) return a;
      final meses = MockData.mesesPlano[a.plano] ?? 1;
      final novaData = DateTime.parse(MockData.today).add(Duration(days: meses * 30));
      return a.copyWith(
        status: 'Ativo',
        vencimento: _formatDate(novaData),
      );
    }).toList();
    notifyListeners();
    _syncAluno(id);
  }

  void salvarHorario({Horario? editando, required Horario dados}) {
    if (editando != null) {
      horarios = horarios.map((h) => h.id == editando.id ? dados : h).toList();
      if (!useMock) {
        SupabaseService.instance.updateHorario(dados).catchError((Object e) {
          debugPrint('Erro ao atualizar horário: $e');
          return dados;
        });
      }
    } else {
      final novo = dados.copyWith(id: DateTime.now().millisecondsSinceEpoch);
      horarios = [...horarios, novo];
      if (!useMock) {
        SupabaseService.instance.insertHorario(novo).then((saved) {
          horarios = horarios.map((h) => h.id == novo.id ? saved : h).toList();
          notifyListeners();
        }).catchError((Object e) {
          debugPrint('Erro ao criar horário: $e');
        });
      }
    }
    notifyListeners();
  }

  void removerHorario(int id) {
    horarios = horarios.where((h) => h.id != id).toList();
    notifyListeners();
    if (!useMock) {
      SupabaseService.instance.deleteHorario(id).catchError((Object e) => debugPrint('Erro ao remover horário: $e'));
    }
  }

  void salvarProduto({Produto? editando, required Produto dados}) {
    if (editando != null) {
      produtos = produtos.map((p) => p.id == editando.id ? dados : p).toList();
      if (!useMock) {
        SupabaseService.instance.updateProduto(dados).catchError((Object e) {
          debugPrint('Erro ao atualizar produto: $e');
          return dados;
        });
      }
    } else {
      final novo = dados.copyWith(id: DateTime.now().millisecondsSinceEpoch);
      produtos = [...produtos, novo];
      if (!useMock) {
        SupabaseService.instance.insertProduto(novo).then((saved) {
          produtos = produtos.map((p) => p.id == novo.id ? saved : p).toList();
          notifyListeners();
        }).catchError((Object e) {
          debugPrint('Erro ao criar produto: $e');
        });
      }
    }
    notifyListeners();
  }

  void removerProduto(int id) {
    produtos = produtos.where((p) => p.id != id).toList();
    notifyListeners();
    if (!useMock) {
      SupabaseService.instance.deleteProduto(id).catchError((Object e) => debugPrint('Erro ao remover produto: $e'));
    }
  }

  double precoPlano(String plano) {
    final produto = produtos.where((p) => p.tipo == 'plano' && p.nome.replaceFirst('Plano ', '') == plano).firstOrNull;
    if (produto != null) return produto.preco;
    return MockData.valoresPlano[plano] ?? 0;
  }

  Produto? produtoPlano(String plano) {
    return produtos.where((p) => p.tipo == 'plano' && p.nome.replaceFirst('Plano ', '') == plano).firstOrNull;
  }

  int get alunosPendentes => alunos.where((a) => a.status == 'Pendente').length;

  void salvarAluno({Aluno? editando, required Aluno dados}) {
    if (editando != null) {
      alunos = alunos.map((a) => a.id == editando.id ? dados : a).toList();
      if (usuario?.id == editando.id) {
        usuario = dados.toUsuario();
      }
      if (!useMock) {
        SupabaseService.instance.updateAluno(dados).catchError((Object e) {
          debugPrint('Erro ao atualizar aluno: $e');
          return dados;
        });
      }
    } else {
      final novo = dados.copyWith(
        dataCadastro: dados.dataCadastro ?? MockData.today,
        alunoDesde: dados.alunoDesde ?? dados.dataCadastro ?? MockData.today,
        vencimento: dados.status == 'Pendente' ? MockData.vencimentoPendente : dados.vencimento,
      );
      if (useMock) {
        alunos = [...alunos, novo];
      } else {
        SupabaseService.instance.insertAluno(novo).then((saved) {
          alunos = [...alunos, saved];
          notifyListeners();
        }).catchError((Object e) {
          debugPrint('Erro ao criar aluno: $e');
        });
      }
    }
    notifyListeners();
  }

  void atualizarFotoAluno(int alunoId, String? fotoBase64) {
    alunos = alunos.map((a) {
      if (a.id != alunoId) return a;
      return a.copyWith(foto: fotoBase64);
    }).toList();
    if (usuario?.id == alunoId) {
      usuario = alunos.firstWhere((a) => a.id == alunoId).toUsuario();
    }
    notifyListeners();
    _syncAluno(alunoId);
  }

  void removerAluno(int id) {
    alunos = alunos.where((a) => a.id != id).toList();
    presencas = presencas.where((p) => p.alunoId != id).toList();
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
    if (usuario?.id == alunoId) {
      final atualizado = alunos.firstWhere((a) => a.id == alunoId);
      usuario = atualizado.toUsuario();
    }
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

  Future<void> recarregarDados() async {
    if (!SupabaseConfig.isConfigured) return;
    try {
      await SupabaseBootstrap.ensureInitialized(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
      final svc = SupabaseService.instance;
      final results = await Future.wait([
        svc.fetchAlunos(),
        svc.fetchHorarios(),
        svc.fetchAgendamentos(),
        svc.fetchProdutos(),
        svc.fetchPresencas(),
        svc.fetchPostsTurma(),
      ]);
      alunos = results[0] as List<Aluno>;
      horarios = results[1] as List<Horario>;
      agendamentos = results[2] as List<Agendamento>;
      produtos = results[3] as List<Produto>;
      presencas = results[4] as List<Presenca>;
      postsTurma = results[5] as List<PostTurma>;
      useMock = false;
      initError = null;
      try {
        _subscribeRealtime();
      } catch (e) {
        debugPrint('Realtime indisponível (dados online OK): $e');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao recarregar dados: $e');
      initError = 'Sem conexão com o banco';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> recarregarAgendamentos() async {
    if (useMock || !SupabaseConfig.isConfigured) return;
    await _syncAgendamentosFromServer();
  }

  void _subscribeRealtime() {
    if (!SupabaseConfig.isConfigured || useMock) return;
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = Supabase.instance.client
        .channel('pulguinha-sync')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'agendamentos',
          callback: (_) => _syncAgendamentosFromServer(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'alunos',
          callback: (_) => _syncAlunosFromServer(),
        )
        .subscribe();
  }

  Future<void> _syncAlunosFromServer() async {
    try {
      alunos = await SupabaseService.instance.fetchAlunos();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao sincronizar alunos: $e');
    }
  }

  Future<void> _syncAgendamentosFromServer() async {
    try {
      agendamentos = await SupabaseService.instance.fetchAgendamentos();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao sincronizar agendamentos: $e');
    }
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

  // ── Presença ──

  bool jaRegistrouPresenca(int alunoId, int horarioId, String data) {
    return presencas.any((p) => p.alunoId == alunoId && p.horarioId == horarioId && p.data == data);
  }

  RegistrarPresencaResult registrarPresenca({
    required int alunoId,
    required int horarioId,
    required String data,
    required TipoPresenca tipo,
  }) {
    if (jaRegistrouPresenca(alunoId, horarioId, data)) {
      return const RegistrarPresencaResult(ok: false, mensagem: 'Presença já registrada hoje nesta aula!');
    }

    final aluno = alunoPorId(alunoId);
    if (aluno == null) {
      return const RegistrarPresencaResult(ok: false, mensagem: 'Aluno não encontrado.');
    }

    final hor = horarios.where((h) => h.id == horarioId).firstOrNull;
    if (hor == null) {
      return const RegistrarPresencaResult(ok: false, mensagem: 'Horário inválido.');
    }

    final nova = Presenca(
      id: DateTime.now().millisecondsSinceEpoch,
      alunoId: alunoId,
      horarioId: horarioId,
      data: data,
      horario: hor.hora,
      timestamp: DateTime.now(),
      tipo: tipo,
      nomeAluno: aluno.nome,
    );

    presencas = [...presencas, nova];

    final novoStreak = _calcularStreak(alunoId);
    final pointsGanhos = MockData.pointsPorCheckin + (MockData.streakMilestones.contains(novoStreak) ? 50 : 0);
    final milestone = MockData.streakMilestones.contains(novoStreak) ? novoStreak : null;

    alunos = alunos.map((a) {
      if (a.id != alunoId) return a;
      return a.copyWith(
        streakPresenca: novoStreak,
        pulguinhaPoints: a.pulguinhaPoints + pointsGanhos,
      );
    }).toList();

    if (usuario?.id == alunoId) {
      usuario = alunos.firstWhere((a) => a.id == alunoId).toUsuario();
    }

    notifyListeners();

    if (!useMock) {
      SupabaseService.instance.insertPresenca(nova).catchError((Object e) {
        debugPrint('Erro ao registrar presença: $e');
        return nova;
      });
      _syncAluno(alunoId);
    }

    final atualizado = alunos.firstWhere((a) => a.id == alunoId);
    return RegistrarPresencaResult(
      ok: true,
      aluno: atualizado,
      novoStreak: novoStreak,
      milestoneAtingido: milestone,
      pointsGanhos: pointsGanhos,
      mensagem: 'Presença confirmada! 💪',
    );
  }

  int _calcularStreak(int alunoId) {
    final datas = presencas
        .where((p) => p.alunoId == alunoId)
        .map((p) => p.data)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (datas.isEmpty) return 0;

    var streak = 1;
    var cursor = DateTime.parse(datas.first);

    for (var i = 1; i < datas.length; i++) {
      final d = DateTime.parse(datas[i]);
      final diff = cursor.difference(d).inDays;
      if (diff == 1) {
        streak++;
        cursor = d;
      } else if (diff > 1) {
        break;
      }
    }
    return streak;
  }

  List<Presenca> presencasPorAluno(int alunoId) {
    return presencas.where((p) => p.alunoId == alunoId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<Presenca> presencasHoje([String? data]) {
    final d = data ?? MockData.today;
    return presencas.where((p) => p.data == d).toList();
  }

  List<Presenca> presencasNaSemana() {
    final hoje = DateTime.parse(MockData.today);
    final inicio = hoje.subtract(Duration(days: hoje.weekday - 1));
    final fim = inicio.add(const Duration(days: 6));
    return presencas.where((p) {
      final d = DateTime.parse(p.data);
      return !d.isBefore(inicio) && !d.isAfter(fim);
    }).toList();
  }

  double taxaPresenca({int? alunoId, int dias = 30}) {
    final hoje = DateTime.parse(MockData.today);
    final inicio = hoje.subtract(Duration(days: dias - 1));
    final noPeriodo = presencas.where((p) {
      if (alunoId != null && p.alunoId != alunoId) return false;
      final d = DateTime.parse(p.data);
      return !d.isBefore(inicio) && !d.isAfter(hoje);
    }).toList();

    if (alunoId != null) {
      final diasComPresenca = noPeriodo.map((p) => p.data).toSet().length;
      return (diasComPresenca / dias * 100).clamp(0, 100);
    }

    final totalAlunos = alunos.where((a) => a.status == 'Ativo').length;
    if (totalAlunos == 0) return 0;
    final mediaPorAluno = alunos.where((a) => a.status == 'Ativo').map((a) {
      final diasAluno = noPeriodo.where((p) => p.alunoId == a.id).map((p) => p.data).toSet().length;
      return diasAluno / dias * 100;
    });
    return mediaPorAluno.isEmpty ? 0 : mediaPorAluno.reduce((a, b) => a + b) / mediaPorAluno.length;
  }

  Map<String, int> presencasPorDia(int dias) {
    final hoje = DateTime.parse(MockData.today);
    final map = <String, int>{};
    for (var i = dias - 1; i >= 0; i--) {
      final d = hoje.subtract(Duration(days: i));
      final iso = _formatDate(d);
      map[iso] = presencas.where((p) => p.data == iso).length;
    }
    return map;
  }

  Map<int, int> presencasPorHorario({int dias = 7}) {
    final hoje = DateTime.parse(MockData.today);
    final inicio = hoje.subtract(Duration(days: dias - 1));
    final map = <int, int>{};
    for (final h in horarios) {
      map[h.id] = presencas.where((p) {
        if (p.horarioId != h.id) return false;
        final d = DateTime.parse(p.data);
        return !d.isBefore(inicio) && !d.isAfter(hoje);
      }).length;
    }
    return map;
  }

  List<(Aluno, int)> rankingSemana({int top = 3}) {
    final semana = presencasNaSemana();
    final counts = <int, int>{};
    for (final p in semana) {
      counts[p.alunoId] = (counts[p.alunoId] ?? 0) + 1;
    }
    final ranked = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return ranked.take(top).map((e) {
      final aluno = alunoPorId(e.key)!;
      return (aluno, e.value);
    }).toList();
  }

  List<Aluno> aniversariantesHoje() {
    return alunos.where((a) => DateHelper.isAniversarioHoje(a.dataNascimento)).toList();
  }

  List<Aluno> aniversariantesProximos7Dias() {
    return alunos.where((a) {
      if (a.dataNascimento == null || a.dataNascimento!.isEmpty) return false;
      if (DateHelper.isAniversarioHoje(a.dataNascimento)) return false;
      final dias = DateHelper.diasAteAniversario(a.dataNascimento!);
      return dias > 0 && dias <= 7;
    }).toList()
      ..sort((a, b) => DateHelper.diasAteAniversario(a.dataNascimento!).compareTo(DateHelper.diasAteAniversario(b.dataNascimento!)));
  }

  int aniversariantesDoMes() {
    final mes = DateTime.now().month;
    return alunos.where((a) => DateHelper.aniversarioNoMes(a.dataNascimento, mes)).length;
  }

  int novosAlunosMes() {
    final mes = DateTime.now().month;
    final ano = DateTime.now().year;
    return alunos.where((a) {
      if (a.dataCadastro == null) return false;
      final d = DateTime.parse(a.dataCadastro!);
      return d.month == mes && d.year == ano;
    }).length;
  }

  Map<String, int> distribuicaoPlanos() {
    final map = <String, int>{};
    for (final a in alunos.where((a) => a.status == 'Ativo')) {
      map[a.plano] = (map[a.plano] ?? 0) + 1;
    }
    return map;
  }

  double get receitaMensalEstimada {
    return alunos.where((a) => a.status == 'Ativo').fold<double>(0, (s, a) {
      final valor = precoPlano(a.plano);
      final meses = MockData.mesesPlano[a.plano] ?? 1;
      return s + valor / meses;
    });
  }

  Aluno? alunoPorId(int? id) {
    if (id == null) return null;
    return alunos.where((a) => a.id == id).firstOrNull;
  }

  Horario? horarioPorId(int? id) {
    if (id == null) return null;
    return horarios.where((h) => h.id == id).firstOrNull;
  }

  String labelTurma(Aluno aluno) {
    final h = horarioPorId(aluno.horarioId);
    if (h == null) return 'Sem turma';
    return '${h.hora} · ${h.dias}';
  }

  List<Aluno> colegasDeTurma(int alunoId) {
    final eu = alunoPorId(alunoId);
    if (eu?.horarioId == null) return [];
    return alunos
        .where((a) => a.id != alunoId && a.horarioId == eu!.horarioId && a.status == 'Ativo')
        .toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));
  }

  List<PostTurma> postsDaTurma(int horarioId) {
    return postsTurma.where((p) => p.horarioId == horarioId).toList()
      ..sort((a, b) => b.dataHora.compareTo(a.dataHora));
  }

  void publicarPostTurma({
    required int alunoId,
    required String nomeAluno,
    required int horarioId,
    required String texto,
    TipoPostTurma tipo = TipoPostTurma.texto,
    String? figurinha,
    String? linkUrl,
    List<String> enqueteOpcoes = const [],
  }) {
    final trimmed = texto.trim();
    if (tipo == TipoPostTurma.texto && trimmed.isEmpty) return;
    if (tipo == TipoPostTurma.figurinha && (figurinha == null || figurinha.isEmpty)) return;
    if (tipo == TipoPostTurma.link && (linkUrl == null || linkUrl.trim().isEmpty)) return;
    if (tipo == TipoPostTurma.enquete && enqueteOpcoes.where((o) => o.trim().isNotEmpty).length < 2) return;

    final post = PostTurma(
      id: DateTime.now().millisecondsSinceEpoch,
      alunoId: alunoId,
      nomeAluno: nomeAluno,
      horarioId: horarioId,
      texto: trimmed,
      dataHora: DateTime.now(),
      tipo: tipo,
      figurinha: figurinha,
      linkUrl: linkUrl?.trim(),
      enqueteOpcoes: enqueteOpcoes.map((o) => o.trim()).where((o) => o.isNotEmpty).toList(),
    );
    postsTurma = [post, ...postsTurma];
    notifyListeners();
    if (!useMock) {
      SupabaseService.instance.insertPostTurma(post).then((saved) {
        postsTurma = postsTurma.map((p) => p.id == post.id ? saved : p).toList();
        notifyListeners();
      }).catchError((Object e) {
        debugPrint('Erro ao publicar post: $e');
      });
    }
  }

  void votarEnquete({required int postId, required int alunoId, required int opcaoIndex}) {
    postsTurma = postsTurma.map((p) {
      if (p.id != postId || p.tipo != TipoPostTurma.enquete) return p;
      final votos = Map<String, int>.from(p.enqueteVotos);
      votos['$alunoId'] = opcaoIndex;
      return p.copyWith(enqueteVotos: votos);
    }).toList();
    notifyListeners();
    if (!useMock) {
      final post = postsTurma.where((p) => p.id == postId).firstOrNull;
      if (post != null) {
        SupabaseService.instance.updatePostTurma(post).catchError((Object e) {
          debugPrint('Erro ao votar: $e');
          return post;
        });
      }
    }
  }

  void toggleReacaoPost(int postId, int alunoId) {
    postsTurma = postsTurma.map((p) {
      if (p.id != postId) return p;
      final reacoes = List<int>.from(p.reacoes);
      if (reacoes.contains(alunoId)) {
        reacoes.remove(alunoId);
      } else {
        reacoes.add(alunoId);
      }
      return p.copyWith(reacoes: reacoes);
    }).toList();
    notifyListeners();
    if (!useMock) {
      final post = postsTurma.where((p) => p.id == postId).firstOrNull;
      if (post != null) {
        SupabaseService.instance.updatePostTurma(post).catchError((Object e) {
          debugPrint('Erro ao reagir: $e');
          return post;
        });
      }
    }
  }

  void comentarPostTurma({required int postId, required int alunoId, required String nomeAluno, required String texto}) {
    if (texto.trim().isEmpty) return;
    final comentario = ComentarioTurma(
      id: DateTime.now().millisecondsSinceEpoch,
      alunoId: alunoId,
      nomeAluno: nomeAluno,
      texto: texto.trim(),
      dataHora: DateTime.now(),
    );
    postsTurma = postsTurma.map((p) {
      if (p.id != postId) return p;
      return p.copyWith(comentarios: [...p.comentarios, comentario]);
    }).toList();
    notifyListeners();
    if (!useMock) {
      final post = postsTurma.where((p) => p.id == postId).firstOrNull;
      if (post != null) {
        SupabaseService.instance.updatePostTurma(post).catchError((Object e) {
          debugPrint('Erro ao comentar: $e');
          return post;
        });
      }
    }
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
