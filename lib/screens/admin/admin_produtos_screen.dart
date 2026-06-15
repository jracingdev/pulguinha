import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

class AdminProdutosScreen extends StatelessWidget {
  const AdminProdutosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final planos = state.produtos.where((p) => p.tipo == 'plano').toList();
    final outros = state.produtos.where((p) => p.tipo != 'plano').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('LOJA', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.white)),
            NeonButton(label: '+ Novo', onPressed: () => _abrirModal(context, state)),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Edite valores dos planos e produtos da loja.', style: TextStyle(fontSize: 12, color: AppColors.gray)),
        const SizedBox(height: 20),
        const SectionTitle(icon: '📅', title: 'Planos'),
        ...planos.map((p) => _produtoCard(context, state, p)),
        const SizedBox(height: 16),
        const SectionTitle(icon: '👕', title: 'Produtos'),
        if (outros.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('Nenhum produto além dos planos.', style: TextStyle(fontSize: 12, color: AppColors.gray)),
          ),
        ...outros.map((p) => _produtoCard(context, state, p)),
      ],
    );
  }

  Widget _produtoCard(BuildContext context, AppState state, Produto p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PulguinhaCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.neon.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(p.emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.nome, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.white)),
                  Text(p.desc, style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                  Text('R\$ ${p.preco.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.neon)),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _abrirModal(context, state, editando: p),
              icon: const Text('✏️'),
              style: IconButton.styleFrom(backgroundColor: AppColors.neon.withValues(alpha: 0.1)),
            ),
            IconButton(
              onPressed: () => _confirmarExclusao(context, state, p),
              icon: const Text('🗑️'),
              style: IconButton.styleFrom(backgroundColor: AppColors.red.withValues(alpha: 0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarExclusao(BuildContext context, AppState state, Produto p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Excluir item?', style: TextStyle(color: AppColors.white)),
        content: Text('Remover "${p.nome}" da loja?', style: const TextStyle(color: AppColors.gray)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir', style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (ok == true) state.removerProduto(p.id);
  }

  Future<void> _abrirModal(BuildContext context, AppState state, {Produto? editando}) async {
    final nomeCtrl = TextEditingController(text: editando?.nome ?? '');
    final descCtrl = TextEditingController(text: editando?.desc ?? '');
    final precoCtrl = TextEditingController(text: editando != null ? editando.preco.toStringAsFixed(2) : '');
    final emojiCtrl = TextEditingController(text: editando?.emoji ?? '📦');
    var tipo = editando?.tipo ?? 'produto';

    await showPulguinhaModal(
      context: context,
      title: editando == null ? 'Novo Item' : 'Editar Item',
      child: StatefulBuilder(
        builder: (ctx, setModal) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FieldLabel(label: 'Nome *', child: TextField(controller: nomeCtrl)),
                FieldLabel(label: 'Descrição', child: TextField(controller: descCtrl, maxLines: 2)),
                FieldLabel(label: 'Preço (R\$) *', child: TextField(controller: precoCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                FieldLabel(label: 'Emoji', child: TextField(controller: emojiCtrl, decoration: const InputDecoration(hintText: '📅'))),
                FieldLabel(
                  label: 'Tipo',
                  child: DropdownButtonFormField<String>(
                    value: tipo,
                    items: const [
                      DropdownMenuItem(value: 'plano', child: Text('Plano')),
                      DropdownMenuItem(value: 'produto', child: Text('Produto')),
                      DropdownMenuItem(value: 'avulso', child: Text('Avulso')),
                    ],
                    onChanged: (v) => setModal(() => tipo = v ?? tipo),
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
                          final preco = double.tryParse(precoCtrl.text.replaceAll(',', '.')) ?? 0;
                          final dados = Produto(
                            id: editando?.id ?? 0,
                            nome: nomeCtrl.text.trim(),
                            desc: descCtrl.text.trim(),
                            preco: preco,
                            tipo: tipo,
                            emoji: emojiCtrl.text.trim().isEmpty ? '📦' : emojiCtrl.text.trim(),
                          );
                          state.salvarProduto(editando: editando, dados: dados);
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
}
