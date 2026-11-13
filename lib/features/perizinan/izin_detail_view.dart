import 'package:material_ui/material_ui.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/izin_ui.dart';
import '../../data/models/enums.dart';
import '../../data/models/perizinan_model.dart';

/// Isi detail pengajuan. Tidak punya tombol aksi, jadi bisa dipakai
/// oleh santri (Tahap 5) maupun pengurus (Tahap 6).
class IzinDetailView extends StatelessWidget {
  const IzinDetailView({
    super.key,
    required this.izin,
    this.tampilkanPemohon = true,
  });

  final Perizinan izin;
  final bool tampilkanPemohon;

  String get _subjudulStatus {
    final oleh = izin.namaPemroses != null ? ' oleh ${izin.namaPemroses}' : '';
    return switch (izin.status) {
      StatusIzin.menunggu => 'Menunggu persetujuan pengurus',
      StatusIzin.disetujui => 'Disetujui$oleh',
      StatusIzin.ditolak => 'Ditolak$oleh',
      StatusIzin.dibatalkan => 'Dibatalkan oleh pemohon',
    };
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final c = izin.status.color;
    final sakit = izin.jenis == JenisIzin.sakit;
    final keluar = izin.jenis == JenisIzin.keluar;
    final sudahDiproses =
        izin.tanggalDiproses != null ||
        (izin.catatanPengurus?.trim().isNotEmpty ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(izin.jenis.icon, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                izin.jenis.label,
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(izin.status.icon, color: c),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      izin.status.label,
                      style: text.titleSmall?.copyWith(
                        color: c,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _subjudulStatus,
                      style: text.bodySmall?.copyWith(color: c),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (tampilkanPemohon)
          _Seksi('Pemohon', [
            _Baris('Nama', izin.namaPemohon),
            _Baris('No. identitas', izin.noIdentitasPemohon),
          ]),
        _Seksi('Waktu', [
          _Baris('Tgl. pengajuan', Fmt.tanggal(izin.tanggalPengajuan)),
          _Baris(
            keluar ? 'Tanggal keluar' : 'Tanggal mulai',
            Fmt.tanggal(izin.tanggalMulai),
          ),
          if (!keluar)
            _Baris('Tanggal selesai', Fmt.tanggal(izin.tanggalSelesai)),
          if (izin.jamKeluar != null)
            _Baris('Jam', '${izin.jamKeluar} – ${izin.jamKembali ?? '-'}'),
        ]),
        _Seksi('Detail', [
          _Baris(sakit ? 'Lokasi pemulihan' : 'Tujuan', izin.tujuan),
          _Baris('Penjemput', izin.penjemput),
          _Baris('Keluhan', izin.keluhan),
        ]),
        _Seksi('Alasan', [
          _Baris('Alasan', izin.alasan),
          _Baris('Keterangan', izin.keterangan),
        ]),
        if (sudahDiproses)
          _Seksi('Proses pengurus', [
            _Baris('Diproses oleh', izin.namaPemroses),
            _Baris(
              'Tanggal proses',
              izin.tanggalDiproses == null
                  ? null
                  : Fmt.tanggalJam(izin.tanggalDiproses!),
            ),
            _Baris('Catatan', izin.catatanPengurus),
          ]),
      ],
    );
  }
}

class _Seksi extends StatelessWidget {
  const _Seksi(this.judul, this.baris);
  final String judul;
  final List<Widget> baris;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              judul,
              style: text.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(children: baris),
            ),
          ),
        ],
      ),
    );
  }
}

/// Baris kosong (nilai null/blank) tidak ditampilkan.
class _Baris extends StatelessWidget {
  const _Baris(this.label, this.nilai);
  final String label;
  final String? nilai;

  @override
  Widget build(BuildContext context) {
    if (nilai == null || nilai!.trim().isEmpty) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(child: Text(nilai!, style: text.bodyMedium)),
        ],
      ),
    );
  }
}
