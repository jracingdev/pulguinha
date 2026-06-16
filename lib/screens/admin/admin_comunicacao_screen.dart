import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/utils/date_helper.dart';
import 'package:pulguinha/utils/mention_helper.dart';
import 'package:pulguinha/widgets/date_field.dart';
import 'package:pulguinha/widgets/mention_text_field.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

class AdminComunicacaoScreen extends StatefulWidget {
  const AdminComunicacaoScreen({super.key});

  @override
  State<AdminComunicacaoScreen> createState() => _AdminComunicacaoScreenState();
}

class _AdminComunicacaoScreenState extends State<AdminComunicacaoScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('COMUNICAÇÃO', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.white)),
        const SizedBox(height: 4),
        const Text('Quadro de avisos e agenda de eventos do estúdio', style: TextStyle(fontSize: 12, color: AppColors.gray)),
        const SizedBox(height: 16),
        TabBar(
          controller: _tabs,
          labelColor: AppColors.neon,
          unselectedLabelColor: AppColors.gray,
          indicatorColor: AppColors.neon,
          tabs: const [
            Tab(text: 'Avisos'),
            Tab(text: 'Eventos'),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 500,
          child: TabBarView(
            controller: _tabs,
            children: [
              _avisosTab(state),
              _eventosTab(state),
            ],
          ),
        ),
      ],
    );
  }

  Widget _avisosTab(AppState state) {
    final lista = state.avisosAtivos();
    return ListView(
      children: [
        NeonButton(label: '+ Novo aviso', fullWidth: true, onPressed: () => _modalAviso(state)),
        const SizedBox(height: 16),
        if (lista.isEmpty)
          const PulguinhaCard(child: Text('Nenhum aviso publicado.', style: TextStyle(color: AppColors.gray)))
        else
          ...lista.map((a) => _avisoCard(state, a)),
      ],
    );
  }

  Widget _eventosTab(AppState state) {
    final lista = state.eventosProximos(dias: 365);
    return ListView(
      children: [
        NeonButton(label: '+ Novo evento', fullWidth: true, onPressed: () => _modalEvento(state)),
        const SizedBox(height: 16),
        if (lista.isEmpty)
          const PulguinhaCard(child: Text('Nenhum evento agendado.', style: TextStyle(color: AppColors.gray)))
        else
          ...lista.map((e) => _eventoCard(state, e)),
      ],
    );
  }

  Widget _avisoCard(AppState state, Aviso a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PulguinhaCard(
        borderColor: a.fixado ? AppColors.neon.withValues(alpha: 0.35) : AppColors.border,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(a.titulo, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.white))),
                if (a.fixado) const PulguinhaBadge(label: 'Fixado', variant: BadgeVariant.neon),
              ],
            ),
            const SizedBox(height: 6),
            MentionText(text: a.texto),
            const SizedBox(height: 8),
            Text(DateHelper.formatarDataHora(a.dataHora), style: const TextStyle(fontSize: 10, color: AppColors.gray)),
            if (a.mencoes.isNotEmpty)
              Text('@ ${a.mencoes.length} aluno(s)', style: const TextStyle(fontSize: 10, color: AppColors.neon, fontWeight: FontWeight.w700)),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: () => state.removerAviso(a.id), child: const Text('Remover', style: TextStyle(color: AppColors.red, fontSize: 11))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _eventoCard(AppState state, EventoEstudio e) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PulguinhaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(e.titulo, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.white)),
            const SizedBox(height: 4),
            Text(DateHelper.formatarDataHora(e.dataInicio), style: const TextStyle(fontSize: 12, color: AppColors.neon, fontWeight: FontWeight.w700)),
            if (e.local != null && e.local!.isNotEmpty) Text(e.local!, style: const TextStyle(fontSize: 11, color: AppColors.gray)),
            if (e.descricao.isNotEmpty) ...[
              const SizedBox(height: 6),
              MentionText(text: e.descricao),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: () => state.removerEvento(e.id), child: const Text('Remover', style: TextStyle(color: AppColors.red, fontSize: 11))),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _modalAviso(AppState state) async {
    final tituloCtrl = TextEditingController();
    final textoCtrl = TextEditingController();
    var notificarTodos = true;
    var fixado = false;
    var mencoes = <int>[];

    await showPulguinhaModal(
      context: context,
      title: 'Novo aviso',
      child: StatefulBuilder(
        builder: (ctx, setModal) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FieldLabel(label: 'Título', child: TextField(controller: tituloCtrl)),
            FieldLabel(
              label: 'Mensagem (@ para marcar aluno)',
              child: MentionTextField(
                controller: textoCtrl,
                alunos: state.alunos,
                onMencoesChanged: (ids) => mencoes = ids,
              ),
            ),
            SwitchListTile(
              value: notificarTodos,
              onChanged: (v) => setModal(() => notificarTodos = v),
              title: const Text('Notificar todos', style: TextStyle(fontSize: 12, color: AppColors.white)),
              activeColor: AppColors.neon,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: fixado,
              onChanged: (v) => setModal(() => fixado = v),
              title: const Text('Fixar no topo', style: TextStyle(fontSize: 12, color: AppColors.white)),
              activeColor: AppColors.neon,
              contentPadding: EdgeInsets.zero,
            ),
            NeonButton(
              label: 'Publicar',
              fullWidth: true,
              onPressed: () {
                if (tituloCtrl.text.trim().isEmpty) return;
                final ids = {...mencoes, ...MentionHelper.parseMencoesFromText(textoCtrl.text, state.alunos)}.toList();
                state.publicarAviso(
                  titulo: tituloCtrl.text,
                  texto: textoCtrl.text,
                  mencoes: ids,
                  notificarTodos: notificarTodos,
                  fixado: fixado,
                );
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
    tituloCtrl.dispose();
    textoCtrl.dispose();
  }

  Future<void> _modalEvento(AppState state) async {
    final tituloCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final localCtrl = TextEditingController();
    final inicioCtrl = TextEditingController(text: DateHelper.formatarData(DateHelper.hojeIso()));
    final fimCtrl = TextEditingController();
    var notificarTodos = true;
    var mencoes = <int>[];
    var lembrete = 1;

    await showPulguinhaModal(
      context: context,
      title: 'Novo evento',
      child: StatefulBuilder(
        builder: (ctx, setModal) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FieldLabel(label: 'Título', child: TextField(controller: tituloCtrl)),
              FieldLabel(label: 'Descrição', child: MentionTextField(controller: descCtrl, alunos: state.alunos, onMencoesChanged: (ids) => mencoes = ids)),
              FieldLabel(label: 'Data início', child: DateField(controller: inicioCtrl, firstDate: DateTime.now())),
              FieldLabel(label: 'Data fim (opcional)', child: DateField(controller: fimCtrl, firstDate: DateTime.now())),
              FieldLabel(label: 'Local', child: TextField(controller: localCtrl)),
              FieldLabel(
                label: 'Lembrete (dias antes)',
                child: DropdownButtonFormField<int>(
                  value: lembrete,
                  items: [1, 2, 3, 7].map((d) => DropdownMenuItem(value: d, child: Text('$d dia(s)'))).toList(),
                  onChanged: (v) => setModal(() => lembrete = v ?? 1),
                ),
              ),
              SwitchListTile(
                value: notificarTodos,
                onChanged: (v) => setModal(() => notificarTodos = v),
                title: const Text('Notificar todos', style: TextStyle(fontSize: 12, color: AppColors.white)),
                activeColor: AppColors.neon,
                contentPadding: EdgeInsets.zero,
              ),
              NeonButton(
                label: 'Criar evento',
                fullWidth: true,
                onPressed: () {
                  if (tituloCtrl.text.trim().isEmpty) return;
                  final inicio = DateHelper.parseData(DateHelper.paraIso(inicioCtrl.text.trim()));
                  final fim = fimCtrl.text.trim().isEmpty ? null : DateHelper.parseData(DateHelper.paraIso(fimCtrl.text.trim()));
                  final ids = {...mencoes, ...MentionHelper.parseMencoesFromText(descCtrl.text, state.alunos)}.toList();
                  state.publicarEvento(
                    titulo: tituloCtrl.text,
                    descricao: descCtrl.text,
                    dataInicio: inicio,
                    dataFim: fim,
                    local: localCtrl.text.trim(),
                    mencoes: ids,
                    notificarTodos: notificarTodos,
                    lembreteDiasAntes: lembrete,
                  );
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
    tituloCtrl.dispose();
    descCtrl.dispose();
    localCtrl.dispose();
    inicioCtrl.dispose();
    fimCtrl.dispose();
  }
}
