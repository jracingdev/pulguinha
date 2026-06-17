import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pulguinha/config/partner_config.dart';
import 'package:pulguinha/config/supabase_config.dart';
import 'package:pulguinha/models/partner_access.dart';
import 'package:pulguinha/services/partner_config_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PartnerAccessService {
  PartnerAccessService._();
  static final instance = PartnerAccessService._();

  Future<PartnerAccessResult> validate({
    required PartnerProvider provider,
    required String identifier,
    TotalpassIdentifierType identifierType = TotalpassIdentifierType.token,
    PartnerAccessMode mode = PartnerAccessMode.validate,
  }) async {
    final trimmed = identifier.trim();
    if (trimmed.isEmpty) {
      return PartnerAccessResult.failure('Informe o código ou documento.');
    }

    if (SupabaseConfig.isConfigured) {
      final viaEdge = await _validateViaEdgeFunction(
        provider: provider,
        identifier: trimmed,
        identifierType: identifierType,
        mode: mode,
      );
      if (viaEdge != null) return viaEdge;
    }

    return _validateDirect(
      provider: provider,
      identifier: trimmed,
      identifierType: identifierType,
      mode: mode,
    );
  }

  Future<PartnerAccessResult?> _validateViaEdgeFunction({
    required PartnerProvider provider,
    required String identifier,
    required TotalpassIdentifierType identifierType,
    required PartnerAccessMode mode,
  }) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        PartnerConfig.edgeFunctionName,
        body: {
          'provider': provider.name,
          'identifier': identifier,
          if (provider == PartnerProvider.totalpass) 'identifier_type': identifierType.apiValue,
          'mode': mode == PartnerAccessMode.use ? 'use' : 'validate',
          ...PartnerConfig.publicPayload(),
        },
      );

      final data = Map<String, dynamic>.from(response.data as Map);
      if (data['ok'] == true) {
        return PartnerAccessResult.success(
          provider: provider,
          identifier: data['identifier'] as String? ?? identifier,
          identifierType: provider == PartnerProvider.totalpass ? identifierType : null,
          mode: mode,
        );
      }
      return PartnerAccessResult.failure(
        data['message'] as String? ?? 'Não foi possível validar o benefício.',
      );
    } catch (e) {
      debugPrint('Edge Function ${PartnerConfig.edgeFunctionName}: $e');
      return null;
    }
  }

  Future<PartnerAccessResult> _validateDirect({
    required PartnerProvider provider,
    required String identifier,
    required TotalpassIdentifierType identifierType,
    required PartnerAccessMode mode,
  }) async {
    final cfg = PartnerConfig.stored;
    if (provider == PartnerProvider.wellhub) {
      if (!PartnerConfig.wellhubConfigured) {
        return PartnerAccessResult.failure(
          'GymPass não configurado. Peça ao professor para configurar no painel admin.',
        );
      }
      return _validateWellhubDirect(identifier, cfg);
    }

    if (!PartnerConfig.totalpassConfigured) {
      return PartnerAccessResult.failure(
        'TotalPass não configurado. Peça ao professor para configurar no painel admin.',
      );
    }
    return _validateTotalpassDirect(identifier, identifierType, mode, cfg);
  }

  Future<PartnerAccessResult> _validateWellhubDirect(String identifier, PartnerStoredConfig cfg) async {
    final gympassId = _onlyDigits(identifier).padLeft(13, '0');
    final id = gympassId.length > 13 ? gympassId.substring(gympassId.length - 13) : gympassId;
    if (id.length != 13) {
      return PartnerAccessResult.failure('ID GymPass deve ter 13 dígitos.');
    }

    final base = cfg.wellhubUseSandbox
        ? 'https://apitesting.partners.gympass.com'
        : 'https://api.partners.gympass.com';
    try {
      final res = await http.post(
        Uri.parse('$base/access/v1/validate'),
        headers: {
          'Authorization': 'Bearer ${cfg.wellhubBearerToken.trim()}',
          'X-Gym-Id': cfg.wellhubGymId.trim(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'gympass_id': id}),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return PartnerAccessResult.success(provider: PartnerProvider.wellhub, identifier: id);
      }
      return PartnerAccessResult.failure(_parseApiError(res.body, 'Check-in GymPass inválido ou expirado.'));
    } catch (e) {
      return PartnerAccessResult.failure('Erro ao conectar com GymPass: $e');
    }
  }

  Future<PartnerAccessResult> _validateTotalpassDirect(
    String identifier,
    TotalpassIdentifierType identifierType,
    PartnerAccessMode mode,
    PartnerStoredConfig cfg,
  ) async {
    var normalized = identifier.trim();
    if (identifierType == TotalpassIdentifierType.cpf) {
      normalized = _onlyDigits(identifier);
      if (normalized.length != 11) {
        return PartnerAccessResult.failure('CPF inválido.');
      }
    }

    final base = cfg.totalpassUseSandbox
        ? 'https://staging.totalpass.com/api'
        : 'https://api.totalpass.com/service';
    final path = mode == PartnerAccessMode.use ? '/v1/track_usages' : '/v1/track_usages/validate';
    final attributes = <String, String>{
      'type': identifierType.apiValue,
      'identifier': normalized,
      'service_provider_code': cfg.totalpassServiceProviderCode.trim(),
    };
    final plan = cfg.totalpassPlanCode.trim();
    if (plan.isNotEmpty) {
      attributes['service_provider_plan_code'] = plan;
    }

    try {
      final res = await http.post(
        Uri.parse('$base$path'),
        headers: {
          'x-api-key': cfg.totalpassApiKey.trim(),
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'data': {
            'type': 'track_usage',
            'attributes': attributes,
          },
        }),
      );
      if (res.statusCode == 204 || (res.statusCode >= 200 && res.statusCode < 300)) {
        return PartnerAccessResult.success(
          provider: PartnerProvider.totalpass,
          identifier: normalized,
          identifierType: identifierType,
          mode: mode,
        );
      }
      return PartnerAccessResult.failure(
        _parseApiError(
          res.body,
          mode == PartnerAccessMode.use
              ? 'Token TotalPass inválido. Faça check-in no app TotalPass.'
              : 'Assinatura TotalPass inválida para esta academia.',
        ),
      );
    } catch (e) {
      return PartnerAccessResult.failure('Erro ao conectar com TotalPass: $e');
    }
  }

  String _onlyDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  String _parseApiError(String body, String fallback) {
    try {
      final data = jsonDecode(body);
      if (data is Map) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) return message;
        final detail = data['detail'];
        if (detail is String && detail.isNotEmpty) return detail;
        final errors = data['errors'];
        if (errors is List && errors.isNotEmpty) {
          final first = errors.first;
          if (first is Map) {
            final d = first['detail'];
            if (d is String && d.isNotEmpty) return d;
            final source = first['source'];
            if (source is List && source.isNotEmpty) {
              final src = source.first;
              if (src is Map) {
                final m = src['message'];
                if (m is String && m.isNotEmpty) return m;
              }
            }
            if (source is String && source.isNotEmpty) return source;
          }
        }
      }
    } catch (_) {}
    return fallback;
  }
}
