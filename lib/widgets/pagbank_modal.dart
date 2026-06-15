import 'package:flutter/material.dart';
import 'package:pulguinha/config/pagbank_config.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/services/pagbank_service.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

enum PagBankStep { choose, loading, waitingCheckout, success, error }

class PagBankModal extends StatefulWidget {
  const PagBankModal({
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
      builder: (_) => PagBankModal(
        item: item,
        aluno: aluno,
        gradeSelecionada: gradeSelecionada,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<PagBankModal> createState() => _PagBankModalState();
}

class _PagBankModalState extends State<PagBankModal> {
  PagBankStep step = PagBankStep.choose;
  String? checkoutUrl;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    if (!PagBankConfig.isRealCheckoutAvailable) {
      step = PagBankStep.error;
      errorMessage = 'PagBank não configurado. O admin deve cadastrar o token em Configurações → PagBank.';
    }
  }

  Future<void> _startCheckout() async {
    setState(() {
      step = PagBankStep.loading;
      errorMessage = null;
    });

    final result = await PagBankService.instance.resolveCheckout(
      produto: widget.item,
      aluno: widget.aluno,
      gradeSelecionada: widget.gradeSelecionada,
    );

    if (!mounted) return;

    if (result == null) {
      setState(() {
        step = PagBankStep.error;
        errorMessage = 'Não foi possível criar o checkout PagBank. Verifique o token e o ambiente (sandbox/produção).';
      });
      return;
    }

    checkoutUrl = result.checkoutUrl;
    final opened = await PagBankService.instance.openCheckout(result.checkoutUrl);
    if (!mounted) return;

    if (!opened) {
      setState(() {
        step = PagBankStep.error;
        errorMessage = 'Não foi possível abrir o checkout do PagBank.';
      });
      return;
    }

    setState(() => step = PagBankStep.waitingCheckout);
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.pagBank,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Text('🏦', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PagBank / PagSeguro', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white, decoration: TextDecoration.none)),
                        Text('Checkout seguro — pagamento real', style: TextStyle(fontSize: 11, color: Colors.white70, decoration: TextDecoration.none)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  PulguinhaCard(
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...switch (step) {
                    PagBankStep.choose => [
                      PulguinhaCard(
                        backgroundColor: AppColors.pagBank.withValues(alpha: 0.08),
                        borderColor: AppColors.pagBank.withValues(alpha: 0.25),
                        child: Text(
                          PagBankConfig.useSandbox
                              ? 'Ambiente de testes (Sandbox). Use cartões de teste do PagBank.'
                              : 'Você será redirecionado ao ambiente seguro do PagBank (PIX, cartão ou boleto).',
                          style: const TextStyle(fontSize: 12, color: AppColors.white, height: 1.4, decoration: TextDecoration.none),
                        ),
                      ),
                      const SizedBox(height: 16),
                      NeonButton(
                        label: '🚀 Ir para pagamento no PagBank',
                        fullWidth: true,
                        backgroundColor: AppColors.pagBank,
                        textColor: Colors.white,
                        onPressed: _startCheckout,
                      ),
                    ],
                    PagBankStep.loading => [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator(color: AppColors.pagBank)),
                      ),
                    ],
                    PagBankStep.waitingCheckout => [
                      const Text('🌐', style: TextStyle(fontSize: 48), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      const Text('Checkout aberto no navegador', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.white, decoration: TextDecoration.none)),
                      if (checkoutUrl != null) ...[
                        const SizedBox(height: 12),
                        GhostButton(
                          label: 'Abrir checkout novamente',
                          fullWidth: true,
                          onPressed: () {
                            if (checkoutUrl != null) PagBankService.instance.openCheckout(checkoutUrl!);
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      NeonButton(label: '✅ Já concluí o pagamento', fullWidth: true, onPressed: () => setState(() => step = PagBankStep.success)),
                    ],
                    PagBankStep.success => [
                      const SizedBox(height: 24),
                      const Text('✅ Pagamento confirmado!', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.neon, decoration: TextDecoration.none)),
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
                    PagBankStep.error => [
                      Text(errorMessage ?? 'Erro', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.red, decoration: TextDecoration.none)),
                      if (PagBankConfig.isRealCheckoutAvailable) ...[
                        const SizedBox(height: 16),
                        NeonButton(label: 'Tentar novamente', fullWidth: true, onPressed: () => setState(() => step = PagBankStep.choose)),
                      ],
                    ],
                  },
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
