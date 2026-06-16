import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/config/mercado_pago_config.dart';
import 'package:pulguinha/config/pagbank_config.dart';
import 'package:pulguinha/models/billing_rules.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/widgets/checkout_picker_modal.dart';
import 'package:pulguinha/widgets/mercado_pago_modal.dart';
import 'package:pulguinha/widgets/pagbank_modal.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

class LojaScreen extends StatefulWidget {
  const LojaScreen({super.key, required this.usuario});

  final Usuario usuario;

  @override
  State<LojaScreen> createState() => _LojaScreenState();
}

class _LojaScreenState extends State<LojaScreen> {
  String tab = 'planos';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final planos = state.produtos.where((p) => p.tipo == 'plano').toList();
    final produtos = state.produtos.where((p) => p.tipo != 'plano').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🛒 LOJA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.neon, letterSpacing: 2, decoration: TextDecoration.none)),
        const Text('PLANOS & PRODUTOS', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.white, decoration: TextDecoration.none)),
        const Text('Funcional do Pulguinha', style: TextStyle(fontSize: 13, color: AppColors.gray, decoration: TextDecoration.none)),
        const SizedBox(height: 20),
        _tabBar(),
        const SizedBox(height: 20),
        if (tab == 'planos') ...planos.map((p) => _planoCard(p, state)),
        if (tab == 'produtos') ...produtos.map((p) => _produtoCard(p)),
      ],
    );
  }

  PrecoComRegras _detalharPreco(Produto p, AppState state) {
    if (!widget.usuario.isAluno || widget.usuario.id == null) {
      return PrecoComRegras(precoOriginal: p.preco, precoFinal: p.preco);
    }
    return state.detalharPrecoComRegras(p, aluno: state.alunoPorId(widget.usuario.id));
  }

  Widget _precoWidget(Produto p, AppState state) {
    final detalhe = _detalharPreco(p, state);
    final temDesconto = detalhe.descontoTotal > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (temDesconto)
          Text(
            'R\$${detalhe.precoOriginal.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 12, color: AppColors.gray, decoration: TextDecoration.lineThrough, decorationColor: AppColors.gray),
          ),
        Text('R\$${detalhe.precoFinal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.neon, decoration: TextDecoration.none)),
        if (detalhe.descontoIndicado > 0)
          Text('-${(detalhe.descontoIndicado / detalhe.precoOriginal * 100).toStringAsFixed(0)}% indicação', style: const TextStyle(fontSize: 10, color: AppColors.yellow)),
        if (detalhe.creditoIndicador > 0)
          Text('-R\$${detalhe.creditoIndicador.toStringAsFixed(0)} crédito', style: const TextStyle(fontSize: 10, color: AppColors.neon)),
      ],
    );
  }

  Widget _tabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          _tabBtn('planos', '📅 Planos'),
          _tabBtn('produtos', '👕 Produtos'),
        ],
      ),
    );
  }

  Widget _tabBtn(String id, String label) {
    final selected = tab == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => tab = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(color: selected ? AppColors.neon : Colors.transparent, borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: selected ? const Color(0xFF111111) : AppColors.gray, decoration: TextDecoration.none)),
        ),
      ),
    );
  }

  Widget _planoCard(Produto p, AppState state) {
    final isAtual = widget.usuario.isAluno && widget.usuario.plano == p.nome.replaceFirst('Plano ', '');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PulguinhaCard(
        borderColor: isAtual ? AppColors.neon.withValues(alpha: 0.4) : AppColors.border,
        backgroundColor: isAtual ? AppColors.neon.withValues(alpha: 0.05) : AppColors.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(p.emoji, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(p.nome, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.white, decoration: TextDecoration.none))),
                          if (isAtual) const PulguinhaBadge(label: 'Seu plano'),
                        ],
                      ),
                      Text(p.desc, style: const TextStyle(fontSize: 12, color: AppColors.gray, decoration: TextDecoration.none)),
                    ],
                  ),
                ),
                _precoWidget(p, state),
              ],
            ),
            const SizedBox(height: 10),
            NeonButton(
              label: isAtual ? '✓ Plano atual — Renovar' : '💳 Assinar agora',
              fullWidth: true,
              backgroundColor: isAtual ? AppColors.card2 : AppColors.neon,
              textColor: isAtual ? AppColors.gray : const Color(0xFF111111),
              onPressed: () => _comprar(p),
            ),
          ],
        ),
      ),
    );
  }

  Widget _produtoCard(Produto p) {
    final state = context.watch<AppState>();
    final detalhe = _detalharPreco(p, state);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PulguinhaCard(
        child: Row(
          children: [
            _produtoThumb(p),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.nome, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.white, decoration: TextDecoration.none)),
                  Text(p.desc, style: const TextStyle(fontSize: 11, color: AppColors.gray, decoration: TextDecoration.none)),
                  if (p.grades.isNotEmpty)
                    Text('Tamanhos: ${p.grades.join(' · ')}', style: const TextStyle(fontSize: 10, color: AppColors.neon, decoration: TextDecoration.none)),
                  if (detalhe.descontoTotal > 0)
                    Text('R\$ ${detalhe.precoOriginal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppColors.gray, decoration: TextDecoration.lineThrough)),
                  Text('R\$ ${detalhe.precoFinal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.neon, decoration: TextDecoration.none)),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () => _comprar(p),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.neon,
                backgroundColor: AppColors.neon.withValues(alpha: 0.1),
                side: BorderSide(color: AppColors.neon.withValues(alpha: 0.25)),
              ),
              child: const Text('Comprar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
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
          borderRadius: BorderRadius.circular(14),
          child: Image.memory(bytes, width: 56, height: 56, fit: BoxFit.cover),
        );
      } catch (_) {}
    }
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.neon.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.neon.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(p.emoji, style: const TextStyle(fontSize: 26)),
    );
  }

  Future<void> _comprar(Produto item) async {
    String? grade;
    if (item.grades.isNotEmpty) {
      grade = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Escolha o tamanho', style: TextStyle(color: AppColors.white)),
          content: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: item.grades.map((g) {
              return ChoiceChip(
                label: Text(g),
                selected: false,
                onSelected: (_) => Navigator.pop(ctx, g),
              );
            }).toList(),
          ),
        ),
      );
      if (grade == null) return;
    }

    if (!mounted) return;

    final state = context.read<AppState>();
    final detalhe = _detalharPreco(item, state);
    final itemComPreco = item.copyWith(preco: detalhe.precoFinal);

    final provider = await CheckoutPickerModal.show(context);
    if (!mounted) return;
    if (provider == null) {
      final semPagamento = !MercadoPagoConfig.isRealCheckoutAvailable && !PagBankConfig.isRealCheckoutAvailable;
      if (semPagamento) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum meio de pagamento configurado. Peça ao admin.')),
        );
      }
      return;
    }

    if (provider == CheckoutProvider.pagbank) {
      PagBankModal.show(
        context,
        item: itemComPreco,
        aluno: widget.usuario.isAluno ? widget.usuario : null,
        gradeSelecionada: grade,
        onSuccess: () => _onCheckoutSuccess(itemComPreco),
      );
      return;
    }

    MercadoPagoModal.show(
      context,
      item: itemComPreco,
      aluno: widget.usuario.isAluno ? widget.usuario : null,
      gradeSelecionada: grade,
      onSuccess: () => _onCheckoutSuccess(itemComPreco),
    );
  }

  void _onCheckoutSuccess(Produto item) {
    if (widget.usuario.isAluno && widget.usuario.id != null) {
      final state = context.read<AppState>();
      if (item.tipo == 'plano') {
        state.ativarPlanoAluno(widget.usuario.id!, item);
        final plano = item.nome.replaceFirst('Plano ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Plano $plano ativado com sucesso!')),
        );
        return;
      }
      state.registrarCompraProduto(widget.usuario.id!, item);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ ${item.nome} — pagamento confirmado!')),
    );
  }
}
