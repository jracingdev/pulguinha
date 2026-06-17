import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pulguinha/app.dart';
import 'package:pulguinha/config/mercado_pago_config.dart';
import 'package:pulguinha/config/partner_config.dart';
import 'package:pulguinha/config/pagbank_config.dart';
import 'package:pulguinha/services/app_version_service.dart';
import 'package:pulguinha/config/supabase_config.dart';
import 'package:pulguinha/services/app_sound_service.dart';
import 'package:pulguinha/services/notifications/notification_service.dart';
import 'package:pulguinha/services/supabase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    usePathUrlStrategy();
  }
  await initializeDateFormatting('pt_BR');
  await SupabaseConfig.initialize();
  await AppVersionService.initialize();
  await MercadoPagoConfig.initialize();
  await PagBankConfig.initialize();
  await PartnerConfig.initialize();
  await NotificationService.instance.initialize();
  await NotificationService.instance.requestPermission();
  await AppSoundService.instance.initialize();

  if (SupabaseConfig.isConfigured) {
    try {
      await SupabaseBootstrap.ensureInitialized(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
    } catch (e) {
      debugPrint('Supabase init em main(): $e');
    }
  }

  runApp(const PulguinhaApp());
}
