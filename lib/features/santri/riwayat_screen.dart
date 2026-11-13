import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/routes.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/perizinan_card.dart';
import '../../data/models/enums.dart';
import '../../data/models/perizinan_model.dart';
import '../perizinan/perizinan_provider.dart';

// 1. Konstruktor dan field
class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({
    super.key,
    this.judul = 'Riwayat Pengajuan',
    this.rute = IzinRoutes.santri,
    this.tampilkanAjukan = false,
  });

  final String judul;
  final IzinRoutes rute;
  final bool tampilkanAjukan; // tombol "Ajukan izin" (dipakai pengurus)

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final _cariCtrl = TextEditingController();
  String _cari = '';
  StatusIzin? _status; // null = semua

  @override
  void dispose() {
    _cariCtrl.dispose();
    super.dispose();
  }

  List<Perizinan> _saring(List<Perizinan> semua) {
    final q = _cari.trim().toLowerCase();
    return semua.where((i) {
      if (_status != null && i.status != _status) return false;
      if (q.isEmpty) return true;
      final teks = [
        i.jenis.label,
        i.alasan,
        i.tujuan,
        i.keluhan,
        i.penjemput,
        i.keterangan,
      ].whereType<String>().join(' ').toLowerCase();
      return teks.contains(q);
    }).toList();
  }

  Widget _kosong(Widget isi) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [const SizedBox(height: 80), isi],
  );

  @override
  Widget build(BuildContext context) {
    final data = context.watch<PerizinanProvider>();
    final hasil = _saring(data.items);

    return Scaffold(
      appBar: AppBar(title: Text(widget.judul)),

      floatingActionButton: widget.tampilkanAjukan
          ? FloatingActionButton.extended(
              onPressed: () => context.push(widget.rute.ajukan),
              icon: const Icon(Icons.add),
              label: const Text('Ajukan izin'),
            )
          : null,

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: TextField(
              controller: _cariCtrl,
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => _cari = v),
              decoration: InputDecoration(
                hintText: 'Cari pengajuan',
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
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('Semua (${data.items.length})'),
                    selected: _status == null,
                    onSelected: (_) => setState(() => _status = null),
                  ),
                ),
                for (final s in StatusIzin.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${s.label} (${data.hitung(s)})'),
                      selected: _status == s,
                      onSelected: (_) => setState(() => _status = s),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => context.read<PerizinanProvider>().load(),
              child: !data.hasLoaded
                  ? const Center(child: CircularProgressIndicator())
                  : data.items.isEmpty
                  ? _kosong(
                      const EmptyState(
                        icon: Icons.history,
                        judul: 'Belum ada riwayat',
                        pesan:
                            'Semua pengajuan izin Anda akan tercatat di sini.',
                      ),
                    )
                  : hasil.isEmpty
                  ? _kosong(
                      const EmptyState(
                        icon: Icons.search_off,
                        judul: 'Tidak ada hasil',
                        pesan: 'Coba ubah kata kunci atau filter status.',
                      ),
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        20,
                        4,
                        20,
                        widget.tampilkanAjukan ? 96 : 24,
                      ),
                      itemCount: hasil.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => PerizinanCard(
                        izin: hasil[i],
                        onTap: () =>
                            context.push(widget.rute.detail(hasil[i].id!)),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
