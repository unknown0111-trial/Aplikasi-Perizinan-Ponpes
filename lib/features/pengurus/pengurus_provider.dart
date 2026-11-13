import 'package:flutter/foundation.dart';

import '../../data/models/enums.dart';
import '../../data/models/perizinan_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/perizinan_repository.dart';

class PengurusProvider extends ChangeNotifier {
  PengurusProvider(this._repo, this.pengurus);

  final PerizinanRepository _repo;
  final AppUser pengurus;

  List<Perizinan> _items = [];
  bool _loading = false;
  bool _loaded = false;
  bool _reloadQueued = false;
  bool _disposed = false;
  String? _error;

  /// Seluruh pengajuan, terbaru di atas.
  List<Perizinan> get semua => _items;
  bool get isLoading => _loading;
  bool get hasLoaded => _loaded;
  String? get error => _error;

  bool bisaDiproses(Perizinan i) =>
      PerizinanRules.bisaDiproses(pemroses: pengurus, izin: i);

  int get jumlahAntrean => _items.where(bisaDiproses).length;

  /// Izin yang boleh diproses pengguna ini, yang paling lama menunggu di atas.
  List<Perizinan> get antrean {
    final l = _items.where(bisaDiproses).toList();
    l.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
    return l;
  }

  int hitung(StatusIzin s) => _items.where((e) => e.status == s).length;

  /// Jumlah izin disetujui yang mencakup hari ini.
  int get jumlahSedangIzin {
    final n = DateTime.now();
    final hariIni = DateTime(n.year, n.month, n.day);
    return _items
        .where(
          (i) =>
              i.status == StatusIzin.disetujui &&
              !i.tanggalMulai.isAfter(hariIni) &&
              !i.tanggalSelesai.isBefore(hariIni),
        )
        .length;
  }

  Perizinan? cari(int id) {
    for (final i in _items) {
      if (i.id == id) return i;
    }
    return null;
  }

  String alasanTidakBisa(Perizinan i) {
    if (i.status != StatusIzin.menunggu) {
      return 'Pengajuan ini sudah tidak menunggu keputusan.';
    }
    if (i.userId == pengurus.id) {
      return 'Anda tidak dapat memproses pengajuan Anda sendiri.';
    }
    return 'Pengajuan ini hanya dapat diproses oleh pengurus senior.';
  }

  Future<void> load() async {
    if (_loading) {
      _reloadQueued = true;
      return;
    }
    _loading = true;
    _error = null;
    _safeNotify();
    try {
      _items = await _repo.getAll();
    } catch (_) {
      _error = 'Gagal memuat data pengajuan.';
    } finally {
      _loading = false;
      _loaded = true;
      _safeNotify();
    }
    if (_reloadQueued && !_disposed) {
      _reloadQueued = false;
      await load();
    }
  }

  /// Setujui atau tolak. Jika gagal (mis. sudah diproses pengurus lain),
  /// daftar dimuat ulang lalu pengecualian diteruskan ke pemanggil.
  Future<void> proses({
    required int id,
    required bool setujui,
    String? catatan,
  }) async {
    try {
      await _repo.proses(
        izinId: id,
        pemroses: pengurus,
        setujui: setujui,
        catatan: catatan,
      );
    } on PerizinanException {
      await load();
      rethrow;
    }
    await load();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
