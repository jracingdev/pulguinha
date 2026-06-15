import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/config/app_links.dart';
import 'package:pulguinha/config/supabase_config.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/screens/admin/admin_agendamentos_screen.dart';
import 'package:pulguinha/screens/admin/admin_alunos_screen.dart';
import 'package:pulguinha/screens/admin/admin_dashboard_screen.dart';
import 'package:pulguinha/screens/admin/admin_financeiro_screen.dart';
import 'package:pulguinha/screens/admin/admin_presenca_screen.dart';
import 'package:pulguinha/screens/admin/admin_produtos_screen.dart';
import 'package:pulguinha/screens/aluno/aluno_agenda_screen.dart';
import 'package:pulguinha/screens/aluno/aluno_checkin_screen.dart';
import 'package:pulguinha/screens/aluno/aluno_home_screen.dart';
import 'package:pulguinha/screens/aluno/aluno_evolucao_screen.dart';
import 'package:pulguinha/screens/aluno/aluno_turma_screen.dart';
import 'package:pulguinha/screens/aluno/aluno_perfil_screen.dart';
import 'package:pulguinha/screens/auth/login_screen.dart';
import 'package:pulguinha/screens/public/public_screen.dart';
import 'package:pulguinha/screens/shared/loja_screen.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/theme/app_theme.dart';
import 'package:pulguinha/widgets/app_shell.dart';

class PulguinhaApp extends StatelessWidget {
  const PulguinhaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: Consumer<AppState>(
        builder: (context, state, _) => MaterialApp(
          title: 'Funcional do Pulguinha',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: state.themeMode,
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const _RootRouter(),
        ),
      ),
    );
  }
}

class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (state.loading) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Image.asset(
            'assets/images/logo1.png',
            width: 280,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      );
    }

    return switch (state.screen) {
      AppScreen.public => PublicScreen(initialStep: AppLinks.publicInitialStep),
      AppScreen.login => const LoginScreen(),
      AppScreen.admin => _AdminShell(state: state),
      AppScreen.aluno => _AlunoShell(state: state),
    };
  }
}

class _AdminShell extends StatelessWidget {
  const _AdminShell({required this.state});

  final AppState state;

  static const _tabs = [
    TabItem(id: 'dashboard', label: 'Início', icon: '⚡'),
    TabItem(id: 'alunos', label: 'Alunos', icon: '👥'),
    TabItem(id: 'agenda', label: 'Agenda', icon: '📅'),
    TabItem(id: 'presenca', label: 'Presença', icon: '📱'),
    TabItem(id: 'financeiro', label: 'Financ.', icon: '💰'),
    TabItem(id: 'loja', label: 'Loja', icon: '🛒'),
  ];

  @override
  Widget build(BuildContext context) {
    final body = switch (state.adminTab) {
      'dashboard' => const AdminDashboardScreen(),
      'alunos' => const AdminAlunosScreen(),
      'agenda' => const AdminAgendamentosScreen(),
      'presenca' => const AdminPresencaScreen(),
      'financeiro' => const AdminFinanceiroScreen(),
      'loja' => const AdminProdutosScreen(),
      _ => const AdminDashboardScreen(),
    };

    return AppShell(
      tabs: _tabs,
      activeTab: state.adminTab,
      onTabChanged: state.setAdminTab,
      onLogout: state.logout,
      headerRight: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.neon.withValues(alpha: 0.1),
          border: Border.all(color: AppColors.neon.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('ADMIN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.neon)),
      ),
      onRefresh: SupabaseConfig.isConfigured
          ? () async {
              if (state.useMock) await state.garantirConexaoSupabase();
              await state.recarregarDados();
            }
          : null,
      child: body,
    );
  }
}

class _AlunoShell extends StatelessWidget {
  const _AlunoShell({required this.state});

  final AppState state;

  static const _tabs = [
    TabItem(id: 'home', label: 'Início', icon: '🏠'),
    TabItem(id: 'turma', label: 'Turma', icon: '👥'),
    TabItem(id: 'evolucao', label: 'Evolução', icon: '📈'),
    TabItem(id: 'checkin', label: 'Check-in', icon: '📷'),
    TabItem(id: 'agenda', label: 'Agenda', icon: '📅'),
    TabItem(id: 'loja', label: 'Loja', icon: '🛒'),
    TabItem(id: 'perfil', label: 'Perfil', icon: '👤'),
  ];

  @override
  Widget build(BuildContext context) {
    final usuario = state.usuario!;
    final body = switch (state.alunoTab) {
      'home' => AlunoHomeScreen(usuario: usuario),
      'turma' => AlunoTurmaScreen(usuario: usuario),
      'evolucao' => const AlunoEvolucaoScreen(),
      'checkin' => AlunoCheckinScreen(usuario: usuario),
      'agenda' => AlunoAgendaScreen(usuario: usuario),
      'loja' => LojaScreen(usuario: usuario),
      'perfil' => AlunoPerfilScreen(usuario: usuario, onLogout: state.logout),
      _ => AlunoHomeScreen(usuario: usuario),
    };

    return AppShell(
      tabs: _tabs,
      activeTab: state.alunoTab,
      onTabChanged: state.setAlunoTab,
      onLogout: state.logout,
      headerRight: Text(
        'Olá, ${usuario.nome.split(' ').first}',
        style: const TextStyle(fontSize: 12, color: AppColors.gray, fontWeight: FontWeight.w600),
      ),
      onRefresh: SupabaseConfig.isConfigured
          ? () async {
              if (state.useMock) await state.garantirConexaoSupabase();
              await state.recarregarDados();
            }
          : null,
      child: body,
    );
  }
}
