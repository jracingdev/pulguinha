import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

class AdminDicasScreen extends StatelessWidget {
  const AdminDicasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final dicas = [...state.dicas]..sort((a, b) => a.ordem.compareTo(b.ordem));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        title: const Text('Dicas de Evolução', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.neon),
            onPressed: () => _abrirForm(context, state),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: dicas.length,
          itemBuilder: (ctx, i) {
          final d = dicas[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PulguinhaCard(
              child: Row(
                children: [
                  Text(d.icon, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.titulo, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: d.ativo ? AppColors.white : AppColors.grayDim)),
                        Text(d.categoria, style: const TextStyle(fontSize: 10, color: AppColors.gray)),
                      ],
                    ),
                  ),
                  if (!d.ativo) const PulguinhaBadge(label: 'Off', variant: BadgeVariant.gray),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: AppColors.gray, size: 18),
                    onSelected: (v) {
                      if (v == 'edit') _abrirForm(context, state, editando: d);
                      if (v == 'toggle') state.salvarDica(d.copyWith(ativo: !d.ativo));
                      if (v == 'del') state.removerDica(d.id);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'toggle', child: Text('Ativar/Desativar')),
                      PopupMenuItem(value: 'del', child: Text('Excluir', style: TextStyle(color: AppColors.red))),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
          ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.neon,
        foregroundColor: AppColors.bg,
        onPressed: () => _abrirForm(context, state),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _abrirForm(BuildContext context, AppState state, {DicaTreino? editando}) {
    final iconCtrl = TextEditingController(text: editando?.icon ?? '💡');
    final tituloCtrl = TextEditingController(text: editando?.titulo ?? '');
    final textoCtrl = TextEditingController(text: editando?.texto ?? '');
    final catCtrl = TextEditingController(text: editando?.categoria ?? 'Geral');
    final ordemCtrl = TextEditingController(text: '${editando?.ordem ?? state.dicas.length}');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(editando == null ? 'Nova dica' : 'Editar dica', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.white)),
            const SizedBox(height: 12),
            FieldLabel(label: 'Ícone', child: TextField(controller: iconCtrl)),
            FieldLabel(label: 'Título', child: TextField(controller: tituloCtrl)),
            FieldLabel(label: 'Categoria', child: TextField(controller: catCtrl)),
            FieldLabel(label: 'Texto', child: TextField(controller: textoCtrl, maxLines: 4)),
            FieldLabel(label: 'Ordem', child: TextField(controller: ordemCtrl, keyboardType: TextInputType.number)),
            const SizedBox(height: 12),
            NeonButton(
              label: 'Salvar',
              fullWidth: true,
              onPressed: () {
                final dica = DicaTreino(
                  id: editando?.id ?? DateTime.now().millisecondsSinceEpoch,
                  icon: iconCtrl.text.trim().isEmpty ? '💡' : iconCtrl.text.trim(),
                  titulo: tituloCtrl.text.trim(),
                  texto: textoCtrl.text.trim(),
                  categoria: catCtrl.text.trim(),
                  ordem: int.tryParse(ordemCtrl.text) ?? 0,
                  ativo: editando?.ativo ?? true,
                );
                if (dica.titulo.isEmpty || dica.texto.isEmpty) return;
                state.salvarDica(dica);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
