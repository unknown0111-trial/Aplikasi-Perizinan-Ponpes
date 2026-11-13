import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/constants/routes.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/empty_state.dart';
import 'data/models/enums.dart';
import 'data/repositories/perizinan_repository.dart';
import 'data/repositories/notifikasi_repository.dart';

import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/splash_screen.dart';

import 'features/perizinan/perizinan_provider.dart';
import 'features/perizinan/form_izin_screen.dart';
import 'features/perizinan/detail_izin_screen.dart';

import 'features/profil/profil_screen.dart';

import 'features/santri/santri_shell.dart';
import 'features/santri/ajukan_screen.dart';
import 'features/santri/beranda_screen.dart';
import 'features/santri/riwayat_screen.dart';

import 'features/pengurus/pengurus_shell.dart';
import 'features/pengurus/pengurus_provider.dart';
import 'features/pengurus/dashboard_screen.dart';
import 'features/pengurus/daftar_pengajuan_screen.dart';
import 'features/pengurus/detail_pengajuan_screen.dart';

import 'features/notifikasi/notifikasi_provider.dart';
import 'features/notifikasi/notifikasi_screen.dart';

const _tabSantri = {
  Routes.santriHome,
  Routes.santriAjukan,
  Routes.santriRiwayat,
  Routes.santriProfil,
};

const _tabPengurus = {
  Routes.pengurusHome,
  Routes.pengurusPengajuan,
  Routes.pengurusRiwayat,
  Routes.pengurusProfil,
};

int _idDari(GoRouterState s) =>
    int.tryParse(s.pathParameters['id'] ?? '') ?? -1;

String? _redirectJenis(GoRouterState s, String fallback) =>
    JenisIzin.values.asNameMap().containsKey(s.pathParameters['jenis'])
    ? null
    : fallback;

Widget _bangunFormUbah(
  BuildContext context,
  GoRouterState state,
  IzinRoutes rute,
) {
  final id = int.tryParse(state.pathParameters['id'] ?? '');
  final izin = id == null ? null : context.read<PerizinanProvider>().cari(id);

  if (izin == null || izin.status != StatusIzin.menunggu) {
    return Scaffold(
      appBar: AppBar(),
      body: const EmptyState(
        icon: Icons.lock_outline,
        judul: 'Pengajuan tidak dapat diubah',
        pesan: 'Hanya pengajuan berstatus Menunggu yang bisa diubah.',
      ),
    );
  }

  return FormIzinScreen(jenis: izin.jenis, awal: izin, rute: rute);
}

class PerizinanApp extends StatefulWidget {
  const PerizinanApp({super.key});

  @override
  State<PerizinanApp> createState() => _PerizinanAppState();
}

class _PerizinanAppState extends State<PerizinanApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    final auth = context.read<AuthProvider>();

    _router = GoRouter(
      initialLocation: Routes.splash,
      refreshListenable: auth,

      redirect: (context, state) {
        final loc = state.matchedLocation;

        if (auth.status == AuthStatus.unknown) {
          return loc == Routes.splash ? null : Routes.splash;
        }

        if (auth.status == AuthStatus.loggedOut) {
          return loc == Routes.login ? null : Routes.login;
        }

        final home = auth.role == UserRole.santri
            ? Routes.santriHome
            : Routes.pengurusHome;

        final boleh = auth.role == UserRole.santri
            ? loc == Routes.santriHome || loc.startsWith('/santri/')
            : loc.startsWith('/pengurus/');

        return boleh ? null : home;
      },

      routes: [
        GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
        GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),

        // ================= SANTRI =================
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) {
            final user = context.read<AuthProvider>().user;

            if (user == null) {
              return const SizedBox.shrink();
            }

            return MultiProvider(
              key: ValueKey(user.id),
              providers: [
                ChangeNotifierProvider<PerizinanProvider>(
                  create: (c) =>
                      PerizinanProvider(c.read<PerizinanRepository>(), user.id!)
                        ..load(),
                ),
                ChangeNotifierProvider<NotifikasiProvider>(
                  create: (c) => NotifikasiProvider(
                    c.read<NotifikasiRepository>(),
                    user.id!,
                  )..load(),
                ),
              ],
              child: SantriShell(
                navigationShell: shell,
                sembunyikanNav: !_tabSantri.contains(state.uri.path),
              ),
            );
          },

          branches: [
            // Tab 1: Beranda
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: Routes.santriHome,
                  builder: (_, _) => const BerandaScreen(),
                  routes: [
                    GoRoute(
                      path: 'notifikasi',
                      builder: (_, _) => NotifikasiScreen(
                        onBuka: (ctx, n) =>
                            ctx.go(Routes.santriDetail(n.perizinanId!)),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Tab 2: Ajukan izin
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: Routes.santriAjukan,
                  builder: (_, _) => const AjukanScreen(),
                  routes: [
                    GoRoute(
                      path: ':jenis',
                      redirect: (_, s) =>
                          _redirectJenis(s, Routes.santriAjukan),
                      builder: (_, s) => FormIzinScreen(
                        jenis: JenisIzin.values.byName(
                          s.pathParameters['jenis']!,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Tab 3: Riwayat
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: Routes.santriRiwayat,
                  builder: (_, _) => const RiwayatScreen(),
                  routes: [
                    GoRoute(
                      path: ':id',
                      builder: (_, s) => DetailIzinScreen(izinId: _idDari(s)),
                      routes: [
                        GoRoute(
                          path: 'ubah',
                          builder: (c, s) =>
                              _bangunFormUbah(c, s, IzinRoutes.santri),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            // Tab 4: Profil
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: Routes.santriProfil,
                  builder: (_, _) => const ProfilScreen(),
                ),
              ],
            ),
          ],
        ),

        // ================= PENGURUS =================
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) {
            final user = context.read<AuthProvider>().user;

            if (user == null) {
              return const SizedBox.shrink();
            }

            return MultiProvider(
              key: ValueKey(user.id),
              providers: [
                ChangeNotifierProvider<PengurusProvider>(
                  create: (c) =>
                      PengurusProvider(c.read<PerizinanRepository>(), user)
                        ..load(),
                ),

                // Pengajuan izin pribadi pengurus
                ChangeNotifierProvider<PerizinanProvider>(
                  create: (c) => PerizinanProvider(
                    c.read<PerizinanRepository>(),
                    user.id!,
                    onBerubah: () => c.read<PengurusProvider>().load(),
                  )..load(),
                ),

                ChangeNotifierProvider<NotifikasiProvider>(
                  create: (c) => NotifikasiProvider(
                    c.read<NotifikasiRepository>(),
                    user.id!,
                  )..load(),
                ),
              ],
              child: PengurusShell(
                navigationShell: shell,
                sembunyikanNav: !_tabPengurus.contains(state.uri.path),
              ),
            );
          },

          branches: [
            // Tab 1: Dashboard
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: Routes.pengurusHome,
                  builder: (_, _) => const DashboardScreen(),
                  routes: [
                    GoRoute(
                      path: 'notifikasi',
                      builder: (_, _) => NotifikasiScreen(
                        onBuka: (ctx, n) {
                          final id = n.perizinanId!;
                          final milikSendiri =
                              ctx.read<PerizinanProvider>().cari(id) != null;

                          if (milikSendiri) {
                            ctx.push(IzinRoutes.pengurus.detail(id));
                          } else {
                            ctx.go(Routes.pengurusDetailPengajuan(id));
                          }
                        },
                      ),
                    ),

                    // Izin saya
                    GoRoute(
                      path: 'izin-saya',
                      builder: (_, _) => const RiwayatScreen(
                        judul: 'Izin Saya',
                        rute: IzinRoutes.pengurus,
                        tampilkanAjukan: true,
                      ),
                      routes: [
                        GoRoute(
                          path: 'ajukan',
                          builder: (_, _) =>
                              const AjukanScreen(rute: IzinRoutes.pengurus),
                          routes: [
                            GoRoute(
                              path: ':jenis',
                              redirect: (_, s) =>
                                  _redirectJenis(s, IzinRoutes.pengurus.ajukan),
                              builder: (_, s) => FormIzinScreen(
                                jenis: JenisIzin.values.byName(
                                  s.pathParameters['jenis']!,
                                ),
                                rute: IzinRoutes.pengurus,
                              ),
                            ),
                          ],
                        ),
                        GoRoute(
                          path: ':id',
                          builder: (_, s) => DetailIzinScreen(
                            izinId: _idDari(s),
                            rute: IzinRoutes.pengurus,
                          ),
                          routes: [
                            GoRoute(
                              path: 'ubah',
                              builder: (c, s) =>
                                  _bangunFormUbah(c, s, IzinRoutes.pengurus),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            // Tab 2: Daftar pengajuan
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: Routes.pengurusPengajuan,
                  builder: (_, _) =>
                      const DaftarPengajuanScreen(riwayat: false),
                  routes: [
                    GoRoute(
                      path: ':id',
                      builder: (_, s) =>
                          DetailPengajuanScreen(izinId: _idDari(s)),
                    ),
                  ],
                ),
              ],
            ),

            // Tab 3: Riwayat pengajuan
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: Routes.pengurusRiwayat,
                  builder: (_, _) => const DaftarPengajuanScreen(riwayat: true),
                  routes: [
                    GoRoute(
                      path: ':id',
                      builder: (_, s) =>
                          DetailPengajuanScreen(izinId: _idDari(s)),
                    ),
                  ],
                ),
              ],
            ),

            // Tab 4: Profil
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: Routes.pengurusProfil,
                  builder: (_, _) => const ProfilScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Perizinan Pesantren',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) {
        return MaterialUiCompatibilityBridge(child: child!);
      },
      routerConfig: _router,
    );
  }
}
