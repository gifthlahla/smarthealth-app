import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smarthealth/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://kmzmqdebniekrvqxoqea.supabase.co',
    anonKey: 'sb_publishable_DPVgHloq1aJBSIrgLsvCog_bN6iqF0i',
  );

  runApp(
    const ProviderScope(
      child: SmartHealthApp(),
    ),
  );
}
