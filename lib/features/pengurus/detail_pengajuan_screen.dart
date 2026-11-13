import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/catatan_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/perizinan_model.dart';
import '../../data/repositories/perizinan_repository.dart';
import '../perizinan/izin_detail_view.dart';
import 'pengurus_provider.dart';

class DetailPengajuanScreen extends StatefulWidget {
  const DetailPengajuanScreen({super.key, required this.izinId});
  final int izinId;

  @override
  State<DetailPengajuanScreen> createState() => _DetailPengajuanScreenState();
}

class _DetailPengajuanScreenState extends State<DetailPengajuanScreen> {
  bool _sibuk = false;

  Future<void> _proses(Perizinan izin, {required bool setujui}) async {
    final provider = context.read<PengurusProvider>();
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);

    void info(String pesan) => messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(pesan), behavior: SnackBarBehavior.floating),
      );

    final catatan = await showDialog<String>(
      context: context,
      builder: (_) => CatatanDialog(
        judul: setujui ? 'Setujui pengajuan?' : 'Tolak pengajuan?',
        deskripsi: '${izin.namaPemohon} • ${izin.jenis.label}',
        label: setujui ? 'Catatan (opsional)' : 'Alasan penolakan',
        aksi: setujui ? 'Setujui' : 'Tolak',
        wajib: !setujui,
        bahaya: !setujui,
      ),
    );
    if (catatan == null || !mounted) return;

    setState(() => _sibuk = true);
    try {
      await provider.proses(
        id: izin.id!,
        setujui: setujui,
        catatan: catatan.isEmpty ? null : catatan,
      );
      info(setujui ? 'Pengajuan disetujui' : 'Pengajuan ditolak');
      if (router.canPop()) router.pop();
    } on PerizinanException catch (e) {
      info(e.message);
    } catch (_) {
      info('Terjadi kesalahan. Silakan coba lagi.');
    }
    if (mounted) setState(() => _sibuk = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PengurusProvider>();
    final izin = provider.cari(widget.izinId);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    if (izin == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Pengajuan')),
        body: const EmptyState(
          icon: Icons.search_off,
          judul: 'Pengajuan tidak ditemukan',
        ),
      );
    }

    final bisa = provider.bisaDiproses(izin);

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pengajuan')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IzinDetailView(izin: izin),
              const SizedBox(height: 24),
              if (bisa)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _sibuk
                            ? null
                            : () => _proses(izin, setujui: false),
                        icon: const Icon(Icons.close),
                        label: const Text('Tolak'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          foregroundColor: scheme.error,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _sibuk
                            ? null
                            : () => _proses(izin, setujui: true),
                        icon: const Icon(Icons.check),
                        label: const Text('Setujui'),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  provider.alasanTidakBisa(izin),
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
