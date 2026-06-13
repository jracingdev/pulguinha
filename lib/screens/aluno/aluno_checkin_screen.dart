import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/utils/qr_helper.dart';
import 'package:pulguinha/widgets/celebration_widgets.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';
import 'package:pulguinha/widgets/qr_widgets.dart';

class AlunoCheckinScreen extends StatefulWidget {
  const AlunoCheckinScreen({super.key, required this.usuario});

  final Usuario usuario;

  @override
  State<AlunoCheckinScreen> createState() => _AlunoCheckinScreenState();
}

class _AlunoCheckinScreenState extends State<AlunoCheckinScreen> {
  bool _showSuccess = false;
  String _successNome = '';
  int _successStreak = 0;
  int? _successMilestone;

  void _onScan(String raw) {
    final state = context.read<AppState>();
    final alunoId = widget.usuario.id;
    if (alunoId == null) return;

    final parsed = QrHelper.parse(raw);
    if (parsed == null) {
      _snack('QR inválido. Escaneie o QR da aula na academia.');
      return;
    }

    RegistrarPresencaResult result;
    if (parsed is QrAula) {
      result = state.registrarPresenca(
        alunoId: alunoId,
        horarioId: parsed.horarioId,
        data: parsed.data,
        tipo: TipoPresenca.scanAluno,
      );
    } else if (parsed is QrDia) {
      // Check-in no primeiro horário disponível do dia (18:00 padrão ou primeiro)
      final hor = state.horarios.where((h) => h.hora == '18:00').firstOrNull ?? state.horarios.firstOrNull;
      if (hor == null) {
        _snack('Nenhum horário configurado.');
        return;
      }
      result = state.registrarPresenca(
        alunoId: alunoId,
        horarioId: hor.id,
        data: parsed.data,
        tipo: TipoPresenca.scanAluno,
      );
    } else {
      _snack('Este QR é do aluno. Escaneie o QR da aula.');
      return;
    }

    if (!result.ok) {
      _snack(result.mensagem ?? 'Erro.');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _showSuccess = true;
      _successNome = result.aluno!.nome;
      _successStreak = result.novoStreak;
      _successMilestone = result.milestoneAtingido;
    });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.card2, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final alunoId = widget.usuario.id ?? 0;
    final minhas = state.presencasPorAluno(alunoId);
    final streak = state.alunoPorId(alunoId)?.streakPresenca ?? 0;
    final points = state.alunoPorId(alunoId)?.pulguinhaPoints ?? 0;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CHECK-IN', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.white)),
            const SizedBox(height: 8),
            Row(
              children: [
                if (streak >= 2)
                  PulguinhaBadge(label: '🔥 $streak treinos seguidos', variant: BadgeVariant.yellow),
                const SizedBox(width: 8),
                PulguinhaBadge(label: '⭐ $points pts', variant: BadgeVariant.neon),
              ],
            ),
            const SizedBox(height: 16),
            const PulguinhaCard(
              child: Column(
                children: [
                  Text('📷', style: TextStyle(fontSize: 32)),
                  SizedBox(height: 8),
                  Text('Escaneie o QR da aula', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.white)),
                  SizedBox(height: 4),
                  Text('Aponte para o cartaz na entrada do treino', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.gray)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PulguinhaQrScanner(onScan: _onScan, hint: 'QR da aula ou QR do dia'),
            const SizedBox(height: 20),
            const SectionTitle(icon: '📋', title: 'Minhas Presenças Recentes'),
            if (minhas.isEmpty)
              const PulguinhaCard(
                child: Column(
                  children: [
                    PulguinhaLogo(size: 60, showShadow: false),
                    SizedBox(height: 8),
                    Text('Nenhuma presença ainda', style: TextStyle(color: AppColors.gray)),
                    Text('Faça seu primeiro check-in! 💪', style: TextStyle(fontSize: 11, color: AppColors.grayDim)),
                  ],
                ),
              )
            else
              ...minhas.take(5).map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: PulguinhaCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Text(p.horario, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.neon, fontSize: 14)),
                          const SizedBox(width: 12),
                          Expanded(child: Text(p.data, style: const TextStyle(color: AppColors.white, fontSize: 13))),
                          PulguinhaBadge(label: 'Check-in', variant: BadgeVariant.neon),
                        ],
                      ),
                    ),
                  )),
          ],
        ),
        CheckinSuccessOverlay(
          visible: _showSuccess,
          nomeAluno: _successNome,
          streak: _successStreak,
          milestone: _successMilestone,
          onDone: () => setState(() => _showSuccess = false),
        ),
      ],
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
