import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/config/app_links.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/utils/photo_picker_helper.dart';
import 'package:pulguinha/widgets/admin_page_layout.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

class AdminProdutosScreen extends StatelessWidget {
  const AdminProdutosScreen({super.key, this.standalone = false});

  final bool standalone;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final planos = state.produtos.where((p) => p.tipo == 'plano').toList();
    final outros = state.produtos.where((p) => p.tipo != 'plano').toList();

    final children = <Widget>[
      _linkPublicoCard(context),
      const SectionTitle(icon: '📅', title: 'Planos'),
      ...planos.map((p) => _produtoCard(context, state, p)),
      const SizedBox(height: 16),
      const SectionTitle(icon: '👕', title: 'Produtos'),
      if (outros.isEmpty)
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('Nenhum produto além dos planos.', style: TextStyle(fontSize: 12, color: AppColors.gray, decoration: TextDecoration.none)),
        ),
      ...outros.map((p) => _produtoCard(context, state, p)),
    ];

    if (standalone) {
      return AdminStandalonePage(
        title: 'Loja',
        subtitle: 'Edite valores dos planos e produtos da loja.',
        actionLabel: '+ Novo',
        onAction: () => _abrirModal(context, state),
        children: children,
      );
    }

    return AdminTabPage(
      title: 'LOJA',
      subtitle: 'Edite valores dos planos e produtos da loja.',
      actionLabel: '+ Novo',
      onAction: () => _abrirModal(context, state),
      children: children,
    );
  }

  Widget _linkPublicoCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: PulguinhaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(icon: '🔗', title: 'Link público da loja'),
            const SizedBox(height: 4),
            SelectableText(
              AppLinks.lojaPublicUrl,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.neon, decoration: TextDecoration.none),
            ),
            const SizedBox(height: 6),
            Text(
              'Atalho curto: ${AppLinks.lojaShortUrl} (configure redirecionamento no Registro.br)',
              style: const TextStyle(fontSize: 10, color: AppColors.gray, decoration: TextDecoration.none),
            ),
            const SizedBox(height: 10),
            GhostButton(
              label: '📋 Copiar link da loja',
              fullWidth: true,
              borderColor: AppColors.neon.withValues(alpha: 0.25),
              textColor: AppColors.neon,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: AppLinks.lojaPublicUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copiado!'), behavior: SnackBarBehavior.floating),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _produtoCard(BuildContext context, AppState state, Produto p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PulguinhaCard(
        child: Row(
          children: [
            _produtoThumb(p),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.nome, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.white, decoration: TextDecoration.none)),
                  Text(p.desc, style: const TextStyle(fontSize: 11, color: AppColors.gray, decoration: TextDecoration.none)),
                  if (p.grades.isNotEmpty)
                    Text('Grades: ${p.grades.join(' · ')}', style: const TextStyle(fontSize: 10, color: AppColors.neon, decoration: TextDecoration.none)),
                  Text('R\$ ${p.preco.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.neon, decoration: TextDecoration.none)),
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

  Widget _produtoThumb(Produto p) {
    if (p.foto != null && p.foto!.isNotEmpty) {
      try {
        final bytes = base64Decode(p.foto!.contains(',') ? p.foto!.split(',').last : p.foto!);
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(bytes, width: 48, height: 48, fit: BoxFit.cover),
        );
      } catch (_) {}
    }
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.neon.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(p.emoji, style: const TextStyle(fontSize: 24)),
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
    final gradesCtrl = TextEditingController(text: editando?.grades.join(', ') ?? '');
    var tipo = editando?.tipo ?? 'produto';
    String? foto = editando?.foto;

    await showPulguinhaModal(
      context: context,
      title: editando == null ? 'Novo Item' : 'Editar Item',
      child: StatefulBuilder(
        builder: (ctx, setModal) {
          final isProdutoFisico = tipo == 'produto';
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FieldLabel(label: 'Nome *', child: TextField(controller: nomeCtrl)),
                FieldLabel(label: 'Descrição', child: TextField(controller: descCtrl, maxLines: 2)),
                FieldLabel(label: 'Preço (R\$) *', child: TextField(controller: precoCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true))),
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
                if (isProdutoFisico) ...[
                  FieldLabel(
                    label: 'Foto do produto',
                    child: Column(
                      children: [
                        if (foto != null && foto!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              base64Decode(foto!.contains(',') ? foto!.split(',').last : foto!),
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Container(
                            height: 100,
                            width: double.infinity,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: AppColors.card2, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                            child: const Text('Sem foto', style: TextStyle(color: AppColors.gray)),
                          ),
                        const SizedBox(height: 8),
                        NeonButton(
                          label: '📷 Tirar foto ou escolher da galeria',
                          fullWidth: true,
                          onPressed: () async {
                            final picked = await pickPhotoBase64(ctx);
                            if (picked != null) setModal(() => foto = picked);
                          },
                        ),
                      ],
                    ),
                  ),
                  FieldLabel(
                    label: 'Grades (tamanhos)',
                    child: TextField(
                      controller: gradesCtrl,
                      decoration: const InputDecoration(hintText: 'P, M, G, GG (separados por vírgula)'),
                    ),
                  ),
                ] else
                  FieldLabel(label: 'Emoji', child: TextField(controller: emojiCtrl, decoration: const InputDecoration(hintText: '📅'))),
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
                          final grades = gradesCtrl.text
                              .split(',')
                              .map((g) => g.trim())
                              .where((g) => g.isNotEmpty)
                              .toList();
                          final dados = Produto(
                            id: editando?.id ?? 0,
                            nome: nomeCtrl.text.trim(),
                            desc: descCtrl.text.trim(),
                            preco: preco,
                            tipo: tipo,
                            emoji: emojiCtrl.text.trim().isEmpty ? '📦' : emojiCtrl.text.trim(),
                            foto: isProdutoFisico ? foto : null,
                            grades: isProdutoFisico ? grades : const [],
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
