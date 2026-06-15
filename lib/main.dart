import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pulguinha/app.dart';
import 'package:pulguinha/config/mercado_pago_config.dart';
import 'package:pulguinha/config/pagbank_config.dart';
import 'package:pulguinha/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    usePathUrlStrategy();
  }
  await initializeDateFormatting('pt_BR');
  await MercadoPagoConfig.initialize();
  await PagBankConfig.initialize();

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey, // ignore: deprecated_member_use
    );
  }

  runApp(const PulguinhaApp());
}
