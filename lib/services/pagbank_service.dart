import 'package:flutter/foundation.dart';
import 'package:pulguinha/config/pagbank_config.dart';
import 'package:pulguinha/models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    // O token do PagBank fica só nos secrets do Supabase; o servidor confere o
    // preço pelo product_id e cria o checkout.
    try {
      final referenceId = _referenceId(produto, aluno);
      final response = await Supabase.instance.client.functions.invoke(
        PagBankConfig.edgeFunctionName,
        body: {
          'product_id': produto.id,
          'grade': gradeSelecionada,
          'reference_id': referenceId,
          'redirect_url': PagBankConfig.redirectUrl,
          if (aluno != null && aluno.email.isNotEmpty && aluno.nome.isNotEmpty) ...{
            'customer_name': aluno.nome,
            'customer_email': aluno.email,
          },
        },
      );

      final data = Map<String, dynamic>.from(response.data as Map);
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
