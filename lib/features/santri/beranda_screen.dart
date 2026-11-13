import '../../core/widgets/lonceng.dart';

import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/routes.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/izin_ui.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/perizinan_card.dart';
import '../../data/models/enums.dart';
import '../../data/models/perizinan_model.dart';
import '../auth/auth_provider.dart';
import '../perizinan/perizinan_provider.dart';

class BerandaScreen extends StatelessWidget {
  const BerandaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final data = context.watch<PerizinanProvider>();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<PerizinanProvider>().load(),
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
                          [
                            if (user.kelas != null) user.kelas!,
                            Fmt.hariLengkap(DateTime.now()),
                          ].join(' • '),
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Lonceng(rute: Routes.santriNotifikasi),
                ],
              ),
              const SizedBox(height: 20),
              if (!data.hasLoaded)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (data.error != null)
                _ErrorBox(
                  pesan: data.error!,
                  onCoba: () => context.read<PerizinanProvider>().load(),
                )
              else ...[
                if (data.izinAktif != null) ...[
                  _BannerIzinAktif(izin: data.izinAktif!),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        status: StatusIzin.menunggu,
                        jumlah: data.hitung(StatusIzin.menunggu),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        status: StatusIzin.disetujui,
                        jumlah: data.hitung(StatusIzin.disetujui),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        status: StatusIzin.ditolak,
                        jumlah: data.hitung(StatusIzin.ditolak),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => context.go(Routes.santriAjukan),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajukan izin baru'),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Pengajuan terbaru',
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (data.items.isNotEmpty)
                      TextButton(
                        onPressed: () => context.go(Routes.santriRiwayat),
                        child: const Text('Lihat semua'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (data.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: EmptyState(
                      icon: Icons.assignment_outlined,
                      judul: 'Belum ada pengajuan',
                      pesan: 'Pengajuan izin Anda akan muncul di sini.',
                    ),
                  )
                else
                  for (final izin in data.terbaru)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PerizinanCard(
                        izin: izin,
                        onTap: () => context.go(Routes.santriDetail(izin.id!)),
                      ),
                    ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.status, required this.jumlah});
  final StatusIzin status;
  final int jumlah;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = status.color;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(status.icon, color: c, size: 22),
            const SizedBox(height: 10),
            Text(
              '$jumlah',
              style: text.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: c,
              ),
            ),
            Text(status.label, style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _BannerIzinAktif extends StatelessWidget {
  const _BannerIzinAktif({required this.izin});
  final Perizinan izin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(izin.jenis.icon, color: scheme.onPrimaryContainer, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sedang dalam ${izin.jenis.label}',
                  style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Berlaku sampai ${Fmt.tanggal(izin.tanggalSelesai)}',
                  style: text.bodySmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.pesan, required this.onCoba});
  final String pesan;
  final VoidCallback onCoba;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 40),
    child: EmptyState(
      icon: Icons.error_outline,
      judul: pesan,
      aksiLabel: 'Coba lagi',
      onAksi: onCoba,
    ),
  );
}
