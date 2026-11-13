import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/routes.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/enums.dart';
import '../../data/models/perizinan_model.dart';
import '../../data/repositories/perizinan_repository.dart';
import 'izin_detail_view.dart';
import 'perizinan_provider.dart';

class DetailIzinScreen extends StatefulWidget {
  const DetailIzinScreen({
    super.key,
    required this.izinId,
    this.rute = IzinRoutes.santri,
  });
  final int izinId;
  final IzinRoutes rute;

  @override
  State<DetailIzinScreen> createState() => _DetailIzinScreenState();
}

class _DetailIzinScreenState extends State<DetailIzinScreen> {
  bool _sibuk = false;

  Future<bool?> _konfirmasi({
    required String judul,
    required String isi,
    required String aksi,
    bool bahaya = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(judul),
        content: Text(isi),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            style: bahaya
                ? FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                    minimumSize: const Size(0, 44),
                  )
                : FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(aksi),
          ),
        ],
      ),
    );
  }

  /// Menjalankan aksi, menampilkan hasilnya, mengembalikan true jika sukses.
  Future<bool> _jalankan(Future<void> Function() aksi, String sukses) async {
    final messenger = ScaffoldMessenger.of(context);
    void info(String pesan) => messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(pesan), behavior: SnackBarBehavior.floating),
      );

    setState(() => _sibuk = true);
    var ok = false;
    try {
      await aksi();
      ok = true;
      info(sukses);
    } on PerizinanException catch (e) {
      info(e.message);
    } catch (_) {
      info('Terjadi kesalahan. Silakan coba lagi.');
    }
    if (mounted) setState(() => _sibuk = false);
    return ok;
  }

  Future<void> _batalkan(Perizinan izin) async {
    final provider = context.read<PerizinanProvider>();
    final ya = await _konfirmasi(
      judul: 'Batalkan pengajuan?',
      isi:
          'Pengajuan ini tidak akan diproses pengurus dan tidak bisa '
          'diaktifkan kembali.',
      aksi: 'Batalkan pengajuan',
    );
    if (ya != true || !mounted) return;
    await _jalankan(() => provider.batalkan(izin.id!), 'Pengajuan dibatalkan');
  }

  Future<void> _hapus(Perizinan izin) async {
    final provider = context.read<PerizinanProvider>();
    final router = GoRouter.of(context);
    final ya = await _konfirmasi(
      judul: 'Hapus pengajuan?',
      isi: 'Pengajuan akan dihapus permanen dari riwayat Anda.',
      aksi: 'Hapus',
      bahaya: true,
    );
    if (ya != true || !mounted) return;
    final ok = await _jalankan(
      () => provider.hapus(izin.id!),
      'Pengajuan dihapus',
    );
    if (ok && router.canPop()) router.pop();
  }

  Widget _aksi(Perizinan izin) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    if (izin.status == StatusIzin.menunggu) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _sibuk ? null : () => _batalkan(izin),
              icon: const Icon(Icons.block),
              label: const Text('Batalkan'),
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
                  : () => context.push(widget.rute.ubah(izin.id!)),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Ubah'),
            ),
          ),
        ],
      );
    }

    final catatan = izin.status == StatusIzin.dibatalkan
        ? 'Pengajuan yang dibatalkan tidak dapat diubah. '
              'Gunakan menu di pojok kanan atas untuk menghapusnya.'
        : 'Pengajuan yang sudah diproses tidak dapat diubah atau dihapus.';
    return Text(
      catatan,
      textAlign: TextAlign.center,
      style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
    );
  }

  @override
  Widget build(BuildContext context) {
    final izin = context.watch<PerizinanProvider>().cari(widget.izinId);

    if (izin == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Pengajuan')),
        body: const EmptyState(
          icon: Icons.search_off,
          judul: 'Pengajuan tidak ditemukan',
          pesan: 'Pengajuan ini mungkin sudah dihapus.',
        ),
      );
    }

    final bisaHapus =
        izin.status == StatusIzin.menunggu ||
        izin.status == StatusIzin.dibatalkan;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pengajuan'),
        actions: [
          if (bisaHapus)
            PopupMenuButton<String>(
              enabled: !_sibuk,
              onSelected: (_) => _hapus(izin),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'hapus', child: Text('Hapus pengajuan')),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IzinDetailView(izin: izin, tampilkanPemohon: false),
              const SizedBox(height: 24),
              _aksi(izin),
            ],
          ),
        ),
      ),
    );
  }
}
