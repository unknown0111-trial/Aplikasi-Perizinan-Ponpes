import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/lonceng.dart';
import '../perizinan/perizinan_provider.dart';
import '../../core/constants/routes.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/izin_ui.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/perizinan_card.dart';
import '../../core/widgets/stat_card.dart';
import '../../data/models/enums.dart';
import '../auth/auth_provider.dart';
import 'pengurus_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final data = context.watch<PengurusProvider>();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final antrean = data.antrean;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<PengurusProvider>().load(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Assalamu'alaikum,",
                          style: text.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.nama,
                          style: text.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${user.jabatan} • ${Fmt.hariLengkap(DateTime.now())}',
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Lonceng(rute: Routes.pengurusNotifikasi),
                ],
              ),
              const SizedBox(height: 20),
              if (!data.hasLoaded)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (data.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: EmptyState(
                    icon: Icons.error_outline,
                    judul: data.error!,
                    aksiLabel: 'Coba lagi',
                    onAksi: () => context.read<PengurusProvider>().load(),
                  ),
                )
              else ...[
                _KartuAntrean(jumlah: data.jumlahAntrean),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        icon: Icons.directions_walk_rounded,
                        warna: scheme.primary,
                        label: 'Sedang izin',
                        nilai: data.jumlahSedangIzin,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        icon: StatusIzin.menunggu.icon,
                        warna: StatusIzin.menunggu.color,
                        label: 'Menunggu',
                        nilai: data.hitung(StatusIzin.menunggu),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        icon: StatusIzin.disetujui.icon,
                        warna: StatusIzin.disetujui.color,
                        label: 'Disetujui',
                        nilai: data.hitung(StatusIzin.disetujui),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        icon: StatusIzin.ditolak.icon,
                        warna: StatusIzin.ditolak.color,
                        label: 'Ditolak',
                        nilai: data.hitung(StatusIzin.ditolak),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Perlu diproses',

                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (antrean.length > 5)
                      TextButton(
                        onPressed: () => context.go(Routes.pengurusPengajuan),
                        child: const Text('Lihat semua'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (antrean.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: EmptyState(
                      icon: Icons.task_alt,
                      judul: 'Semua sudah ditangani',
                      pesan:
                          'Tidak ada pengajuan yang menunggu keputusan Anda.',
                    ),
                  )
                else
                  for (final izin in antrean.take(5))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PerizinanCard(
                        izin: izin,
                        tampilkanPemohon: true,
                        perluTindakan: true,
                        onTap: () => context.go(
                          Routes.pengurusDetailPengajuan(izin.id!),
                        ),
                      ),
                    ),
                const SizedBox(height: 28),
                _IzinSaya(sebagaiSenior: user.levelPengurus >= 2),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _KartuAntrean extends StatelessWidget {
  const _KartuAntrean({required this.jumlah});
  final int jumlah;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Perlu diproses',
            style: text.titleSmall?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$jumlah',
            style: text.displayMedium?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            jumlah == 0
                ? 'Tidak ada pengajuan yang menunggu Anda.'
                : 'Pengajuan menunggu keputusan Anda.',
            style: text.bodyMedium?.copyWith(color: scheme.onPrimaryContainer),
          ),
          if (jumlah > 0) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go(Routes.pengurusPengajuan),
              child: const Text('Tinjau sekarang'),
            ),
          ],
        ],
      ),
    );
  }
}

class _IzinSaya extends StatelessWidget {
  const _IzinSaya({required this.sebagaiSenior});

  final bool sebagaiSenior;

  @override
  Widget build(BuildContext context) {
    final own = context.watch<PerizinanProvider>();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Izin saya',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            if (own.items.isNotEmpty)
              TextButton(
                onPressed: () => context.push(Routes.pengurusIzinSaya),
                child: const Text('Lihat semua'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: () => context.push(IzinRoutes.pengurus.ajukan),
          icon: const Icon(Icons.add),
          label: const Text('Ajukan izin saya'),
        ),
        const SizedBox(height: 6),
        Text(
          sebagaiSenior
              ? 'Izin Anda diproses oleh pengurus senior lain.'
              : 'Izin Anda diproses oleh pengurus senior.',
          textAlign: TextAlign.center,
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        if (own.hasLoaded && own.items.isEmpty)
          Text(
            'Anda belum pernah mengajukan izin.',
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          )
        else
          for (final izin in own.terbaru.take(2))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PerizinanCard(
                izin: izin,
                onTap: () => context.push(IzinRoutes.pengurus.detail(izin.id!)),
              ),
            ),
      ],
    );
  }
}
