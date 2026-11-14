import 'package:material_ui/material_ui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'dart:async';

import 'data/repositories/notifikasi_repository.dart';
import 'app.dart';
import 'data/datasources/database_helper.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/perizinan_repository.dart';
import 'features/auth/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi format tanggal Indonesia.
  await initializeDateFormatting('id_ID');

  final db = DatabaseHelper.instance;
  final authProvider = AuthProvider(AuthRepository(db));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        Provider<PerizinanRepository>.value(value: PerizinanRepository(db)),
        Provider<NotifikasiRepository>.value(value: NotifikasiRepository(db)),
      ],
      child: const PerizinanApp(),
    ),
  );

  // Inisialisasi sesi setelah UI tampil.
  // Inisialisasi sesi setelah UI tampil.
  // Inisialisasi sesi setelah UI tampil.
  unawaited(authProvider.init());
}
