import 'package:flutter/foundation.dart';
import 'package:pulguinha/config/partner_config.dart';
import 'package:pulguinha/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Publica a grade na Booking API da TotalPass.
class TotalpassSyncService {
  TotalpassSyncService._();
  static final instance = TotalpassSyncService._();

  Future<Map<String, dynamic>> syncSchedule() async {
    if (!SupabaseConfig.isConfigured) {
      return {'ok': false, 'message': 'Supabase não configurado'};
    }
    try {
      final response = await Supabase.instance.client.functions.invoke(
        PartnerConfig.totalpassSyncFunctionName,
        body: {
          'action': 'sync_schedule',
          ...PartnerConfig.publicPayload(),
        },
      );
      final data = response.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return {'ok': true, 'data': data};
    } catch (e) {
      debugPrint('TotalPass schedule sync: $e');
      return {'ok': false, 'message': e.toString()};
    }
  }
}
