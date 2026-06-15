import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/utils/date_helper.dart';
import 'package:pulguinha/data/mock_data.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/utils/photo_picker_helper.dart';
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
          children: ['Todos', 'Ativo', 'Pendente', 'Inadimplente'].map((f) {
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
    final isAniv = DateHelper.isAniversarioHoje(a.dataNascimento);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PulguinhaCard(
        child: Row(
          children: [
            PulguinhaAvatar(initials: a.avatar, fotoBase64: a.foto),
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
                      PulguinhaBadge(label: a.status, variant: _badgeVariant(a.status)),
                      if (isAniv) const PulguinhaBadge(label: '🎂 Hoje!', variant: BadgeVariant.yellow),
                      if (a.streakPresenca >= 3) PulguinhaBadge(label: '🔥 ${a.streakPresenca}', variant: BadgeVariant.yellow),
                    ],
                  ),
                  Text('${a.telefone} · ${a.plano}', style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                  Text(vt, style: TextStyle(fontSize: 11, color: vc, fontWeight: FontWeight.w600)),
                  if (!a.anamnese.isEmpty && a.anamnese.restricoesMedicas.isNotEmpty)
                    Text('⚠️ ${a.anamnese.restricoesMedicas}', style: const TextStyle(fontSize: 10, color: AppColors.yellow)),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _abrirModal(context, state, editando: a),
              icon: const Text('✏️'),
              style: IconButton.styleFrom(backgroundColor: AppColors.neon.withValues(alpha: 0.1)),
            ),
            if (a.status == 'Pendente')
              IconButton(
                onPressed: () => _validar(context, state, a),
                icon: const Text('✅'),
                tooltip: 'Aprovar cadastro',
                style: IconButton.styleFrom(backgroundColor: AppColors.neon.withValues(alpha: 0.15)),
              ),
            IconButton(
              onPressed: () => _confirmarExclusao(context, state, a),
              icon: const Text('🗑️'),
              style: IconButton.styleFrom(backgroundColor: AppColors.red.withValues(alpha: 0.1)),
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
    final vencCtrl = TextEditingController(text: editando != null ? DateHelper.formatarData(editando.vencimento) : '');
    final nascCtrl = TextEditingController(text: editando?.dataNascimento != null && editando!.dataNascimento!.isNotEmpty ? DateHelper.formatarData(editando.dataNascimento!) : '');
    final senhaCtrl = TextEditingController(text: editando?.senha ?? '1234');
    final restrCtrl = TextEditingController(text: editando?.anamnese.restricoesMedicas ?? '');
    final medCtrl = TextEditingController(text: editando?.anamnese.medicamentos ?? '');
    final objCtrl = TextEditingController(text: editando?.anamnese.objetivoTreino ?? '');
    final emergCtrl = TextEditingController(text: editando?.anamnese.contatoEmergencia ?? '');
    final emergTelCtrl = TextEditingController(text: editando?.anamnese.telefoneEmergencia ?? '');
    var plano = editando?.plano ?? 'Mensal';
    var status = editando?.status ?? 'Ativo';
    var nivel = editando?.anamnese.nivelExperiencia ?? 'Iniciante';
    String? fotoBase64 = editando?.foto;

    await showPulguinhaModal(
      context: context,
      title: editando == null ? 'Novo Aluno' : 'Editar Aluno',
      child: StatefulBuilder(
        builder: (ctx, setModalState) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FieldLabel(label: 'Nome *', child: TextField(controller: nomeCtrl)),
                FieldLabel(label: 'E-mail', child: TextField(controller: emailCtrl)),
                FieldLabel(label: 'Telefone', child: TextField(controller: telCtrl)),
                FieldLabel(label: 'Data nascimento', child: TextField(controller: nascCtrl, decoration: const InputDecoration(hintText: '13-06-1995'))),
                FieldLabel(label: 'Vencimento', child: TextField(controller: vencCtrl, decoration: const InputDecoration(hintText: '20-06-2026'))),
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
                    items: ['Ativo', 'Pendente', 'Inadimplente', 'Inativo'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setModalState(() => status = v ?? status),
                  ),
                ),
                const SectionTitle(icon: '🏥', title: 'Anamnese'),
                FieldLabel(label: 'Restrições / lesões', child: TextField(controller: restrCtrl, maxLines: 2)),
                FieldLabel(label: 'Medicamentos', child: TextField(controller: medCtrl)),
                FieldLabel(label: 'Objetivo do treino', child: TextField(controller: objCtrl)),
                FieldLabel(
                  label: 'Nível',
                  child: DropdownButtonFormField<String>(
                    value: nivel,
                    items: ['Iniciante', 'Intermediário', 'Avançado'].map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                    onChanged: (v) => setModalState(() => nivel = v ?? nivel),
                  ),
                ),
                FieldLabel(label: 'Contato emergência', child: TextField(controller: emergCtrl)),
                FieldLabel(label: 'Tel. emergência', child: TextField(controller: emergTelCtrl)),
                FieldLabel(
                  label: 'Foto',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (fotoBase64 != null && fotoBase64!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: PulguinhaAvatar(initials: editando?.avatar ?? 'AL', size: AvatarSize.lg, fotoBase64: fotoBase64),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: GhostButton(
                              label: '📷 Escolher foto',
                              onPressed: () async {
                                final base64 = await pickPhotoBase64(ctx);
                                if (base64 != null) {
                                  setModalState(() => fotoBase64 = base64);
                                }
                              },
                            ),
                          ),
                          if (fotoBase64 != null && fotoBase64!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            GhostButton(
                              label: 'Remover',
                              onPressed: () => setModalState(() => fotoBase64 = null),
                            ),
                          ],
                        ],
                      ),
                    ],
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
                          final anamnese = Anamnese(
                            restricoesMedicas: restrCtrl.text.trim(),
                            medicamentos: medCtrl.text.trim(),
                            objetivoTreino: objCtrl.text.trim(),
                            nivelExperiencia: nivel,
                            contatoEmergencia: emergCtrl.text.trim(),
                            telefoneEmergencia: emergTelCtrl.text.trim(),
                          );
                          final dados = Aluno(
                            id: editando?.id ?? DateTime.now().millisecondsSinceEpoch,
                            nome: nomeCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                            telefone: telCtrl.text.trim(),
                            plano: plano,
                            vencimento: vencCtrl.text.trim().isEmpty ? MockData.today : DateHelper.paraIso(vencCtrl.text.trim()),
                            status: status,
                            senha: senhaCtrl.text,
                            avatar: editando?.avatar ?? avatar,
                            dataNascimento: nascCtrl.text.trim().isEmpty ? null : DateHelper.paraIso(nascCtrl.text.trim()),
                            anamnese: anamnese,
                            foto: fotoBase64,
                            streakPresenca: editando?.streakPresenca ?? 0,
                            pulguinhaPoints: editando?.pulguinhaPoints ?? 0,
                            dataCadastro: editando?.dataCadastro ?? MockData.today,
                          );
                          state.salvarAluno(editando: editando, dados: dados);
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  BadgeVariant _badgeVariant(String status) {
    return switch (status) {
      'Ativo' => BadgeVariant.neon,
      'Pendente' => BadgeVariant.yellow,
      'Inadimplente' => BadgeVariant.red,
      _ => BadgeVariant.gray,
    };
  }

  void _validar(BuildContext context, AppState state, Aluno a) {
    state.validarAluno(a.id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${a.nome} aprovado com sucesso!')));
  }

  Future<void> _confirmarExclusao(BuildContext context, AppState state, Aluno a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Excluir aluno?', style: TextStyle(color: AppColors.white)),
        content: Text('Remover ${a.nome} permanentemente?', style: const TextStyle(color: AppColors.gray)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir', style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (ok == true) {
      state.removerAluno(a.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${a.nome} removido.')));
      }
    }
  }
}
