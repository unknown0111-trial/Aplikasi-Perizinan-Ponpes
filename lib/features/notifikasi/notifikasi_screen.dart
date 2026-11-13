import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/izin_ui.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/enums.dart';
import '../../data/models/notifikasi_model.dart';
import 'notifikasi_provider.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key, required this.onBuka});

  /// Dipanggil saat notifikasi yang terkait suatu izin diketuk.
  final void Function(BuildContext context, AppNotifikasi n) onBuka;

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  @override
  void initState() {
    super.initState();
    // Segarkan saat layar dibuka.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotifikasiProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<NotifikasiProvider>();
    final items = data.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          IconButton(
            tooltip: 'Tandai semua dibaca',
            icon: const Icon(Icons.done_all),
            onPressed: data.belumDibaca > 0
                ? () => context.read<NotifikasiProvider>().tandaiSemuaDibaca()
                : null,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<NotifikasiProvider>().load(),
        child: !data.hasLoaded
            ? const Center(child: CircularProgressIndicator())
            : items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 100),
                  EmptyState(
                    icon: Icons.notifications_none,
                    judul: 'Belum ada notifikasi',
                    pesan:
                        'Pemberitahuan tentang pengajuan izin muncul di sini.',
                  ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _KartuNotifikasi(
                  n: items[i],
                  onTap: () {
                    context.read<NotifikasiProvider>().tandaiDibaca(items[i]);
                    if (items[i].perizinanId != null) {
                      widget.onBuka(context, items[i]);
                    }
                  },
                ),
              ),
      ),
    );
  }
}

class _KartuNotifikasi extends StatelessWidget {
  const _KartuNotifikasi({required this.n, required this.onTap});
  final AppNotifikasi n;
  final VoidCallback onTap;

  (IconData, Color) _gaya(ColorScheme s) {
    final j = n.judul.toLowerCase();
    if (j.contains('disetujui')) {
      return (StatusIzin.disetujui.icon, StatusIzin.disetujui.color);
    }
    if (j.contains('ditolak')) {
      return (StatusIzin.ditolak.icon, StatusIzin.ditolak.color);
    }
    return (Icons.inbox_outlined, s.primary);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final (ikon, warna) = _gaya(scheme);

    return Card(
      clipBehavior: Clip.antiAlias,
      color: n.dibaca ? null : scheme.primaryContainer.withValues(alpha: 0.35),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: warna.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(ikon, color: warna, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.judul,
                      style: text.titleSmall?.copyWith(
                        fontWeight: n.dibaca
                            ? FontWeight.w500
                            : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(n.isi, style: text.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      Fmt.tanggalJam(n.createdAt),
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (!n.dibaca)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 6, left: 8),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
