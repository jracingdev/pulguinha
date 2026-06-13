import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/utils/date_helper.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

class AdminAlunosScreen extends StatefulWidget {
  const AdminAlunosScreen({super.key});

  @override
  State<AdminAlunosScreen> createState() => _AdminAlunosScreenState();
}

class _AdminAlunosScreenState extends State<AdminAlunosScreen> {
  String busca = '';
  String filtro = 'Todos';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lista = state.alunos.where((a) {
      final mb = a.nome.toLowerCase().contains(busca.toLowerCase()) || a.email.toLowerCase().contains(busca.toLowerCase());
      final mf = filtro == 'Todos' || a.status == filtro;
      return mb && mf;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ALUNOS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.white)),
            NeonButton(label: '+ Novo', onPressed: () => _abrirModal(context, state)),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: (v) => setState(() => busca = v),
          decoration: const InputDecoration(hintText: 'Buscar por nome ou e-mail...', prefixIcon: Icon(Icons.search, color: AppColors.gray)),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: ['Todos', 'Ativo', 'Inadimplente'].map((f) {
            final selected = filtro == f;
            return ChoiceChip(
              label: Text(f),
              selected: selected,
              onSelected: (_) => setState(() => filtro = f),
              selectedColor: AppColors.neon,
              labelStyle: TextStyle(color: selected ? const Color(0xFF111111) : AppColors.gray, fontWeight: FontWeight.w700, fontSize: 12),
              backgroundColor: AppColors.card2,
              side: BorderSide.none,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        ...lista.map((a) => _alunoCard(context, state, a)),
      ],
    );
  }

  Widget _alunoCard(BuildContext context, AppState state, Aluno a) {
    final d = DateHelper.diasAteVencimento(a.vencimento);
    final vc = d < 0 ? AppColors.red : d <= 7 ? AppColors.yellow : AppColors.gray;
    final vt = d < 0
        ? 'Vencido ${d.abs()}d'
        : d == 0
            ? 'Vence hoje!'
            : d <= 7
                ? 'Vence em ${d}d'
                : 'Venc. ${DateHelper.formatarData(a.vencimento)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PulguinhaCard(
        child: Row(
          children: [
            PulguinhaAvatar(initials: a.avatar),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(a.nome, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.white)),
                      PulguinhaBadge(label: a.status, variant: a.status == 'Ativo' ? BadgeVariant.neon : BadgeVariant.red),
                    ],
                  ),
                  Text('${a.telefone} · ${a.plano}', style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                  Text(vt, style: TextStyle(fontSize: 11, color: vc, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _abrirModal(context, state, editando: a),
              icon: const Text('✏️'),
              style: IconButton.styleFrom(backgroundColor: AppColors.neon.withValues(alpha: 0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirModal(BuildContext context, AppState state, {Aluno? editando}) async {
    final nomeCtrl = TextEditingController(text: editando?.nome ?? '');
    final emailCtrl = TextEditingController(text: editando?.email ?? '');
    final telCtrl = TextEditingController(text: editando?.telefone ?? '');
    final vencCtrl = TextEditingController(text: editando?.vencimento ?? '');
    final senhaCtrl = TextEditingController(text: editando?.senha ?? '1234');
    var plano = editando?.plano ?? 'Mensal';
    var status = editando?.status ?? 'Ativo';

    await showPulguinhaModal(
      context: context,
      title: editando == null ? 'Novo Aluno' : 'Editar Aluno',
      child: StatefulBuilder(
        builder: (ctx, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FieldLabel(label: 'Nome *', child: TextField(controller: nomeCtrl)),
              FieldLabel(label: 'E-mail', child: TextField(controller: emailCtrl)),
              FieldLabel(label: 'Telefone', child: TextField(controller: telCtrl)),
              FieldLabel(label: 'Vencimento', child: TextField(controller: vencCtrl, decoration: const InputDecoration(hintText: '2026-06-20'))),
              FieldLabel(label: 'Senha do app', child: TextField(controller: senhaCtrl, obscureText: true)),
              FieldLabel(
                label: 'Plano',
                child: DropdownButtonFormField<String>(
                  value: plano,
                  items: ['Mensal', 'Trimestral', 'Semestral', 'Anual'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setModalState(() => plano = v ?? plano),
                ),
              ),
              FieldLabel(
                label: 'Status',
                child: DropdownButtonFormField<String>(
                  value: status,
                  items: ['Ativo', 'Inadimplente', 'Inativo'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setModalState(() => status = v ?? status),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: GhostButton(label: 'Cancelar', onPressed: () => Navigator.pop(ctx))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: NeonButton(
                      label: 'Salvar',
                      onPressed: () {
                        if (nomeCtrl.text.trim().isEmpty) return;
                        final avatar = nomeCtrl.text.split(' ').map((n) => n[0]).take(2).join().toUpperCase();
                        final dados = Aluno(
                          id: editando?.id ?? DateTime.now().millisecondsSinceEpoch,
                          nome: nomeCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          telefone: telCtrl.text.trim(),
                          plano: plano,
                          vencimento: vencCtrl.text.trim(),
                          status: status,
                          senha: senhaCtrl.text,
                          avatar: editando?.avatar ?? avatar,
                        );
                        state.salvarAluno(editando: editando, dados: dados);
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
