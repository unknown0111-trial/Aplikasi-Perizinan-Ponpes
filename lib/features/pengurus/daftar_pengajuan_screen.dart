import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/routes.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/perizinan_card.dart';
import '../../data/models/enums.dart';
import '../../data/models/perizinan_model.dart';
import 'pengurus_provider.dart';

enum _Saring {
  perluDiproses('Perlu diproses'),
  semua('Semua'),
  menunggu('Menunggu'),
  disetujui('Disetujui'),
  ditolak('Ditolak'),
  dibatalkan('Dibatalkan');

  const _Saring(this.label);
  final String label;

  StatusIzin? get status => switch (this) {
    _Saring.menunggu => StatusIzin.menunggu,
    _Saring.disetujui => StatusIzin.disetujui,
    _Saring.ditolak => StatusIzin.ditolak,
    _Saring.dibatalkan => StatusIzin.dibatalkan,
    _ => null,
  };
}

class DaftarPengajuanScreen extends StatefulWidget {
  const DaftarPengajuanScreen({super.key, required this.riwayat});

  /// true = mode Riwayat (hanya yang sudah selesai diproses).
  final bool riwayat;

  @override
  State<DaftarPengajuanScreen> createState() => _DaftarPengajuanScreenState();
}

class _DaftarPengajuanScreenState extends State<DaftarPengajuanScreen> {
  final _cariCtrl = TextEditingController();
  String _cari = '';
  late _Saring _saring;
  JenisIzin? _jenis;
  DateTimeRange? _rentang;

  List<_Saring> get _opsi => widget.riwayat
      ? const [
          _Saring.semua,
          _Saring.disetujui,
          _Saring.ditolak,
          _Saring.dibatalkan,
        ]
      : _Saring.values;

  bool get _filterAktif => _jenis != null || _rentang != null;

  @override
  void initState() {
    super.initState();
    _saring = widget.riwayat ? _Saring.semua : _Saring.perluDiproses;
  }

  @override
  void dispose() {
    _cariCtrl.dispose();
    super.dispose();
  }

  Iterable<Perizinan> _dasar(PengurusProvider p) => widget.riwayat
      ? p.semua.where((i) => i.status != StatusIzin.menunggu)
      : p.semua;

  int _hitung(_Saring s, PengurusProvider p) => switch (s) {
    _Saring.perluDiproses => p.jumlahAntrean,
    _Saring.semua => _dasar(p).length,
    _ => _dasar(p).where((i) => i.status == s.status).length,
  };

  List<Perizinan> _terapkan(PengurusProvider p) {
    Iterable<Perizinan> hasil = switch (_saring) {
      _Saring.perluDiproses => p.antrean,
      _Saring.semua => _dasar(p),
      _ => _dasar(p).where((i) => i.status == _saring.status),
    };
    if (_jenis != null) hasil = hasil.where((i) => i.jenis == _jenis);
    final r = _rentang;
    if (r != null) {
      hasil = hasil.where(
        (i) =>
            !i.tanggalSelesai.isBefore(r.start) &&
            !i.tanggalMulai.isAfter(r.end),
      );
    }
    final q = _cari.trim().toLowerCase();
    if (q.isNotEmpty) {
      hasil = hasil.where(
        (i) => [
          i.namaPemohon,
          i.noIdentitasPemohon,
          i.jenis.label,
          i.alasan,
          i.tujuan,
          i.keluhan,
        ].whereType<String>().join(' ').toLowerCase().contains(q),
      );
    }
    return hasil.toList();
  }

  Future<void> _bukaFilter() async {
    JenisIzin? jenis = _jenis;
    DateTimeRange? rentang = _rentang;

    final terapkan = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final text = Theme.of(ctx).textTheme;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter',
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Jenis izin', style: text.bodySmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Semua'),
                        selected: jenis == null,
                        onSelected: (_) => setSheet(() => jenis = null),
                      ),
                      for (final j in JenisIzin.values)
                        ChoiceChip(
                          label: Text(j.label),
                          selected: jenis == j,
                          onSelected: (_) => setSheet(() => jenis = j),
                        ),
                    ],
                  ),
                  if (widget.riwayat) ...[
                    const SizedBox(height: 16),
                    Text('Rentang tanggal izin', style: text.bodySmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.date_range),
                            label: Text(
                              rentang == null
                                  ? 'Pilih rentang'
                                  : '${Fmt.tanggal(rentang!.start)} – ${Fmt.tanggal(rentang!.end)}',
                              overflow: TextOverflow.ellipsis,
                            ),
                            onPressed: () async {
                              final h = DateTime.now();
                              final r = await showDateRangePicker(
                                context: ctx,
                                firstDate: DateTime(h.year - 2),
                                lastDate: DateTime(h.year + 1, 12, 31),
                                initialDateRange: rentang,
                              );
                              if (r != null) setSheet(() => rentang = r);
                            },
                          ),
                        ),
                        if (rentang != null)
                          IconButton(
                            tooltip: 'Hapus rentang',
                            icon: const Icon(Icons.close),
                            onPressed: () => setSheet(() => rentang = null),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => setSheet(() {
                            jenis = null;
                            rentang = null;
                          }),
                          child: const Text('Atur ulang'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Terapkan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (terapkan == true) {
      setState(() {
        _jenis = jenis;
        _rentang = rentang;
      });
    }
  }

  Widget _kosong(Widget isi) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [const SizedBox(height: 80), isi],
  );

  @override
  Widget build(BuildContext context) {
    final data = context.watch<PengurusProvider>();
    final hasil = _terapkan(data);
    final tanpaPenyaring = _cari.trim().isEmpty && !_filterAktif;

    Widget kosong;
    if (data.semua.isEmpty) {
      kosong = const EmptyState(
        icon: Icons.inbox_outlined,
        judul: 'Belum ada pengajuan',
        pesan: 'Pengajuan izin santri akan muncul di sini.',
      );
    } else if (_saring == _Saring.perluDiproses && tanpaPenyaring) {
      kosong = const EmptyState(
        icon: Icons.task_alt,
        judul: 'Tidak ada yang perlu diproses',
        pesan: 'Semua pengajuan untuk Anda sudah ditangani.',
      );
    } else {
      kosong = const EmptyState(
        icon: Icons.search_off,
        judul: 'Tidak ada hasil',
        pesan: 'Coba ubah kata kunci atau filter.',
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.riwayat ? 'Riwayat Perizinan' : 'Pengajuan Izin'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cariCtrl,
                    textInputAction: TextInputAction.search,
                    onChanged: (v) => setState(() => _cari = v),
                    decoration: InputDecoration(
                      hintText: 'Cari nama atau nomor santri',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _cari.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Hapus pencarian',
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _cariCtrl.clear();
                                setState(() => _cari = '');
                              },
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Filter',
                  style: IconButton.styleFrom(fixedSize: const Size(56, 56)),
                  onPressed: _bukaFilter,
                  icon: Badge(
                    smallSize: 9,
                    isLabelVisible: _filterAktif,
                    child: const Icon(Icons.tune),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                for (final s in _opsi)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${s.label} (${_hitung(s, data)})'),
                      selected: _saring == s,
                      onSelected: (_) => setState(() => _saring = s),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => context.read<PengurusProvider>().load(),
              child: !data.hasLoaded
                  ? const Center(child: CircularProgressIndicator())
                  : hasil.isEmpty
                  ? _kosong(kosong)
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: hasil.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final izin = hasil[i];
                        return PerizinanCard(
                          izin: izin,
                          tampilkanPemohon: true,
                          perluTindakan:
                              !widget.riwayat && data.bisaDiproses(izin),
                          onTap: () => context.push(
                            widget.riwayat
                                ? Routes.pengurusDetailRiwayat(izin.id!)
                                : Routes.pengurusDetailPengajuan(izin.id!),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
