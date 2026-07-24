import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/utils/date_helper.dart';
import 'package:pulguinha/data/mock_data.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/services/viacep_service.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/utils/vencimento_helper.dart';
import 'package:pulguinha/utils/photo_picker_helper.dart';
import 'package:pulguinha/widgets/change_password_dialog.dart';
import 'package:pulguinha/widgets/date_field.dart';
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
        if (state.alunosPendentes > 0) ...[
          PulguinhaCard(
            borderColor: AppColors.neon.withValues(alpha: 0.35),
            backgroundColor: AppColors.neon.withValues(alpha: 0.06),
            child: Row(
              children: [
                const Text('⏳', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${state.alunosPendentes} cadastro(s) aguardando aprovação — filtre por "Pendente" ou puxe a tela para atualizar.',
                    style: const TextStyle(fontSize: 12, color: AppColors.neon, fontWeight: FontWeight.w600, decoration: TextDecoration.none),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        ...lista.map((a) => _alunoCard(context, state, a)),
      ],
    );
  }

  Widget _alunoCard(BuildContext context, AppState state, Aluno a) {
    final vt = VencimentoHelper.textoCurto(a);
    final vc = VencimentoHelper.cor(a);
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
                  if (a.alunoDesde != null && a.alunoDesde!.isNotEmpty)
                    Text('Aluno desde ${DateHelper.formatarData(a.alunoDesde!)}', style: const TextStyle(fontSize: 11, color: AppColors.grayDim)),
                  if (a.horarioId != null)
                    Text('Turma: ${state.labelTurma(a)}', style: const TextStyle(fontSize: 11, color: AppColors.neon, fontWeight: FontWeight.w600)),
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
              )
            else if (a.status == 'Ativo' && DateHelper.diasAteVencimento(a.vencimento) <= 7)
              IconButton(
                onPressed: () {
                  state.marcarPago(a.id);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pagamento registrado — ${a.nome}')));
                },
                icon: const Text('💰'),
                tooltip: 'Dar baixa manual',
                style: IconButton.styleFrom(backgroundColor: AppColors.neon.withValues(alpha: 0.1)),
              )
            else if (a.status == 'Inadimplente')
              IconButton(
                onPressed: () {
                  state.marcarPago(a.id);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pagamento registrado — ${a.nome}')));
                },
                icon: const Text('💰'),
                tooltip: 'Dar baixa manual',
                style: IconButton.styleFrom(backgroundColor: AppColors.neon.withValues(alpha: 0.1)),
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
    final cepCtrl = TextEditingController(text: editando?.cep ?? '');
    final logradouroCtrl = TextEditingController(text: editando?.logradouro ?? '');
    final numeroCtrl = TextEditingController(text: editando?.numero ?? '');
    final complementoCtrl = TextEditingController(text: editando?.complemento ?? '');
    final bairroCtrl = TextEditingController(text: editando?.bairro ?? '');
    final cidadeCtrl = TextEditingController(text: editando?.cidade ?? '');
    final ufCtrl = TextEditingController(text: editando?.uf ?? '');
    final vencCtrl = TextEditingController(
      text: editando != null && editando.status != 'Pendente'
          ? DateHelper.formatarData(editando.vencimento)
          : DateHelper.formatarData(state.calcularVencimentoParaPlano(editando?.plano ?? 'Mensal')),
    );
    final alunoDesdeCtrl = TextEditingController(
      text: editando?.alunoDesde != null && editando!.alunoDesde!.isNotEmpty
          ? DateHelper.formatarData(editando.alunoDesde!)
          : editando?.dataCadastro != null
              ? DateHelper.formatarData(editando!.dataCadastro!)
              : DateHelper.formatarData(MockData.today),
    );
    final nascCtrl = TextEditingController(text: editando?.dataNascimento != null && editando!.dataNascimento!.isNotEmpty ? DateHelper.formatarData(editando.dataNascimento!) : '');
    final senhaCtrl = TextEditingController(text: editando?.senha ?? '1234');
    final restrCtrl = TextEditingController(text: editando?.anamnese.restricoesMedicas ?? '');
    final medCtrl = TextEditingController(text: editando?.anamnese.medicamentos ?? '');
    final objCtrl = TextEditingController(text: editando?.anamnese.objetivoTreino ?? '');
    final emergCtrl = TextEditingController(text: editando?.anamnese.contatoEmergencia ?? '');
    final emergTelCtrl = TextEditingController(text: editando?.anamnese.telefoneEmergencia ?? '');
    final wellhubCtrl = TextEditingController(text: editando?.wellhubId ?? '');
    final totalpassCpfCtrl = TextEditingController(text: editando?.totalpassCpf ?? '');
    var plano = editando?.plano ?? 'Mensal';
    var status = editando?.status ?? 'Ativo';
    var nivel = editando?.anamnese.nivelExperiencia ?? 'Iniciante';
    int? turmaId = editando?.horarioId;
    String? fotoBase64 = editando?.foto;
    var cepLoading = false;
    String? cepErro;

    Future<void> buscarCep(void Function(void Function()) setModalState) async {
      setModalState(() {
        cepErro = null;
        cepLoading = true;
      });
      final res = await ViaCepService.instance.buscar(cepCtrl.text.trim());
      if (!context.mounted) return;
      setModalState(() => cepLoading = false);
      if (res == null || res.erro) {
        setModalState(() => cepErro = 'CEP inválido ou não encontrado.');
        return;
      }
      setModalState(() {
        logradouroCtrl.text = res.logradouro;
        bairroCtrl.text = res.bairro;
        cidadeCtrl.text = res.cidade;
        ufCtrl.text = res.uf;
      });
    }

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
                const SizedBox(height: 8),
                const SectionTitle(icon: '🎫', title: 'GymPass / TotalPass'),
                FieldLabel(
                  label: 'ID GymPass (13 dígitos)',
                  child: TextField(
                    controller: wellhubCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Para login via app GymPass'),
                  ),
                ),
                FieldLabel(
                  label: 'CPF TotalPass',
                  child: TextField(
                    controller: totalpassCpfCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Somente números — para login TotalPass'),
                  ),
                ),
                const SizedBox(height: 8),
                const SectionTitle(icon: '📍', title: 'Endereço'),
                FieldLabel(
                  label: 'CEP',
                  child: TextField(
                    controller: cepCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: '00000-000',
                      suffixIcon: cepLoading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : (cepCtrl.text.trim().length == 8 ? const Icon(Icons.search, color: AppColors.neon) : null),
                    ),
                    onChanged: (v) {
                      setModalState(() => cepErro = null);
                      final digits = v.replaceAll(RegExp(r'\D'), '');
                      if (digits.length == 8 && !cepLoading) buscarCep(setModalState);
                    },
                  ),
                ),
                if (cepErro != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      '⚠️ $cepErro',
                      style: const TextStyle(color: AppColors.red, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                FieldLabel(label: 'Logradouro', child: TextField(controller: logradouroCtrl)),
                Row(
                  children: [
                    Expanded(
                      child: FieldLabel(
                        label: 'Número',
                        child: TextField(controller: numeroCtrl, keyboardType: TextInputType.number),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FieldLabel(label: 'Complemento', child: TextField(controller: complementoCtrl)),
                    ),
                  ],
                ),
                FieldLabel(label: 'Bairro', child: TextField(controller: bairroCtrl)),
                FieldLabel(label: 'Cidade', child: TextField(controller: cidadeCtrl)),
                FieldLabel(
                  label: 'UF',
                  child: TextField(
                    controller: ufCtrl,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 2,
                  ),
                ),
                FieldLabel(
                  label: 'Data nascimento',
                  child: DateField(
                    controller: nascCtrl,
                    lastDate: DateTime.now(),
                    hintText: '13-06-1995',
                  ),
                ),
                FieldLabel(
                  label: 'Aluno desde',
                  child: DateField(controller: alunoDesdeCtrl, lastDate: DateTime.now().add(const Duration(days: 365))),
                ),
                FieldLabel(
                  label: 'Vencimento da mensalidade',
                  child: DateField(
                    controller: vencCtrl,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                    hintText: VencimentoHelper.hintVencimento(plano, state.diaVencimentoPadrao),
                    enabled: status != 'Pendente',
                  ),
                ),
                FieldLabel(label: 'Senha do app', child: TextField(controller: senhaCtrl, obscureText: true)),
                FieldLabel(
                  label: 'Plano',
                  child: DropdownButtonFormField<String>(
                    value: plano,
                    items: ['Mensal', 'Trimestral', 'Semestral', 'Anual'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (v) => setModalState(() {
                      plano = v ?? plano;
                      if (status != 'Pendente') {
                        vencCtrl.text = DateHelper.formatarData(state.calcularVencimentoParaPlano(plano));
                      }
                    }),
                  ),
                ),
                FieldLabel(
                  label: 'Status',
                  child: DropdownButtonFormField<String>(
                    value: status,
                    items: ['Ativo', 'Pendente', 'Inadimplente', 'Inativo'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setModalState(() {
                      status = v ?? status;
                      if (status == 'Pendente') {
                        vencCtrl.clear();
                      } else if (vencCtrl.text.trim().isEmpty) {
                        vencCtrl.text = DateHelper.formatarData(state.calcularVencimentoParaPlano(plano));
                      }
                    }),
                  ),
                ),
                FieldLabel(
                  label: 'Turma principal (controle — não restringe agendamentos)',
                  child: DropdownButtonFormField<int?>(
                    value: turmaId,
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Sem turma')),
                      ...state.horariosOrdenados.map((h) => DropdownMenuItem<int?>(
                            value: h.id,
                            child: Text('${h.hora} · ${h.dias}'),
                          )),
                    ],
                    onChanged: (v) => setModalState(() => turmaId = v),
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
                if (editando != null) ...[
                  const SizedBox(height: 8),
                  GhostButton(
                    label: '📧 Enviar link de redefinição por e-mail',
                    fullWidth: true,
                    onPressed: () async {
                      final msg = await state.solicitarRedefinicaoSenha(editando.email);
                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text(msg), duration: const Duration(seconds: 6)),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  GhostButton(
                    label: '🔑 Definir senha temporária',
                    fullWidth: true,
                    onPressed: () async {
                      final nova = await showResetPasswordDialog(ctx, nomeAluno: editando.nome);
                      if (nova == null || nova.isEmpty) return;
                      final err = await state.resetarSenhaAlunoAdmin(editando.id, nova);
                      if (!ctx.mounted) return;
                      if (err != null) {
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(err)));
                      } else {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Nova senha: $nova — informe ao aluno'), duration: const Duration(seconds: 8)),
                        );
                      }
                    },
                  ),
                ],
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
                          final alunoDesde = alunoDesdeCtrl.text.trim().isEmpty ? MockData.today : DateHelper.paraIso(alunoDesdeCtrl.text.trim());
                          String vencimento;
                          if (status == 'Pendente') {
                            vencimento = MockData.vencimentoPendente;
                          } else if (vencCtrl.text.trim().isEmpty) {
                            vencimento = state.calcularVencimentoParaPlano(plano);
                          } else {
                            vencimento = DateHelper.paraIso(vencCtrl.text.trim());
                          }
                          final dados = Aluno(
                            id: editando?.id ?? DateTime.now().millisecondsSinceEpoch,
                            nome: nomeCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                            telefone: telCtrl.text.trim(),
                            cep: cepCtrl.text.trim(),
                            logradouro: logradouroCtrl.text.trim(),
                            numero: numeroCtrl.text.trim(),
                            complemento: complementoCtrl.text.trim(),
                            bairro: bairroCtrl.text.trim(),
                            cidade: cidadeCtrl.text.trim(),
                            uf: ufCtrl.text.trim(),
                            plano: plano,
                            vencimento: vencimento,
                            status: status,
                            senha: senhaCtrl.text,
                            avatar: editando?.avatar ?? avatar,
                            dataNascimento: nascCtrl.text.trim().isEmpty ? null : DateHelper.paraIso(nascCtrl.text.trim()),
                            anamnese: anamnese,
                            foto: fotoBase64,
                            streakPresenca: editando?.streakPresenca ?? 0,
                            pulguinhaPoints: editando?.pulguinhaPoints ?? 0,
                            dataCadastro: editando?.dataCadastro ?? MockData.today,
                            alunoDesde: alunoDesde,
                            horarioId: turmaId,
                            codigoIndicacao: editando?.codigoIndicacao ?? '',
                            creditoIndicacao: editando?.creditoIndicacao ?? 0,
                            wellhubId: wellhubCtrl.text.trim().isEmpty
                                ? null
                                : wellhubCtrl.text.replaceAll(RegExp(r'\D'), ''),
                            totalpassCpf: totalpassCpfCtrl.text.trim().isEmpty
                                ? null
                                : totalpassCpfCtrl.text.replaceAll(RegExp(r'\D'), ''),
                            beneficioOrigem: wellhubCtrl.text.trim().isNotEmpty
                                ? 'wellhub'
                                : (totalpassCpfCtrl.text.trim().isNotEmpty ? 'totalpass' : editando?.beneficioOrigem),
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

  Future<void> _validar(BuildContext context, AppState state, Aluno a) async {
    final vencCtrl = TextEditingController(text: DateHelper.formatarData(state.calcularVencimentoParaPlano(a.plano)));
    var jaPagou = false;

    await showPulguinhaModal(
      context: context,
      title: 'Aprovar ${a.nome}',
      child: StatefulBuilder(
        builder: (ctx, setModal) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Plano ${a.plano} · vencimento padrão dia ${state.diaVencimentoPadrao}',
                style: const TextStyle(fontSize: 12, color: AppColors.gray),
              ),
              const SizedBox(height: 12),
              FieldLabel(
                label: 'Primeiro vencimento',
                child: DateField(
                  controller: vencCtrl,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  hintText: VencimentoHelper.hintVencimento(a.plano, state.diaVencimentoPadrao),
                ),
              ),
              CheckboxListTile(
                value: jaPagou,
                onChanged: (v) => setModal(() => jaPagou = v ?? false),
                title: const Text('Primeira mensalidade já recebida', style: TextStyle(fontSize: 12, color: AppColors.white)),
                subtitle: const Text('Avança o vencimento para o próximo ciclo', style: TextStyle(fontSize: 11, color: AppColors.gray)),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.neon,
              ),
              const SizedBox(height: 8),
              NeonButton(
                label: '✅ Aprovar aluno',
                fullWidth: true,
                onPressed: () {
                  var venc = vencCtrl.text.trim().isEmpty
                      ? state.calcularVencimentoParaPlano(a.plano)
                      : DateHelper.paraIso(vencCtrl.text.trim());
                  if (jaPagou) {
                    venc = VencimentoHelper.proximoVencimentoAposPagamento(
                      plano: a.plano,
                      diaVencimento: state.diaVencimentoPadrao,
                      vencimentoAtual: venc,
                    );
                  }
                  state.validarAluno(a.id, vencimento: venc);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${a.nome} aprovado com sucesso!')));
                },
              ),
            ],
          );
        },
      ),
    );
    vencCtrl.dispose();
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
