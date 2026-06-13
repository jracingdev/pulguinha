import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pulguinha/app.dart';
import 'package:pulguinha/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey, // ignore: deprecated_member_use
    );
  }

  runApp(const PulguinhaApp());
}
