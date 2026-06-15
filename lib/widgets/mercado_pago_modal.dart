import 'package:flutter/material.dart';
import 'package:pulguinha/config/mercado_pago_config.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/services/mercado_pago_service.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

enum MpStep { choose, loading, waitingCheckout, success, error }

class MercadoPagoModal extends StatefulWidget {
  const MercadoPagoModal({
    super.key,
    required this.item,
    this.aluno,
    this.gradeSelecionada,
    required this.onSuccess,
  });

  final Produto item;
  final Usuario? aluno;
  final String? gradeSelecionada;
  final VoidCallback onSuccess;

  static Future<void> show(
    BuildContext context, {
    required Produto item,
    Usuario? aluno,
    String? gradeSelecionada,
    required VoidCallback onSuccess,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MercadoPagoModal(item: item, aluno: aluno, gradeSelecionada: gradeSelecionada, onSuccess: onSuccess),
    );
  }

  @override
  State<MercadoPagoModal> createState() => _MercadoPagoModalState();
}

class _MercadoPagoModalState extends State<MercadoPagoModal> {
  MpStep step = MpStep.choose;
  String? checkoutUrl;
  String? checkoutSource;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    if (!MercadoPagoConfig.isRealCheckoutAvailable) {
      step = MpStep.error;
      errorMessage = 'Mercado Pago não configurado. Configure Supabase + Edge Function ou Payment Links no painel admin.';
    }
  }

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
        errorMessage = 'Não foi possível iniciar o checkout. Verifique Supabase, Edge Function e credenciais MP.';
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

  void _confirmPayment() {
    setState(() => step = MpStep.success);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DraggableScrollableSheet(
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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  _buildProductSummary(),
                  const SizedBox(height: 16),
                  ...switch (step) {
                    MpStep.choose => _buildChoose(),
                    MpStep.loading => [_buildLoading('Preparando checkout...')],
                    MpStep.waitingCheckout => [_buildWaitingCheckout()],
                    MpStep.success => [_buildSuccess()],
                    MpStep.error => [_buildError()],
                  },
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mercado Pago', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white, decoration: TextDecoration.none)),
                Text('Checkout seguro — pagamento real', style: TextStyle(fontSize: 11, color: Colors.white70, decoration: TextDecoration.none)),
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
          const Text('Você está pagando', style: TextStyle(fontSize: 13, color: AppColors.gray, decoration: TextDecoration.none)),
          const SizedBox(height: 4),
          Text('${widget.item.emoji} ${widget.item.nome}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.neon, decoration: TextDecoration.none)),
          if (widget.gradeSelecionada != null)
            Text('Tamanho: ${widget.gradeSelecionada}', style: const TextStyle(fontSize: 12, color: AppColors.gray, decoration: TextDecoration.none)),
          Text('R\$ ${widget.item.preco.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.white, decoration: TextDecoration.none)),
          if (widget.aluno != null)
            Text('Para: ${widget.aluno!.nome}', style: const TextStyle(fontSize: 12, color: AppColors.gray, decoration: TextDecoration.none)),
        ],
      ),
    );
  }

  List<Widget> _buildChoose() {
    return [
      PulguinhaCard(
        backgroundColor: AppColors.mercadoPago.withValues(alpha: 0.08),
        borderColor: AppColors.mercadoPago.withValues(alpha: 0.25),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CHECKOUT PRO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.mercadoPago, letterSpacing: 1.2, decoration: TextDecoration.none)),
            SizedBox(height: 8),
            Text(
              'Você será redirecionado ao ambiente seguro do Mercado Pago para concluir o pagamento (PIX, cartão ou boleto).',
              style: TextStyle(fontSize: 12, color: AppColors.white, height: 1.4, decoration: TextDecoration.none),
            ),
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
    ];
  }

  Widget _buildWaitingCheckout() {
    return Column(
      children: [
        const Text('🌐', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        const Text('Checkout aberto no navegador', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.white, decoration: TextDecoration.none)),
        const SizedBox(height: 8),
        Text(
          'Conclua o pagamento no Mercado Pago${checkoutSource != null ? ' ($checkoutSource)' : ''}.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.gray, decoration: TextDecoration.none),
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
          Text(msg, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.white, decoration: TextDecoration.none)),
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
          Text(errorMessage ?? 'Erro desconhecido', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.red, decoration: TextDecoration.none)),
          if (MercadoPagoConfig.isRealCheckoutAvailable) ...[
            const SizedBox(height: 16),
            NeonButton(label: 'Tentar novamente', fullWidth: true, onPressed: () => setState(() => step = MpStep.choose)),
          ],
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
          const Text('Pagamento confirmado!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.neon, decoration: TextDecoration.none)),
          const SizedBox(height: 8),
          Text('${widget.item.nome} ativado com sucesso.', style: const TextStyle(fontSize: 13, color: AppColors.gray, decoration: TextDecoration.none)),
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
