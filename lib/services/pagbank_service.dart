import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pulguinha/config/pagbank_config.dart';
import 'package:pulguinha/models/models.dart';
import 'package:url_launcher/url_launcher.dart';

class PagBankCheckoutResult {
  const PagBankCheckoutResult({
    required this.checkoutUrl,
    this.checkoutId,
    this.referenceId,
  });

  final String checkoutUrl;
  final String? checkoutId;
  final String? referenceId;
}

class PagBankService {
  PagBankService._();
  static final instance = PagBankService._();

  Future<PagBankCheckoutResult?> resolveCheckout({
    required Produto produto,
    Usuario? aluno,
    String? gradeSelecionada,
  }) async {
    if (!PagBankConfig.isRealCheckoutAvailable) return null;
    return _createCheckout(produto: produto, aluno: aluno, gradeSelecionada: gradeSelecionada);
  }

  Future<bool> openCheckout(String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      debugPrint('PagBank: não foi possível abrir $url');
      return false;
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<PagBankCheckoutResult?> _createCheckout({
    required Produto produto,
    Usuario? aluno,
    String? gradeSelecionada,
  }) async {
    final token = PagBankConfig.token;
    if (token.isEmpty) return null;

    try {
      final referenceId = _referenceId(produto, aluno);
      final itemName = gradeSelecionada != null ? '${produto.nome} ($gradeSelecionada)' : produto.nome;
      final body = <String, dynamic>{
        'reference_id': referenceId,
        'customer_modifiable': true,
        'items': [
          {
            'reference_id': 'prod_${produto.id}',
            'name': itemName.length > 100 ? itemName.substring(0, 100) : itemName,
            'description': produto.desc.length > 255 ? produto.desc.substring(0, 255) : produto.desc,
            'quantity': 1,
            'unit_amount': (produto.preco * 100).round(),
          },
        ],
        'redirect_url': PagBankConfig.redirectUrl,
      };

      if (aluno != null && aluno.email.isNotEmpty && aluno.nome.isNotEmpty) {
        body['customer'] = {
          'name': aluno.nome,
          'email': aluno.email,
        };
        body['customer_modifiable'] = false;
      }

      final response = await http.post(
        Uri.parse('${PagBankConfig.apiBaseUrl}/checkouts'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('PagBank API erro ${response.statusCode}: ${response.body}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final payUrl = _extractPayUrl(data);
      if (payUrl == null || payUrl.isEmpty) return null;

      return PagBankCheckoutResult(
        checkoutUrl: payUrl,
        checkoutId: data['id']?.toString(),
        referenceId: referenceId,
      );
    } catch (e) {
      debugPrint('PagBank API erro: $e');
      return null;
    }
  }

  String? _extractPayUrl(Map<String, dynamic> data) {
    final links = data['links'];
    if (links is List) {
      for (final item in links) {
        if (item is Map && item['rel'] == 'PAY') {
          final href = item['href'];
          if (href is String && href.isNotEmpty) return href;
        }
      }
    }
    final direct = data['pay_url'] ?? data['url'];
    if (direct is String && direct.isNotEmpty) return direct;
    return null;
  }

  String _referenceId(Produto produto, Usuario? aluno) {
    final alunoId = aluno?.id ?? 0;
    return 'pulguinha_pb_${alunoId}_${produto.id}_${DateTime.now().millisecondsSinceEpoch}';
  }
}
