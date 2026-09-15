import 'package:flutter/foundation.dart';
import 'package:pulguinha/config/partner_config.dart';
import 'package:pulguinha/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Dispara sync de vagas Wellhub sem bloquear a UX.
class WellhubSyncService {
  WellhubSyncService._();
  static final instance = WellhubSyncService._();

  void syncOccupancy({required int horarioId, required String data}) {
    if (!SupabaseConfig.isConfigured) return;
    Future(() async {
      try {
        await Supabase.instance.client.functions.invoke(
          PartnerConfig.syncFunctionName,
          body: {
            'action': 'occupancy',
            'horario_id': horarioId,
            'data': data,
            ...PartnerConfig.publicPayload(),
          },
        );
      } catch (e) {
        debugPrint('Wellhub occupancy sync: $e');
      }
    });
  }

  Future<Map<String, dynamic>> syncSchedule() async {
    if (!SupabaseConfig.isConfigured) {
      return {'ok': false, 'message': 'Supabase não configurado'};
    }
    try {
      final response = await Supabase.instance.client.functions.invoke(
        PartnerConfig.syncFunctionName,
        body: {
          'action': 'sync_schedule',
          ...PartnerConfig.publicPayload(),
        },
      );
      final data = response.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return {'ok': true, 'data': data};
    } catch (e) {
      debugPrint('Wellhub schedule sync: $e');
      return {'ok': false, 'message': e.toString()};
    }
  }
}
