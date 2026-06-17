import 'package:flutter/material.dart';
import 'package:pulguinha/config/supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pulguinha/data/mock_data.dart';
import 'package:pulguinha/models/billing_rules.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/models/partner_access.dart';
import 'package:pulguinha/services/partner_access_service.dart';
import 'package:pulguinha/services/supabase_bootstrap.dart';
import 'package:pulguinha/services/supabase_service.dart';
import 'package:pulguinha/services/finance_settings_storage.dart';
import 'package:pulguinha/services/referral_storage.dart';
import 'package:pulguinha/services/notifications/notification_payload.dart';
import 'package:pulguinha/services/notifications/notification_scheduler.dart';
import 'package:pulguinha/services/notifications/notification_settings_storage.dart';
import 'package:pulguinha/utils/date_helper.dart';
import 'package:pulguinha/utils/horario_helper.dart';
import 'package:pulguinha/utils/mention_helper.dart';
import 'package:pulguinha/utils/vencimento_helper.dart';

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
  List<Aviso> avisos = [];
  List<EventoEstudio> eventos = [];
  List<DicaTreino> dicas = [];
  List<Desafio> desafios = [];
  List<Indicacao> indicacoes = [];
  List<DesafioProgresso> desafioProgresso = [];
  Set<String> comunicacaoLidas = {};
  NotificationSettings notificationSettings = const NotificationSettings();
  bool adminParticipaMural = false;
  String adminTab = 'dashboard';
  String alunoTab = 'home';
  ThemeMode themeMode = ThemeMode.dark;
  int diaVencimentoPadrao = FinanceSettingsStorage.defaultDiaVencimento;
  int diasParaInadimplencia = FinanceSettingsStorage.defaultDiasInadimplencia;
  List<RegraCobranca> regrasCobranca = RegraCobranca.padrao();

  bool loading = true;
  bool useMock = true;
  String? initError;

  RealtimeChannel? _realtimeChannel;

  AppState() {
    init();
  }

  static const _themePrefKey = 'pulguinha_theme_mode';
  static const _adminMuralPrefKey = 'pulguinha_admin_participa_mural';

  Future<void> init() async {
    loading = true;
    initError = null;
    notifyListeners();

    try {
      await _loadThemeMode();
      await _loadAdminMuralPref();
      await _loadFinanceSettings();
      await NotificationScheduler.instance.loadSettings();
      notificationSettings = await NotificationSettingsStorage.instance.load();
      await NotificationScheduler.instance.refreshSettings(notificationSettings);

      if (SupabaseConfig.isConfigured) {
        final conectou = await _sincronizarDadosSupabase(includeFotosAlunos: false);
        if (!conectou) {
          initError = 'Modo offline (dados locais)';
          _carregarMock();
          await _carregarIndicacoesMock();
        }
      } else {
        _carregarMock();
        await _carregarIndicacoesMock();
      }
    } catch (e, st) {
      debugPrint('Erro na inicialização do app: $e\n$st');
      initError = 'Falha ao iniciar. Usando dados locais.';
      _carregarMock();
      await _carregarIndicacoesMock();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void _carregarMock() {
    useMock = true;
    alunos = _aplicarCodigosIndicacao(List.from(MockData.alunosIniciais));
    horarios = _processarHorarios(List.from(MockData.horariosIniciais));
    agendamentos = List.from(MockData.agendamentosIniciais);
    produtos = List.from(MockData.produtosLoja);
    presencas = MockData.presencasIniciais();
    postsTurma = MockData.postsTurmaIniciais();
    avisos = MockData.avisosIniciais();
    eventos = MockData.eventosIniciais();
    dicas = MockData.dicasIniciais();
    desafios = MockData.desafiosIniciais();
  }

  String _gerarCodigoIndicacao(Aluno aluno) {
    final nomeBase = aluno.nome.trim().isEmpty ? 'ALUNO' : aluno.nome.trim().split(' ').first;
    final letras = nomeBase.replaceAll(RegExp(r'[^A-Za-z]'), '').toUpperCase();
    final prefixo =
        letras.isEmpty ? 'ALU' : (letras.length >= 3 ? letras.substring(0, 3) : letras.padRight(3, 'X'));
    final sufixo = (aluno.id % 10000).toString().padLeft(4, '0');
    return '$prefixo$sufixo';
  }

  List<Aluno> _aplicarCodigosIndicacao(List<Aluno> lista) {
    final usados = <String>{};
    final pendentesSync = <Map<String, dynamic>>[];

    final atualizados = lista.map((a) {
      var codigo = a.codigoIndicacao;
      final originalVazio = codigo.isEmpty;
      if (codigo.isEmpty) {
        var tentativa = _gerarCodigoIndicacao(a);
        while (usados.contains(tentativa)) {
          tentativa = '${tentativa}X';
        }
        codigo = tentativa;
      }
      usados.add(codigo);
      if (!useMock && originalVazio) {
        pendentesSync.add({'id': a.id, 'codigo': codigo});
      }
      return a.copyWith(codigoIndicacao: codigo);
    }).toList();

    for (final item in pendentesSync) {
      SupabaseService.instance
          .updateAlunoFields(item['id'] as int, {'codigo_indicacao': item['codigo']})
          .catchError((Object e) {
        debugPrint('Erro ao salvar codigo_indicacao: $e');
        return null;
      });
    }

    return atualizados;
  }

  Future<void> _carregarIndicacoesMock() async {
    indicacoes = await ReferralStorage.instance.loadIndicacoes();
  }

  Future<void> _persistirIndicacoes() async {
    if (useMock) {
      await ReferralStorage.instance.saveIndicacoes(indicacoes);
    }
  }

  Aluno? buscarAlunoPorCodigoIndicacao(String codigo) {
    final norm = codigo.trim().toUpperCase();
    if (norm.isEmpty) return null;
    return alunos.where((a) => a.codigoIndicacao.toUpperCase() == norm).firstOrNull;
  }

  Indicacao? indicacaoPorIndicado(int indicadoId) =>
      indicacoes.where((i) => i.indicadoId == indicadoId).firstOrNull;

  bool indicadoElegivelDesconto(int indicadoId) {
    final ind = indicacaoPorIndicado(indicadoId);
    return ind != null && ind.status == 'pendente';
  }

  int indicacoesConvertidasPor(int indicadorId) =>
      indicacoes.where((i) => i.indicadorId == indicadorId && i.status == 'convertida').length;

  String? validarCodigoIndicacao(String codigo, {int? indicadoId}) {
    final norm = codigo.trim().toUpperCase();
    if (norm.isEmpty) return null;
    final indicador = buscarAlunoPorCodigoIndicacao(norm);
    if (indicador == null) return 'Código de indicação inválido.';
    if (indicadoId != null && indicador.id == indicadoId) {
      return 'Você não pode usar seu próprio código.';
    }
    if (indicadoId != null && indicacaoPorIndicado(indicadoId) != null) {
      return 'Este cadastro já possui indicação.';
    }
    return null;
  }

  Future<String?> registrarIndicacao(String codigo, int indicadoId) async {
    final erro = validarCodigoIndicacao(codigo, indicadoId: indicadoId);
    if (erro != null) return erro;
    final norm = codigo.trim().toUpperCase();
    if (norm.isEmpty) return null;

    final indicador = buscarAlunoPorCodigoIndicacao(norm)!;
    final nova = Indicacao(
      id: DateTime.now().millisecondsSinceEpoch,
      indicadorId: indicador.id,
      indicadoId: indicadoId,
      codigoUsado: norm,
      status: 'pendente',
      dataCriacao: MockData.today,
    );

    if (useMock) {
      indicacoes = [...indicacoes, nova];
      await _persistirIndicacoes();
      notifyListeners();
      return null;
    }

    try {
      final saved = await SupabaseService.instance.insertIndicacao(nova);
      indicacoes = [saved, ...indicacoes];
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('Erro insertIndicacao: $e');
      return 'Erro ao registrar indicação: ${e.toString().split('\n').first}';
    }
  }

  void _processarPagamentoIndicacao(int compradorId, double creditoUsado, {required bool converterIndicacao}) {
    if (creditoUsado > 0) {
      alunos = alunos.map((a) {
        if (a.id != compradorId) return a;
        final novo = (a.creditoIndicacao - creditoUsado).clamp(0.0, double.infinity);
        return a.copyWith(creditoIndicacao: novo);
      }).toList();
      if (usuario?.id == compradorId) {
        usuario = alunos.firstWhere((a) => a.id == compradorId).toUsuario();
      }
      _syncAluno(compradorId);
    }

    if (!converterIndicacao) {
      if (creditoUsado > 0) notifyListeners();
      return;
    }

    final ind = indicacaoPorIndicado(compradorId);
    if (ind == null || ind.status != 'pendente') {
      if (creditoUsado > 0) notifyListeners();
      return;
    }

    final regra = regraPorTipo('indique_ganhe');
    final bonusIndicador = regra?.valorFixo ?? 30;
    final convertida = ind.copyWith(status: 'convertida', dataConversao: MockData.today);
    indicacoes = indicacoes.map((i) => i.id == ind.id ? convertida : i).toList();

    alunos = alunos.map((a) {
      if (a.id == ind.indicadorId) {
        return a.copyWith(creditoIndicacao: a.creditoIndicacao + bonusIndicador);
      }
      return a;
    }).toList();

    if (useMock) {
      _persistirIndicacoes();
    } else {
      SupabaseService.instance.updateIndicacao(convertida).catchError((Object e) {
        debugPrint('Erro ao converter indicação: $e');
        return convertida;
      });
      _syncAluno(ind.indicadorId);
    }
    notifyListeners();
  }

  void registrarCompraProduto(int alunoId, Produto produto) {
    final detalhe = detalharPrecoComRegras(produto, aluno: alunoPorId(alunoId));
    _processarPagamentoIndicacao(alunoId, detalhe.creditoIndicador, converterIndicacao: false);
  }

  Future<List<Indicacao>> _fetchIndicacoesSafe() async {
    try {
      return await SupabaseService.instance.fetchIndicacoes();
    } catch (e) {
      debugPrint('Indicações indisponíveis (rode migration_indique_ganhe.sql): $e');
      return [];
    }
  }

  Future<List<DicaTreino>> _fetchDicasSafe() async {
    try {
      final list = await SupabaseService.instance.fetchDicas();
      return list.isEmpty ? MockData.dicasIniciais() : list;
    } catch (e) {
      debugPrint('Dicas indisponíveis (rode migration_mural_dicas_desafios.sql): $e');
      return MockData.dicasIniciais();
    }
  }

  Future<List<Desafio>> _fetchDesafiosSafe() async {
    try {
      return await SupabaseService.instance.fetchDesafios();
    } catch (e) {
      debugPrint('Desafios indisponíveis: $e');
      return MockData.desafiosIniciais();
    }
  }

  Future<List<DesafioProgresso>> _fetchDesafioProgressoSafe() async {
    try {
      return await SupabaseService.instance.fetchDesafioProgresso();
    } catch (e) {
      debugPrint('Progresso desafios indisponível: $e');
      return [];
    }
  }

  Future<List<Aviso>> _fetchAvisosSafe() async {
    try {
      return await SupabaseService.instance.fetchAvisos();
    } catch (e) {
      debugPrint('Avisos indisponíveis (rode migration_comunicacao.sql): $e');
      return [];
    }
  }

  Future<List<EventoEstudio>> _fetchEventosSafe() async {
    try {
      return await SupabaseService.instance.fetchEventos();
    } catch (e) {
      debugPrint('Eventos indisponíveis (rode migration_comunicacao.sql): $e');
      return [];
    }
  }

  Future<List<Presenca>> _fetchPresencasSafe() async {
    try {
      return await SupabaseService.instance.fetchPresencas();
    } catch (e) {
      debugPrint('Presenças indisponíveis: $e');
      return presencas;
    }
  }

  Future<List<PostTurma>> _fetchPostsTurmaSafe() async {
    try {
      return await SupabaseService.instance.fetchPostsTurma();
    } catch (e) {
      debugPrint('Posts turma indisponíveis: $e');
      return postsTurma;
    }
  }

  /// Carrega dados do Supabase sem cair em mock por falha em tabela secundária.
  /// Retorna true quando horários/agenda/produtos/alunos foram sincronizados.
  Future<bool> _sincronizarDadosSupabase({bool includeFotosAlunos = false}) async {
    if (!SupabaseConfig.isConfigured) return false;
    try {
      await SupabaseBootstrap.ensureInitialized(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
      final svc = SupabaseService.instance;
      final results = await Future.wait([
        svc.fetchAlunos(includeFoto: includeFotosAlunos),
        svc.fetchHorarios(),
        svc.fetchAgendamentos(),
        svc.fetchProdutos(),
        _fetchPresencasSafe(),
        _fetchPostsTurmaSafe(),
        _fetchAvisosSafe(),
        _fetchEventosSafe(),
        _fetchDicasSafe(),
        _fetchDesafiosSafe(),
        _fetchDesafioProgressoSafe(),
        _fetchIndicacoesSafe(),
      ]);
      alunos = _aplicarCodigosIndicacao(results[0] as List<Aluno>);
      horarios = _processarHorarios(results[1] as List<Horario>);
      agendamentos = results[2] as List<Agendamento>;
      produtos = results[3] as List<Produto>;
      presencas = results[4] as List<Presenca>;
      postsTurma = results[5] as List<PostTurma>;
      avisos = results[6] as List<Aviso>;
      eventos = results[7] as List<EventoEstudio>;
      dicas = results[8] as List<DicaTreino>;
      desafios = results[9] as List<Desafio>;
      desafioProgresso = results[10] as List<DesafioProgresso>;
      indicacoes = results[11] as List<Indicacao>;
      useMock = false;
      initError = null;
      alunos = _aplicarCodigosIndicacao(alunos);
      _atualizarInadimplentes();
      try {
        _subscribeRealtime();
      } catch (e) {
        debugPrint('Realtime indisponível (dados online OK): $e');
      }
      notifyListeners();
      return true;
    } catch (e, st) {
      debugPrint('Supabase indisponível, usando mock: $e\n$st');
      return false;
    }
  }

  Future<void> _carregarProgressoAluno(int alunoId) async {
    if (useMock) return;
    try {
      final all = await SupabaseService.instance.fetchDesafioProgresso();
      desafioProgresso = [
        ...desafioProgresso.where((p) => p.alunoId != alunoId),
        ...all.where((p) => p.alunoId == alunoId),
      ];
      notifyListeners();
    } catch (e) {
      debugPrint('Progresso desafio: $e');
    }
  }

  Future<void> _loadAdminMuralPref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      adminParticipaMural = prefs.getBool(_adminMuralPrefKey) ?? false;
    } catch (e) {
      debugPrint('Erro pref mural admin: $e');
    }
  }

  Future<void> setAdminParticipaMural(bool value) async {
    adminParticipaMural = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_adminMuralPrefKey, value);
    } catch (e) {
      debugPrint('Erro ao salvar pref mural: $e');
    }
  }

  Future<void> _atualizarFotoAlunoLogado(String email) async {
    if (useMock || !SupabaseConfig.isConfigured) return;
    try {
      final remoto = await SupabaseService.instance.buscarAlunoPorEmail(email);
      if (remoto == null) return;
      alunos = alunos
          .map((a) => a.email.toLowerCase() == email.toLowerCase() ? remoto : a)
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Foto do aluno logado: $e');
    }
  }

  Future<void> _carregarLeiturasAluno(int alunoId) async {
    if (useMock) return;
    try {
      comunicacaoLidas = await SupabaseService.instance.fetchLeiturasAluno(alunoId);
      notifyListeners();
    } catch (e) {
      debugPrint('Leituras: $e');
    }
  }

  Future<void> _agendarNotificacoesUsuario() async {
    NotificationScheduler.instance.setDiasParaInadimplencia(diasParaInadimplencia);
    await NotificationScheduler.instance.rescheduleAll(
      agendamentos: agendamentos,
      alunos: alunos,
      horarios: horarios,
      alunoLogadoId: usuario?.tipo == UserType.aluno ? usuario?.id : null,
      isAdmin: usuario?.isAdmin ?? false,
      diasParaInadimplencia: diasParaInadimplencia,
    );
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
        recarregarDados(includeFotosAlunos: true);
      }
    }
    if (!user.isAdmin && user.id != null) {
      _carregarLeiturasAluno(user.id!);
      _carregarProgressoAluno(user.id!);
      _atualizarFotoAlunoLogado(user.email);
    }
    _agendarNotificacoesUsuario();
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
      recarregarDados(includeFotosAlunos: tab == 'alunos');
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

  /// Valida check-in Wellhub/TotalPass e entra com aluno vinculado.
  /// Retorna (usuário, mensagem de erro).
  Future<(Usuario?, String?)> autenticarComBeneficio({
    required PartnerProvider provider,
    required String identifier,
    TotalpassIdentifierType identifierType = TotalpassIdentifierType.token,
  }) async {
    final validation = await PartnerAccessService.instance.validate(
      provider: provider,
      identifier: identifier,
      identifierType: identifierType,
      mode: PartnerAccessMode.validate,
    );
    if (!validation.ok) {
      return (null, validation.message ?? 'Benefício inválido.');
    }

    final normalized = validation.identifier ?? identifier.trim();
    Aluno? aluno;

    if (provider == PartnerProvider.wellhub) {
      aluno = alunos.where((a) => a.wellhubId == normalized).firstOrNull;
      if (aluno == null && !useMock) {
        aluno = await SupabaseService.instance.buscarAlunoPorWellhubId(normalized);
      }
    } else {
      aluno = alunos.where((a) => a.totalpassCpf == normalized).firstOrNull;
      if (aluno == null && !useMock) {
        aluno = await SupabaseService.instance.buscarAlunoPorTotalpassCpf(normalized);
      }
    }

    if (aluno == null) {
      return (
        null,
        'Benefício validado, mas nenhuma conta está vinculada. Peça ao professor para cadastrar seu ID ${provider.label}.',
      );
    }
    if (aluno.status == 'Pendente') {
      return (null, 'Cadastro aguardando aprovação do professor.');
    }
    if (aluno.status != 'Ativo' && aluno.status != 'Inadimplente') {
      return (null, 'Conta com status "${aluno.status}". Fale com o professor.');
    }

    return (aluno.toUsuario(), null);
  }

  Aluno? buscarAlunoPorBeneficio(PartnerProvider provider, String identifier) {
    final normalized = identifier.replaceAll(RegExp(r'\D'), '');
    if (normalized.isEmpty) return null;
    if (provider == PartnerProvider.wellhub) {
      final id = normalized.padLeft(13, '0');
      final gympassId = id.length > 13 ? id.substring(id.length - 13) : id;
      return alunos.where((a) => a.wellhubId == gympassId).firstOrNull;
    }
    final cpf = normalized.length > 11 ? normalized.substring(normalized.length - 11) : normalized;
    return alunos.where((a) => a.totalpassCpf == cpf).firstOrNull;
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

  Future<String?> cadastrarAlunoPublico(Aluno dados, {String? codigoIndicacao}) async {
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
      alunos = _aplicarCodigosIndicacao([...alunos, saved]);
      if (codigoIndicacao != null && codigoIndicacao.trim().isNotEmpty) {
        final errInd = await registrarIndicacao(codigoIndicacao, saved.id);
        if (errInd != null) debugPrint('Indicação não registrada: $errInd');
      }
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
      final ok = await _sincronizarDadosSupabase(includeFotosAlunos: false);
      if (ok) await _agendarNotificacoesUsuario();
      return ok;
    } catch (e) {
      debugPrint('Falha ao conectar Supabase: $e');
      initError = 'Sem conexão com o banco';
      notifyListeners();
      return false;
    }
  }

  void validarAluno(int id, {String? vencimento}) {
    alunos = alunos.map((a) {
      if (a.id != id) return a;
      return a.copyWith(
        status: 'Ativo',
        vencimento: vencimento ?? calcularVencimentoParaPlano(a.plano),
      );
    }).toList();
    notifyListeners();
    _syncAluno(id);
  }

  String calcularVencimentoParaPlano(String plano, [String? baseIso]) {
    return VencimentoHelper.calcularVencimentoInicial(plano, diaVencimentoPadrao, baseIso);
  }

  Future<void> setDiaVencimentoPadrao(int dia) async {
    diaVencimentoPadrao = dia.clamp(1, 28);
    await FinanceSettingsStorage.instance.saveDiaVencimento(diaVencimentoPadrao);
    notifyListeners();
  }

  Future<void> _loadFinanceSettings() async {
    diaVencimentoPadrao = await FinanceSettingsStorage.instance.loadDiaVencimento();
    diasParaInadimplencia = await FinanceSettingsStorage.instance.loadDiasInadimplencia();
    regrasCobranca = await FinanceSettingsStorage.instance.loadRegrasCobranca();
  }

  List<Horario> _ordenarHorarios(List<Horario> lista) => HorarioHelper.ordenar(lista);

  List<Horario> _processarHorarios(List<Horario> lista) => _ordenarHorarios(
        lista.map((h) => h.copyWith(hora: HorarioHelper.normalizar(h.hora))).toList(),
      );

  /// Horários sempre em ordem cronológica (06:00 antes de 09:00).
  List<Horario> get horariosOrdenados => _processarHorarios(horarios);

  Future<void> setDiasParaInadimplencia(int dias) async {
    diasParaInadimplencia = dias.clamp(1, 60);
    await FinanceSettingsStorage.instance.saveDiasInadimplencia(diasParaInadimplencia);
    _atualizarInadimplentes();
    notifyListeners();
  }

  Future<void> salvarRegrasCobranca(List<RegraCobranca> regras) async {
    regrasCobranca = regras;
    await FinanceSettingsStorage.instance.saveRegrasCobranca(regras);
    notifyListeners();
  }

  Future<void> adicionarRegraCobranca(RegraCobranca regra) async {
    regrasCobranca = [...regrasCobranca, regra];
    await FinanceSettingsStorage.instance.saveRegrasCobranca(regrasCobranca);
    notifyListeners();
  }

  RegraCobranca? regraPorTipo(String tipo) =>
      regrasCobranca.where((r) => r.tipo == tipo && r.ativo).firstOrNull;

  /// Detalha preço com desconto antecipado, indicação e crédito.
  PrecoComRegras detalharPrecoComRegras(Produto produto, {Aluno? aluno}) {
    final precoOriginal = produto.preco;
    var precoFinal = precoOriginal;
    var descontoAntecipado = 0.0;
    var descontoIndicado = 0.0;
    var creditoIndicador = 0.0;

    if (aluno != null && produto.tipo == 'plano') {
      final desconto = regraPorTipo('desconto_antecipado');
      if (desconto != null &&
          VencimentoHelper.temPlanoAtivo(aluno) &&
          DateHelper.diasAteVencimento(aluno.vencimento) > 0) {
        descontoAntecipado = precoOriginal * (desconto.valorPercent / 100);
        precoFinal -= descontoAntecipado;
      }

      final regraIndique = regraPorTipo('indique_ganhe');
      if (regraIndique != null && indicadoElegivelDesconto(aluno.id)) {
        descontoIndicado = precoOriginal * (regraIndique.valorPercent / 100);
        precoFinal -= descontoIndicado;
      }
    }

    if (aluno != null && aluno.creditoIndicacao > 0) {
      creditoIndicador = aluno.creditoIndicacao;
      if (creditoIndicador > precoFinal) creditoIndicador = precoFinal;
      precoFinal -= creditoIndicador;
    }

    if (precoFinal < 0) precoFinal = 0;

    return PrecoComRegras(
      precoOriginal: precoOriginal,
      precoFinal: precoFinal,
      descontoAntecipado: descontoAntecipado,
      descontoIndicado: descontoIndicado,
      creditoIndicador: creditoIndicador,
    );
  }

  /// Preço final com regras de cobrança (desconto antecipado, indicação, crédito).
  double calcularPrecoComRegras(Produto produto, {Aluno? aluno}) =>
      detalharPrecoComRegras(produto, aluno: aluno).precoFinal;

  void _atualizarInadimplentes() {
    final idsAlterados = <int>[];
    alunos = alunos.map((a) {
      if (a.status != 'Ativo' || !VencimentoHelper.temPlanoAtivo(a)) return a;
      final dias = DateHelper.diasAteVencimento(a.vencimento);
      if (dias < -diasParaInadimplencia) {
        idsAlterados.add(a.id);
        return a.copyWith(status: 'Inadimplente');
      }
      return a;
    }).toList();
    for (final id in idsAlterados) {
      _syncAluno(id);
    }
    if (idsAlterados.isNotEmpty) notifyListeners();
  }

  void marcarPago(int alunoId) {
    alunos = alunos.map((a) {
      if (a.id != alunoId) return a;
      return a.copyWith(
        status: 'Ativo',
        vencimento: VencimentoHelper.proximoVencimentoAposPagamento(
          plano: a.plano,
          diaVencimento: diaVencimentoPadrao,
          vencimentoAtual: a.vencimento,
        ),
      );
    }).toList();
    notifyListeners();
    _syncAluno(alunoId);
    _processarPagamentoIndicacao(alunoId, 0, converterIndicacao: true);
    final aluno = alunos.where((a) => a.id == alunoId).firstOrNull;
    if (aluno != null) {
      NotificationScheduler.instance.notifyPagamento(aluno.nome, alunoId);
    }
  }

  void salvarHorario({Horario? editando, required Horario dados}) {
    final normalizado = dados.copyWith(hora: HorarioHelper.normalizar(dados.hora));
    if (editando != null) {
      horarios = _ordenarHorarios(horarios.map((h) => h.id == editando.id ? normalizado : h).toList());
      if (!useMock) {
        SupabaseService.instance.updateHorario(normalizado).catchError((Object e) {
          debugPrint('Erro ao atualizar horário: $e');
          return normalizado;
        });
      }
    } else {
      final novo = normalizado.copyWith(id: DateTime.now().millisecondsSinceEpoch);
      horarios = _ordenarHorarios([...horarios, novo]);
      if (!useMock) {
        SupabaseService.instance.insertHorario(novo).then((saved) {
          horarios = _ordenarHorarios(horarios.map((h) => h.id == novo.id ? saved : h).toList());
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

  void renovarPlano(Aluno aluno) {
    alunos = alunos.map((a) {
      if (a.id != aluno.id) return a;
      return a.copyWith(
        status: 'Ativo',
        vencimento: VencimentoHelper.proximoVencimentoAposPagamento(
          plano: aluno.plano,
          diaVencimento: diaVencimentoPadrao,
          vencimentoAtual: aluno.vencimento,
        ),
      );
    }).toList();
    notifyListeners();
    _syncAluno(aluno.id);
  }

  void ativarPlanoAluno(int alunoId, Produto produto) {
    final alunoAntes = alunoPorId(alunoId);
    final detalhe = detalharPrecoComRegras(produto, aluno: alunoAntes);
    final plano = produto.nome.replaceFirst('Plano ', '');
    alunos = alunos.map((a) {
      if (a.id != alunoId) return a;
      return a.copyWith(
        plano: plano,
        status: 'Ativo',
        vencimento: VencimentoHelper.proximoVencimentoAposPagamento(
          plano: plano,
          diaVencimento: diaVencimentoPadrao,
          vencimentoAtual: a.vencimento,
        ),
      );
    }).toList();
    if (usuario?.id == alunoId) {
      final atualizado = alunos.firstWhere((a) => a.id == alunoId);
      usuario = atualizado.toUsuario();
    }
    notifyListeners();
    _syncAluno(alunoId);
    _processarPagamentoIndicacao(alunoId, detalhe.creditoIndicador, converterIndicacao: true);
  }

  void _syncAluno(int alunoId) {
    if (useMock) return;
    final aluno = alunos.firstWhere((a) => a.id == alunoId);
    SupabaseService.instance.updateAluno(aluno).catchError((Object e) {
      debugPrint('Erro ao sincronizar aluno: $e');
      return aluno;
    });
  }

  Future<void> recarregarDados({bool includeFotosAlunos = false}) async {
    if (!SupabaseConfig.isConfigured) return;
    try {
      final ok = await _sincronizarDadosSupabase(includeFotosAlunos: includeFotosAlunos);
      if (!ok) {
        initError = 'Sem conexão com o banco';
        notifyListeners();
        throw StateError('Sem conexão com o banco');
      }
      await _agendarNotificacoesUsuario();
    } catch (e) {
      debugPrint('Erro ao recarregar dados: $e');
      if (initError == null) initError = 'Sem conexão com o banco';
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
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'avisos',
          callback: (_) => _syncAvisosFromServer(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'eventos',
          callback: (_) => _syncEventosFromServer(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'posts_turma',
          callback: (_) => _syncPostsTurmaFromServer(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'comunicacao_leituras',
          callback: (_) {
            final u = usuario;
            if (u?.tipo != UserType.aluno || u?.id == null) return;
            _carregarLeiturasAluno(u!.id!);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'dicas_treino',
          callback: (_) => _syncDicasFromServer(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'desafios',
          callback: (_) => _syncDesafiosFromServer(),
        )
        .subscribe();
  }

  Future<void> _syncPostsTurmaFromServer() async {
    try {
      postsTurma = await SupabaseService.instance.fetchPostsTurma();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao sincronizar mural: $e');
    }
  }

  Future<void> _syncDicasFromServer() async {
    try {
      dicas = await _fetchDicasSafe();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao sincronizar dicas: $e');
    }
  }

  Future<void> _syncDesafiosFromServer() async {
    try {
      desafios = await _fetchDesafiosSafe();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao sincronizar desafios: $e');
    }
  }

  Future<void> _syncAlunosFromServer() async {
    try {
      alunos = _aplicarCodigosIndicacao(await SupabaseService.instance.fetchAlunos(includeFoto: true));
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao sincronizar alunos: $e');
    }
  }

  Future<void> _syncAgendamentosFromServer() async {
    try {
      agendamentos = await SupabaseService.instance.fetchAgendamentos();
      await _agendarNotificacoesUsuario();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao sincronizar agendamentos: $e');
    }
  }

  Future<void> _syncAvisosFromServer() async {
    try {
      avisos = await _fetchAvisosSafe();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao sincronizar avisos: $e');
    }
  }

  Future<void> _syncEventosFromServer() async {
    try {
      eventos = await _fetchEventosSafe();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao sincronizar eventos: $e');
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
    int? alunoId,
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

    agendamentos = [...agendamentos, novo];
    notifyListeners();

    if (useMock) {
      _agendarNotificacoesUsuario();
      return;
    }

    SupabaseService.instance.insertAgendamento(novo).then((saved) {
      agendamentos = agendamentos.map((a) => a.id == novo.id ? saved : a).toList();
      notifyListeners();
      _agendarNotificacoesUsuario();
    }).catchError((Object e) {
      debugPrint('Erro ao criar agendamento: $e');
      agendamentos = agendamentos.where((a) => a.id != novo.id).toList();
      notifyListeners();
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

    _atualizarDesafiosAluno(alunoId, checkin: true);

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

  List<PostTurma> postsDaTurma(int horarioId, {bool incluirOcultos = false}) {
    return postsTurma
        .where((p) => p.horarioId == horarioId && (incluirOcultos || !p.oculto))
        .toList()
      ..sort((a, b) {
        if (a.fixado != b.fixado) return a.fixado ? -1 : 1;
        return b.dataHora.compareTo(a.dataHora);
      });
  }

  int contagemAlunosTurma(int horarioId) =>
      alunos.where((a) => a.horarioId == horarioId && a.status == 'Ativo').length;

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

  Future<void> setNotificationSettings(NotificationSettings settings) async {
    notificationSettings = settings;
    await NotificationSettingsStorage.instance.save(settings);
    await NotificationScheduler.instance.refreshSettings(settings);
    await _agendarNotificacoesUsuario();
    notifyListeners();
  }

  List<Aviso> avisosAtivos() => avisos.where((a) => a.ativo).toList()
    ..sort((a, b) {
      if (a.fixado != b.fixado) return a.fixado ? -1 : 1;
      return b.dataHora.compareTo(a.dataHora);
    });

  List<EventoEstudio> eventosProximos({int dias = 30}) {
    final limite = DateTime.now().add(Duration(days: dias));
    return eventos.where((e) => e.ativo && e.dataInicio.isBefore(limite) && e.dataInicio.isAfter(DateTime.now().subtract(const Duration(days: 1)))).toList()
      ..sort((a, b) => a.dataInicio.compareTo(b.dataInicio));
  }

  bool comunicacaoLida(String tipo, int itemId) => comunicacaoLidas.contains('${tipo}_$itemId');

  int mencoesNaoLidas(int alunoId) {
    var n = 0;
    for (final a in avisosAtivos()) {
      if (MentionHelper.alunoMencionado(alunoId, a.mencoes) && !comunicacaoLida('aviso', a.id)) n++;
    }
    for (final e in eventosProximos()) {
      if (MentionHelper.alunoMencionado(alunoId, e.mencoes) && !comunicacaoLida('evento', e.id)) n++;
    }
    return n;
  }

  List<Aviso> avisosParaAluno(int alunoId) {
    return avisosAtivos().where((a) => a.notificarTodos || MentionHelper.alunoMencionado(alunoId, a.mencoes)).toList();
  }

  void marcarComunicacaoLida(int alunoId, String itemTipo, int itemId) {
    comunicacaoLidas.add('${itemTipo}_$itemId');
    notifyListeners();
    if (!useMock) {
      SupabaseService.instance.marcarComunicacaoLida(alunoId, itemTipo, itemId).catchError((Object e) {
        debugPrint('Erro ao marcar leitura: $e');
        return null;
      });
    }
  }

  void publicarAviso({
    required String titulo,
    required String texto,
    required List<int> mencoes,
    bool notificarTodos = true,
    bool fixado = false,
  }) {
    final aviso = Aviso(
      id: DateTime.now().millisecondsSinceEpoch,
      titulo: titulo.trim(),
      texto: texto.trim(),
      autor: usuario?.nome ?? 'Admin',
      dataHora: DateTime.now(),
      mencoes: mencoes,
      notificarTodos: notificarTodos,
      fixado: fixado,
    );
    if (useMock) {
      avisos = [aviso, ...avisos];
    } else {
      SupabaseService.instance.insertAviso(aviso).then((saved) {
        avisos = [saved, ...avisos];
        notifyListeners();
      }).catchError((Object e) {
        debugPrint('Erro aviso: $e');
      });
    }
    notifyListeners();
    NotificationScheduler.instance.notifyComunicacao(
      tipo: NotificationPayloadType.aviso,
      titulo: aviso.titulo,
      corpo: aviso.texto.length > 80 ? '${aviso.texto.substring(0, 80)}...' : aviso.texto,
      notificarTodos: notificarTodos,
      mencoes: mencoes,
      alunosAtivos: alunos.where((a) => a.status == 'Ativo').toList(),
      itemId: aviso.id,
    );
  }

  void publicarEvento({
    required String titulo,
    required String descricao,
    required DateTime dataInicio,
    DateTime? dataFim,
    String? local,
    required List<int> mencoes,
    bool notificarTodos = true,
    int lembreteDiasAntes = 1,
  }) {
    final evento = EventoEstudio(
      id: DateTime.now().millisecondsSinceEpoch,
      titulo: titulo.trim(),
      descricao: descricao.trim(),
      dataInicio: dataInicio,
      dataFim: dataFim,
      local: local,
      mencoes: mencoes,
      notificarTodos: notificarTodos,
      lembreteDiasAntes: lembreteDiasAntes,
      criadoEm: DateTime.now(),
    );
    if (useMock) {
      eventos = [...eventos, evento];
    } else {
      SupabaseService.instance.insertEvento(evento).then((saved) {
        eventos = [...eventos, saved];
        notifyListeners();
      }).catchError((Object e) {
        debugPrint('Erro evento: $e');
      });
    }
    notifyListeners();
    final lembrete = dataInicio.subtract(Duration(days: lembreteDiasAntes));
    NotificationScheduler.instance.notifyComunicacao(
      tipo: NotificationPayloadType.evento,
      titulo: evento.titulo,
      corpo: DateHelper.formatarDataHora(evento.dataInicio),
      notificarTodos: notificarTodos,
      mencoes: mencoes,
      alunosAtivos: alunos.where((a) => a.status == 'Ativo').toList(),
      itemId: evento.id,
      lembreteEvento: lembrete,
    );
  }

  void removerAviso(int id) {
    avisos = avisos.where((a) => a.id != id).toList();
    notifyListeners();
    if (!useMock) SupabaseService.instance.deleteAviso(id).catchError((Object e) => debugPrint('$e'));
  }

  void removerEvento(int id) {
    eventos = eventos.where((e) => e.id != id).toList();
    notifyListeners();
    if (!useMock) SupabaseService.instance.deleteEvento(id).catchError((Object e) => debugPrint('$e'));
  }

  // —— Senhas ——

  Future<String?> alterarSenhaAluno(int alunoId, String senhaAtual, String novaSenha) async {
    final aluno = alunoPorId(alunoId);
    if (aluno == null) return 'Aluno não encontrado.';
    if (aluno.senha != senhaAtual) return 'Senha atual incorreta.';
    if (novaSenha.length < 4) return 'Mínimo 4 caracteres.';
    alunos = alunos.map((a) => a.id == alunoId ? a.copyWith(senha: novaSenha) : a).toList();
    if (usuario?.id == alunoId) usuario = alunos.firstWhere((a) => a.id == alunoId).toUsuario();
    notifyListeners();
    if (!useMock) {
      try {
        await SupabaseService.instance.updateAlunoSenha(alunoId, novaSenha);
      } catch (e) {
        return 'Erro ao salvar senha: $e';
      }
    }
    return null;
  }

  Future<String?> alterarSenhaAdmin(String email, String senhaAtual, String novaSenha) async {
    if (novaSenha.length < 4) return 'Mínimo 4 caracteres.';
    if (useMock) {
      if (senhaAtual != 'admin123') return 'Senha atual incorreta.';
      return null;
    }
    try {
      final ok = await SupabaseService.instance.autenticarAdmin(email, senhaAtual);
      if (ok == null) return 'Senha atual incorreta.';
      await SupabaseService.instance.updateAdminSenha(email, novaSenha);
      return null;
    } catch (e) {
      return 'Erro ao salvar: $e';
    }
  }

  Future<String?> resetarSenhaAlunoAdmin(int alunoId, String novaSenha) async {
    if (novaSenha.length < 4) return 'Mínimo 4 caracteres.';
    alunos = alunos.map((a) => a.id == alunoId ? a.copyWith(senha: novaSenha) : a).toList();
    notifyListeners();
    if (!useMock) {
      try {
        await SupabaseService.instance.updateAlunoSenha(alunoId, novaSenha);
      } catch (e) {
        return 'Erro: $e';
      }
    }
    return null;
  }

  Future<String?> dicaRecuperacaoSenha(String email) async {
    final em = email.trim().toLowerCase();
    Aluno? aluno;
    if (useMock) {
      aluno = alunos.where((a) => a.email.toLowerCase() == em).firstOrNull;
    } else {
      try {
        aluno = await SupabaseService.instance.buscarAlunoPorEmail(em);
      } catch (_) {
        aluno = alunos.where((a) => a.email.toLowerCase() == em).firstOrNull;
      }
    }
    if (aluno == null) return null;
    final primeiro = aluno.nome.split(' ').first;
    final tel = aluno.telefone.length >= 4 ? '***${aluno.telefone.substring(aluno.telefone.length - 4)}' : '';
    return 'Cadastro encontrado ($primeiro). Fale com a recepção do Pulguinha para resetar sua senha${tel.isNotEmpty ? ' (tel. $tel)' : ''}.';
  }

  // —— Mural moderação ——

  void publicarPostTurmaAdmin({
    required String nomeAdmin,
    required int horarioId,
    required String texto,
    TipoPostTurma tipo = TipoPostTurma.texto,
    String? figurinha,
    String? linkUrl,
    List<String> enqueteOpcoes = const [],
  }) {
    final trimmed = texto.trim();
    if (tipo == TipoPostTurma.texto && trimmed.isEmpty) return;
    final post = PostTurma(
      id: DateTime.now().millisecondsSinceEpoch,
      alunoId: 0,
      nomeAluno: nomeAdmin,
      horarioId: horarioId,
      texto: trimmed,
      dataHora: DateTime.now(),
      tipo: tipo,
      autorTipo: AutorPostTurma.admin,
      figurinha: figurinha,
      linkUrl: linkUrl?.trim(),
      enqueteOpcoes: enqueteOpcoes.where((o) => o.trim().isNotEmpty).toList(),
    );
    postsTurma = [post, ...postsTurma];
    notifyListeners();
    if (!useMock) {
      SupabaseService.instance.insertPostTurma(post).then((saved) {
        postsTurma = postsTurma.map((p) => p.id == post.id ? saved : p).toList();
        notifyListeners();
      }).catchError((Object e) {
        debugPrint('Erro post admin: $e');
      });
    }
  }

  void moderarPostTurma(int postId, {bool? oculto, bool? fixado}) {
    postsTurma = postsTurma.map((p) {
      if (p.id != postId) return p;
      return p.copyWith(oculto: oculto ?? p.oculto, fixado: fixado ?? p.fixado);
    }).toList();
    notifyListeners();
    if (!useMock) {
      final post = postsTurma.where((p) => p.id == postId).firstOrNull;
      if (post != null) {
        SupabaseService.instance.updatePostTurma(post).catchError((Object e) {
          debugPrint('$e');
          return post;
        });
      }
    }
  }

  void removerPostTurma(int postId) {
    postsTurma = postsTurma.where((p) => p.id != postId).toList();
    notifyListeners();
    if (!useMock) SupabaseService.instance.deletePostTurma(postId).catchError((Object e) => debugPrint('$e'));
  }

  // —— Dicas ——

  List<DicaTreino> dicasAtivas() => dicas.where((d) => d.ativo).toList()..sort((a, b) => a.ordem.compareTo(b.ordem));

  DicaTreino dicaDoDia([DateTime? date]) {
    final ativas = dicasAtivas();
    if (ativas.isEmpty) return MockData.dicasIniciais().first;
    final d = date ?? DateTime.now();
    final index = (d.year * 366 + d.month * 31 + d.day) % ativas.length;
    return ativas[index];
  }

  void salvarDica(DicaTreino dica) {
    final idx = dicas.indexWhere((d) => d.id == dica.id);
    if (idx >= 0) {
      dicas = [...dicas]..[idx] = dica;
    } else {
      dicas = [...dicas, dica];
    }
    notifyListeners();
    if (!useMock) {
      if (idx >= 0) {
        SupabaseService.instance.updateDica(dica).then((saved) {
          dicas = dicas.map((d) => d.id == dica.id ? saved : d).toList();
          notifyListeners();
        }).catchError((Object e) {
          debugPrint('$e');
        });
      } else {
        SupabaseService.instance.insertDica(dica).then((saved) {
          dicas = [...dicas.where((d) => d.id != dica.id), saved];
          notifyListeners();
        }).catchError((Object e) {
          debugPrint('$e');
        });
      }
    }
  }

  void removerDica(int id) {
    dicas = dicas.where((d) => d.id != id).toList();
    notifyListeners();
    if (!useMock) SupabaseService.instance.deleteDica(id).catchError((Object e) => debugPrint('$e'));
  }

  // —— Desafios ——

  List<Desafio> desafiosAtivos() => desafios.where((d) => d.ativo && d.vigente).toList();

  DesafioProgresso? progressoDesafio(int alunoId, int desafioId) =>
      desafioProgresso.where((p) => p.alunoId == alunoId && p.desafioId == desafioId).firstOrNull;

  void salvarDesafio(Desafio d) {
    final idx = desafios.indexWhere((x) => x.id == d.id);
    if (idx >= 0) {
      desafios = [...desafios]..[idx] = d;
    } else {
      desafios = [...desafios, d];
    }
    notifyListeners();
    if (!useMock) {
      if (idx >= 0) {
        SupabaseService.instance.updateDesafio(d).then((saved) {
          desafios = desafios.map((x) => x.id == d.id ? saved : x).toList();
          notifyListeners();
        }).catchError((Object e) {
          debugPrint('$e');
        });
      } else {
        SupabaseService.instance.insertDesafio(d).then((saved) {
          desafios = [...desafios.where((x) => x.id != d.id), saved];
          notifyListeners();
        }).catchError((Object e) {
          debugPrint('$e');
        });
      }
    }
  }

  void removerDesafio(int id) {
    desafios = desafios.where((d) => d.id != id).toList();
    desafioProgresso = desafioProgresso.where((p) => p.desafioId != id).toList();
    notifyListeners();
    if (!useMock) SupabaseService.instance.deleteDesafio(id).catchError((Object e) => debugPrint('$e'));
  }

  void registrarProgressoAgua(int alunoId, int copos) {
    _atualizarDesafiosAluno(alunoId, coposAgua: copos);
  }

  void _atualizarDesafiosAluno(int alunoId, {bool checkin = false, int? coposAgua}) {
    var mudou = false;
    for (final d in desafiosAtivos()) {
      var prog = progressoDesafio(alunoId, d.id);
      if (prog?.concluido == true) continue;

      var novo = prog?.progresso ?? 0;
      if (d.tipo == TipoDesafio.checkins && checkin) novo++;
      if (d.tipo == TipoDesafio.streak && checkin) novo = alunoPorId(alunoId)?.streakPresenca ?? 0;
      if (d.tipo == TipoDesafio.agua && coposAgua != null) novo = coposAgua;

      final concluiu = novo >= d.meta;
      final atualizado = DesafioProgresso(
        desafioId: d.id,
        alunoId: alunoId,
        progresso: novo.clamp(0, d.meta),
        concluidoEm: concluiu ? DateTime.now() : null,
      );

      desafioProgresso = [
        ...desafioProgresso.where((p) => !(p.desafioId == d.id && p.alunoId == alunoId)),
        atualizado,
      ];
      mudou = true;

      if (concluiu && prog?.concluido != true && d.pontosRecompensa > 0) {
        alunos = alunos.map((a) {
          if (a.id != alunoId) return a;
          return a.copyWith(pulguinhaPoints: a.pulguinhaPoints + d.pontosRecompensa);
        }).toList();
        if (usuario?.id == alunoId) usuario = alunos.firstWhere((a) => a.id == alunoId).toUsuario();
        if (!useMock) _syncAluno(alunoId);
      }
    }
    if (mudou) {
      notifyListeners();
      if (!useMock) {
        for (final p in desafioProgresso.where((x) => x.alunoId == alunoId)) {
          SupabaseService.instance.upsertDesafioProgresso(p).catchError((Object e) => debugPrint('$e'));
        }
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
