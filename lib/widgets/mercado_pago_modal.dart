import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

enum MpStep { choose, processing, success }

class MercadoPagoModal extends StatefulWidget {
  const MercadoPagoModal({
    super.key,
    required this.item,
    this.aluno,
    required this.onSuccess,
  });

  final Produto item;
  final Usuario? aluno;
  final VoidCallback onSuccess;

  static Future<void> show(
    BuildContext context, {
    required Produto item,
    Usuario? aluno,
    required VoidCallback onSuccess,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MercadoPagoModal(item: item, aluno: aluno, onSuccess: onSuccess),
    );
  }

  @override
  State<MercadoPagoModal> createState() => _MercadoPagoModalState();
}

class _MercadoPagoModalState extends State<MercadoPagoModal> {
  String method = 'pix';
  MpStep step = MpStep.choose;

  Future<void> _pay() async {
    setState(() => step = MpStep.processing);
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    setState(() => step = MpStep.success);
  }

  @override
  Widget build(BuildContext context) {
    final pixCode =
        '00020126580014BR.GOV.BCB.PIX0136pulguinha@gmail.com5204000053039865406${widget.item.preco.toStringAsFixed(2)}5802BR5924Funcional do Pulguinha6009SAO PAULO62070503***6304ABCD';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.mercadoPago,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Text('💳', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Mercado Pago', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Pagamento simulado', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ],
                      ),
                      const Text('Demonstração — sem cobrança real', style: TextStyle(fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.all(20),
              children: [
                if (step == MpStep.choose) ..._buildChoose(pixCode),
                if (step == MpStep.processing) _buildProcessing(),
                if (step == MpStep.success) _buildSuccess(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildChoose(String pixCode) {
    return [
      PulguinhaCard(
        backgroundColor: AppColors.card2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Você está pagando', style: TextStyle(fontSize: 13, color: AppColors.gray)),
            const SizedBox(height: 4),
            Text('${widget.item.emoji} ${widget.item.nome}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.neon)),
            Text('R\$ ${widget.item.preco.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.white)),
            if (widget.aluno != null)
              Text('Para: ${widget.aluno!.nome}', style: const TextStyle(fontSize: 12, color: AppColors.gray)),
          ],
        ),
      ),
      const SizedBox(height: 20),
      const Text('FORMA DE PAGAMENTO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.gray, letterSpacing: 1.5)),
      const SizedBox(height: 10),
      Row(
        children: [
          _methodCard('pix', 'PIX', '⚡', 'Instantâneo'),
          const SizedBox(width: 8),
          _methodCard('card', 'Cartão', '💳', 'Crédito/Débito'),
          const SizedBox(width: 8),
          _methodCard('boleto', 'Boleto', '🧾', '1-3 dias úteis'),
        ],
      ),
      const SizedBox(height: 16),
      if (method == 'pix') _buildPix(pixCode),
      if (method == 'card') _buildCard(),
      if (method == 'boleto') _buildBoleto(),
      const SizedBox(height: 16),
      NeonButton(
        label: method == 'pix' ? '✅ Confirmar PIX' : method == 'boleto' ? '🧾 Gerar Boleto' : '💳 Pagar agora',
        fullWidth: true,
        backgroundColor: AppColors.mercadoPago,
        textColor: Colors.white,
        onPressed: _pay,
      ),
      const SizedBox(height: 12),
      const Center(child: Text('🔒 Demonstração — integração real requer backend + credenciais MP', style: TextStyle(fontSize: 10, color: AppColors.grayDim))),
    ];
  }

  Widget _methodCard(String id, String label, String icon, String sub) {
    final selected = method == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => method = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.mercadoPago.withValues(alpha: 0.15) : AppColors.card2,
            border: Border.all(color: selected ? AppColors.mercadoPago : AppColors.border, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: selected ? AppColors.mercadoPago : AppColors.white)),
              Text(sub, style: const TextStyle(fontSize: 10, color: AppColors.gray)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPix(String pixCode) {
    return PulguinhaCard(
      backgroundColor: AppColors.card2,
      child: Column(
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: const Text('QR', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black)),
          ),
          const SizedBox(height: 12),
          const Text('Escaneie o QR Code ou copie o código', style: TextStyle(fontSize: 11, color: AppColors.gray)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.card3, borderRadius: BorderRadius.circular(8)),
            child: Text('${pixCode.substring(0, 60)}...', style: const TextStyle(fontSize: 10, color: AppColors.neon, fontFamily: 'monospace')),
          ),
          const SizedBox(height: 10),
          GhostButton(
            label: '📋 Copiar código PIX',
            fullWidth: true,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: pixCode));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código PIX copiado!')));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return const Column(
      children: [
        FieldLabel(label: 'Número do cartão', child: TextField(decoration: InputDecoration(hintText: '0000 0000 0000 0000'))),
        FieldLabel(label: 'Nome no cartão', child: TextField(decoration: InputDecoration(hintText: 'NOME SOBRENOME'))),
        Row(
          children: [
            Expanded(child: FieldLabel(label: 'Validade', child: TextField(decoration: InputDecoration(hintText: 'MM/AA')))),
            SizedBox(width: 10),
            Expanded(child: FieldLabel(label: 'CVV', child: TextField(decoration: InputDecoration(hintText: '123')))),
          ],
        ),
      ],
    );
  }

  Widget _buildBoleto() {
    return const PulguinhaCard(
      backgroundColor: AppColors.card2,
      child: Column(
        children: [
          Text('🧾', style: TextStyle(fontSize: 36)),
          SizedBox(height: 8),
          Text('Boleto bancário', style: TextStyle(fontSize: 13, color: AppColors.white, fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text('Vencimento em 3 dias úteis.\nApós pagamento, confirmação em até 3 dias.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.gray)),
        ],
      ),
    );
  }

  Widget _buildProcessing() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Text('⏳', style: TextStyle(fontSize: 48)),
          SizedBox(height: 16),
          Text('Processando pagamento...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.white)),
          SizedBox(height: 8),
          Text('Aguarde, não feche esta tela', style: TextStyle(fontSize: 12, color: AppColors.gray)),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.neon.withValues(alpha: 0.15),
              border: Border.all(color: AppColors.neon, width: 2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text('✅', style: TextStyle(fontSize: 36)),
          ),
          const SizedBox(height: 16),
          const Text('Pagamento confirmado!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.neon)),
          const SizedBox(height: 8),
          Text('${widget.item.nome} ativado com sucesso.', style: const TextStyle(fontSize: 13, color: AppColors.gray)),
          const SizedBox(height: 24),
          NeonButton(
            label: 'Continuar',
            fullWidth: true,
            onPressed: () {
              widget.onSuccess();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
