import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/widgets/mercado_pago_modal.dart';
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
        const Text('🛒 LOJA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.neon, letterSpacing: 2)),
        const Text('PLANOS & PRODUTOS', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.white)),
        const Text('Funcional do Pulguinha', style: TextStyle(fontSize: 13, color: AppColors.gray)),
        const SizedBox(height: 20),
        _tabBar(),
        const SizedBox(height: 20),
        if (tab == 'planos') ...planos.map((p) => _planoCard(p)),
        if (tab == 'produtos') ...produtos.map((p) => _produtoCard(p)),
        const SizedBox(height: 24),
        _linkPublico(),
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
          child: Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: selected ? const Color(0xFF111111) : AppColors.gray)),
        ),
      ),
    );
  }

  Widget _planoCard(Produto p) {
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
                          Expanded(child: Text(p.nome, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.white))),
                          if (isAtual) const PulguinhaBadge(label: 'Seu plano'),
                        ],
                      ),
                      Text(p.desc, style: const TextStyle(fontSize: 12, color: AppColors.gray)),
                    ],
                  ),
                ),
                Text('R\$${p.preco.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.neon)),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PulguinhaCard(
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.neon.withValues(alpha: 0.08),
                border: Border.all(color: AppColors.neon.withValues(alpha: 0.15)),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(p.emoji, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.nome, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.white)),
                  Text(p.desc, style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                  Text('R\$ ${p.preco.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.neon)),
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

  Widget _linkPublico() {
    const link = 'https://pulguinha.mercadopago.com.br/checkout';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mercadoPago.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.mercadoPago.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🔗 LINK PÚBLICO DE PAGAMENTO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.mercadoPago, letterSpacing: 1)),
          const SizedBox(height: 6),
          const Text('Compartilhe com novos alunos sem precisar de login', style: TextStyle(fontSize: 12, color: AppColors.gray)),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.card2, borderRadius: BorderRadius.circular(8)),
            child: const Text(link, style: TextStyle(fontSize: 11, color: AppColors.neon, fontFamily: 'monospace')),
          ),
          const SizedBox(height: 10),
          GhostButton(
            label: '📋 Copiar link público',
            fullWidth: true,
            borderColor: AppColors.mercadoPago.withValues(alpha: 0.3),
            textColor: AppColors.mercadoPago,
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: link));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copiado!')));
            },
          ),
        ],
      ),
    );
  }

  void _comprar(Produto item) {
    MercadoPagoModal.show(
      context,
      item: item,
      aluno: widget.usuario.isAluno ? widget.usuario : null,
      onSuccess: () {
        if (item.tipo == 'plano' && widget.usuario.isAluno && widget.usuario.id != null) {
          context.read<AppState>().ativarPlanoAluno(widget.usuario.id!, item);
          final plano = item.nome.replaceFirst('Plano ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ Plano $plano ativado com sucesso!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ ${item.nome} — pagamento confirmado!')),
          );
        }
      },
    );
  }
}
