import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pulguinha/config/mercado_pago_config.dart';
import 'package:pulguinha/config/supabase_config.dart';
import 'package:pulguinha/models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class MercadoPagoCheckoutResult {
  const MercadoPagoCheckoutResult({
    required this.checkoutUrl,
    required this.source,
    this.preferenceId,
    this.externalReference,
  });

  final String checkoutUrl;
  final String source;
  final String? preferenceId;
  final String? externalReference;
}

class MercadoPagoService {
  MercadoPagoService._();
  static final instance = MercadoPagoService._();

  Future<MercadoPagoCheckoutResult?> resolveCheckout({
    required Produto produto,
    Usuario? aluno,
  }) async {
    final staticLink = MercadoPagoConfig.paymentLinkForProduct(produto.id);
    if (staticLink.isNotEmpty) {
      return MercadoPagoCheckoutResult(
        checkoutUrl: staticLink,
        source: 'payment_link',
        externalReference: _externalReference(produto, aluno),
      );
    }

    if (MercadoPagoConfig.hasAccessToken) {
      return _createPreferenceDirect(produto: produto, aluno: aluno);
    }

    if (MercadoPagoConfig.canUseEdgeFunction) {
      return _createPreferenceViaEdgeFunction(produto: produto, aluno: aluno);
    }

    return null;
  }

  Future<bool> openCheckout(String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      debugPrint('MercadoPago: não foi possível abrir $url');
      return false;
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<MercadoPagoCheckoutResult?> _createPreferenceDirect({
    required Produto produto,
    Usuario? aluno,
  }) async {
    final token = MercadoPagoConfig.accessToken;
    if (token.isEmpty) return null;

    try {
      final externalReference = _externalReference(produto, aluno);
      final body = {
        'items': [
          {
            'title': produto.nome,
            'description': produto.desc,
            'quantity': 1,
            'unit_price': produto.preco,
            'currency_id': 'BRL',
          },
        ],
        'payer': {
          if (aluno?.email != null && aluno!.email.isNotEmpty) 'email': aluno.email,
        },
        'external_reference': externalReference,
        'back_urls': {
          'success': MercadoPagoConfig.backUrl,
          'pending': MercadoPagoConfig.backUrl,
          'failure': MercadoPagoConfig.backUrl,
        },
        'auto_return': 'approved',
      };

      final response = await http.post(
        Uri.parse('https://api.mercadopago.com/checkout/preferences'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('MercadoPago API erro ${response.statusCode}: ${response.body}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final initPoint = (data['init_point'] ?? data['sandbox_init_point']) as String?;
      if (initPoint == null || initPoint.isEmpty) return null;

      return MercadoPagoCheckoutResult(
        checkoutUrl: initPoint,
        source: 'checkout_pro_app',
        preferenceId: data['id']?.toString(),
        externalReference: externalReference,
      );
    } catch (e) {
      debugPrint('MercadoPago API direta erro: $e');
      return null;
    }
  }

  Future<MercadoPagoCheckoutResult?> _createPreferenceViaEdgeFunction({
    required Produto produto,
    Usuario? aluno,
  }) async {
    if (!SupabaseConfig.isConfigured) return null;

    try {
      final externalReference = _externalReference(produto, aluno);
      final response = await Supabase.instance.client.functions.invoke(
        MercadoPagoConfig.edgeFunctionName,
        body: {
          'title': produto.nome,
          'description': produto.desc,
          'price': produto.preco,
          'quantity': 1,
          'payer_email': aluno?.email,
          'external_reference': externalReference,
          'back_url': MercadoPagoConfig.backUrl,
          'notification_url': null,
        },
      );

      final data = Map<String, dynamic>.from(response.data as Map);
      final initPoint = (data['init_point'] ?? data['sandbox_init_point']) as String?;
      if (initPoint == null || initPoint.isEmpty) return null;

      return MercadoPagoCheckoutResult(
        checkoutUrl: initPoint,
        source: 'checkout_pro',
        preferenceId: data['id']?.toString(),
        externalReference: externalReference,
      );
    } catch (e) {
      debugPrint('MercadoPago Edge Function erro: $e');
      return null;
    }
  }

  String _externalReference(Produto produto, Usuario? aluno) {
    final alunoId = aluno?.id ?? 0;
    return 'pulguinha_${alunoId}_${produto.id}_${DateTime.now().millisecondsSinceEpoch}';
  }
}
