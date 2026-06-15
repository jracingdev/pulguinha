import 'package:flutter/material.dart';
import 'package:pulguinha/config/mercado_pago_config.dart';
import 'package:pulguinha/config/pagbank_config.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

enum CheckoutProvider { mercadoPago, pagbank }

class CheckoutPickerModal {
  static Future<CheckoutProvider?> show(BuildContext context) async {
    final mp = MercadoPagoConfig.isRealCheckoutAvailable;
    final pb = PagBankConfig.isRealCheckoutAvailable;

    if (mp && !pb) return CheckoutProvider.mercadoPago;
    if (pb && !mp) return CheckoutProvider.pagbank;
    if (!mp && !pb) return null;

    return showModalBottomSheet<CheckoutProvider>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Forma de pagamento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.white, decoration: TextDecoration.none)),
              const SizedBox(height: 6),
              const Text('Escolha como deseja pagar:', style: TextStyle(fontSize: 12, color: AppColors.gray, decoration: TextDecoration.none)),
              const SizedBox(height: 16),
              if (mp)
                NeonButton(
                  label: '💳 Mercado Pago',
                  fullWidth: true,
                  backgroundColor: AppColors.mercadoPago,
                  textColor: Colors.white,
                  onPressed: () => Navigator.pop(ctx, CheckoutProvider.mercadoPago),
                ),
              if (mp && pb) const SizedBox(height: 10),
              if (pb)
                NeonButton(
                  label: '🏦 PagBank / PagSeguro',
                  fullWidth: true,
                  backgroundColor: AppColors.pagBank,
                  textColor: Colors.white,
                  onPressed: () => Navigator.pop(ctx, CheckoutProvider.pagbank),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
