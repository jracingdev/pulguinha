import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pulguinha/config/mercado_pago_config.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/services/mercado_pago_service.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

enum MpStep { choose, loading, waitingCheckout, processing, success, error }

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
  String? checkoutUrl;
  String? checkoutSource;
  String? errorMessage;
  bool _forceSimulation = false;

  bool get _useRealCheckout => MercadoPagoConfig.isRealCheckoutAvailable && !_forceSimulation;

  Future<void> _startRealCheckout() async {
    setState(() {
      step = MpStep.loading;
      errorMessage = null;
    });

    final result = await MercadoPagoService.instance.resolveCheckout(
      produto: widget.item,
      aluno: widget.aluno,
    );

    if (!mounted) return;

    if (result == null) {
      setState(() {
        step = MpStep.error;
        errorMessage = 'Não foi possível iniciar o checkout. Verifique Supabase/MP ou use modo demo.';
      });
      return;
    }

    checkoutUrl = result.checkoutUrl;
    checkoutSource = result.source;

    final opened = await MercadoPagoService.instance.openCheckout(result.checkoutUrl);
    if (!mounted) return;

    if (!opened) {
      setState(() {
        step = MpStep.error;
        errorMessage = 'Não foi possível abrir o checkout do Mercado Pago.';
      });
      return;
    }

    setState(() => step = MpStep.waitingCheckout);
  }

  Future<void> _paySimulated() async {
    setState(() => step = MpStep.processing);
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    setState(() => step = MpStep.success);
  }

  void _confirmPayment() {
    setState(() => step = MpStep.success);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.all(20),
              children: [
                _buildProductSummary(),
                const SizedBox(height: 16),
                ...switch (step) {
                  MpStep.choose => _buildChoose(),
                  MpStep.loading => [_buildLoading('Preparando checkout...')],
                  MpStep.waitingCheckout => [_buildWaitingCheckout()],
                  MpStep.processing => [_buildProcessing()],
                  MpStep.success => [_buildSuccess()],
                  MpStep.error => [_buildError()],
                },
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final badge = _useRealCheckout ? MercadoPagoConfig.integrationLabel() : 'Modo demonstração';
    final subtitle = _useRealCheckout
        ? 'Checkout hospedado Mercado Pago'
        : 'Configure MP_LINK_* ou Supabase + Edge Function';

    return Container(
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
                      child: Text(badge, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ],
                ),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSummary() {
    return PulguinhaCard(
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
    );
  }

  List<Widget> _buildChoose() {
    if (_useRealCheckout) {
      return [
        PulguinhaCard(
          backgroundColor: AppColors.mercadoPago.withValues(alpha: 0.08),
          borderColor: AppColors.mercadoPago.withValues(alpha: 0.25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('CHECKOUT PRO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.mercadoPago, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              const Text(
                'Você será redirecionado ao ambiente seguro do Mercado Pago para concluir o pagamento (PIX, cartão ou boleto).',
                style: TextStyle(fontSize: 12, color: AppColors.white, height: 1.4),
              ),
              if (MercadoPagoConfig.hasPublicKey) ...[
                const SizedBox(height: 8),
                Text('Public Key: ${MercadoPagoConfig.publicKey.substring(0, MercadoPagoConfig.publicKey.length.clamp(0, 12))}...', style: const TextStyle(fontSize: 10, color: AppColors.gray)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        NeonButton(
          label: '🚀 Ir para pagamento no Mercado Pago',
          fullWidth: true,
          backgroundColor: AppColors.mercadoPago,
          textColor: Colors.white,
          onPressed: _startRealCheckout,
        ),
        const SizedBox(height: 12),
        GhostButton(
          label: 'Usar simulação local',
          fullWidth: true,
          onPressed: () => setState(() => _forceSimulation = true),
        ),
      ];
    }

    final pixCode =
        '00020126580014BR.GOV.BCB.PIX0136pulguinha@gmail.com5204000053039865406${widget.item.preco.toStringAsFixed(2)}5802BR5924Funcional do Pulguinha6009SAO PAULO62070503***6304ABCD';

    return [
      const Text('FORMA DE PAGAMENTO (SIMULADO)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.gray, letterSpacing: 1.5)),
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
        label: method == 'pix' ? '✅ Confirmar PIX (demo)' : method == 'boleto' ? '🧾 Gerar Boleto (demo)' : '💳 Pagar agora (demo)',
        fullWidth: true,
        backgroundColor: AppColors.mercadoPago,
        textColor: Colors.white,
        onPressed: _paySimulated,
      ),
      const SizedBox(height: 12),
      const Center(
        child: Text(
          '⚠️ Credenciais MP não configuradas — fluxo simulado.\nAdicione MP_LINK_* ou Supabase + Edge Function.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: AppColors.grayDim),
        ),
      ),
    ];
  }

  Widget _buildWaitingCheckout() {
    return Column(
      children: [
        const Text('🌐', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        const Text('Checkout aberto no navegador', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.white)),
        const SizedBox(height: 8),
        Text(
          'Conclua o pagamento no Mercado Pago${checkoutSource != null ? ' ($checkoutSource)' : ''}.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.gray),
        ),
        if (checkoutUrl != null) ...[
          const SizedBox(height: 12),
          GhostButton(
            label: 'Abrir checkout novamente',
            fullWidth: true,
            onPressed: () {
              if (checkoutUrl != null) {
                MercadoPagoService.instance.openCheckout(checkoutUrl!);
              }
            },
          ),
        ],
        const SizedBox(height: 16),
        NeonButton(
          label: '✅ Já concluí o pagamento',
          fullWidth: true,
          onPressed: _confirmPayment,
        ),
        const SizedBox(height: 10),
        const Text(
          'Em produção, confirmação automática via webhook MP + deep link.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: AppColors.grayDim),
        ),
      ],
    );
  }

  Widget _buildLoading(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const CircularProgressIndicator(color: AppColors.mercadoPago),
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.white)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const Text('❌', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(errorMessage ?? 'Erro desconhecido', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.red)),
          const SizedBox(height: 16),
          NeonButton(label: 'Tentar novamente', fullWidth: true, onPressed: () => setState(() => step = MpStep.choose)),
        ],
      ),
    );
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
          const Text('Escaneie o QR Code ou copie o código (demo)', style: TextStyle(fontSize: 11, color: AppColors.gray)),
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
          Text('Boleto bancário (demo)', style: TextStyle(fontSize: 13, color: AppColors.white, fontWeight: FontWeight.w700)),
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
